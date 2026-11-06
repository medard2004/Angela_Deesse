import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../../screens/receipt_screen.dart';

/// Service autonome de génération de reçu PDF au format ticket thermique 80 mm.
/// Construit UNIQUEMENT à partir des champs immuables/figés du versement.
class ReceiptPdfGenerator {
  const ReceiptPdfGenerator();

  /// Nettoie une chaîne pour le nom de fichier : retire les accents, espaces et caractères spéciaux.
  static String sanitizeForFileName(String input) {
    var s = input.trim();
    // Table de remplacement des accents et ligatures courants
    const replacements = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
      'ý': 'y', 'ÿ': 'y', 'Ý': 'Y',
      'ç': 'c', 'Ç': 'C',
      'ñ': 'n', 'Ñ': 'N',
      'œ': 'oe', 'Œ': 'OE', 'æ': 'ae', 'Æ': 'AE',
      '\'': '_', '’': '_', ' ': '_', '-': '-',
    };

    replacements.forEach((key, val) {
      s = s.replaceAll(key, val);
    });

    // Remplace tout ce qui n'est pas lettre, chiffre, tiret ou souligné
    s = s.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    // Nettoie les soulignés consécutifs
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

    return s.isEmpty ? 'sans_nom' : s;
  }

  /// Construit un nom de fichier standardisé et assaini, ex: `Recu_CMD-0007_Afiwa.pdf`.
  static String buildFileName(ReceiptData data) {
    final cleanNo = sanitizeForFileName(data.receiptNo);
    final cleanName = sanitizeForFileName(data.beneficiaryName);
    return 'Recu_${cleanNo}_$cleanName.pdf';
  }

  /// Génère les octets PDF pour un reçu donné.
  /// Accepte optionnellement les octets des polices TTF (très utile pour les tests sans assets Flutter).
  Future<Uint8List> generatePdf(
    ReceiptData data, {
    Uint8List? regularFontBytes,
    Uint8List? boldFontBytes,
  }) async {
    final regularData = regularFontBytes ??
        (await rootBundle.load('assets/fonts/Manrope-400.ttf')).buffer.asUint8List();
    final boldData = boldFontBytes ??
        (await rootBundle.load('assets/fonts/Manrope-700.ttf')).buffer.asUint8List();

    final fontRegular = pw.Font.ttf(regularData.buffer.asByteData());
    final fontBold = pw.Font.ttf(boldData.buffer.asByteData());

    final doc = pw.Document(
      title: 'Reçu ${data.receiptNo}',
      author: data.atelierName,
      creator: 'Angela Déesse',
      subject: data.title,
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    // Tampon calculé selon les règles strictes
    final String stampLabel;
    if (data.isVoided) {
      stampLabel = 'ANNULÉ';
    } else if (data.remainingAmount <= 0) {
      stampLabel = 'SOLDÉ';
    } else {
      stampLabel = 'VERSÉ';
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. En-tête atelier
              pw.Center(
                child: pw.Text(
                  data.atelierName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'REÇU DE VERSEMENT',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'N° ${data.receiptNo}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8, color: PdfColors.grey500),
              pw.SizedBox(height: 6),

              // 2. Infos versement & Bénéficiaire
              _pdfRow('Date', fmtDate(data.date)),
              _pdfRow(data.beneficiaryRole, data.beneficiaryName, bold: true),
              if (data.beneficiaryPhone.isNotEmpty)
                _pdfRow('Téléphone', data.beneficiaryPhone),
              if (data.itemDetail != null && data.itemDetail!.isNotEmpty)
                _pdfRow('Détail', data.itemDetail!),
              if (data.note.isNotEmpty)
                _pdfRow('Motif', data.note),

              pw.SizedBox(height: 6),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8, color: PdfColors.grey500),
              pw.SizedBox(height: 6),

              // 3. Montant versé mis en avant
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'MONTANT VERSÉ',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.Text(
                      fcfa(data.amountPaid),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8, color: PdfColors.grey500),
              pw.SizedBox(height: 6),

              // 4. Décompte financier figé
              _pdfRow(
                data.beneficiaryRole == 'Client(e)' ? 'Prix total' : 'Total formation',
                fcfa(data.totalFee),
              ),
              _pdfRow('Cumul versé à ce jour', fcfa(data.totalPaidToDate)),
              _pdfRow(
                'Reste à payer',
                data.remainingAmount <= 0 ? 'Soldé' : fcfa(data.remainingAmount),
                bold: true,
              ),
              if (data.nextDueDate != null && data.remainingAmount > 0)
                _pdfRow('Prochaine échéance', fmtDate(data.nextDueDate!)),

              pw.SizedBox(height: 10),

              // 5. Tampon (VERSÉ, SOLDÉ, ANNULÉ)
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: data.isVoided ? PdfColors.red800 : PdfColors.blue900,
                      width: 2,
                    ),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        stampLabel,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2.0,
                          color: data.isVoided ? PdfColors.red800 : PdfColors.blue900,
                        ),
                      ),
                      if (data.isVoided) ...[
                        if (data.voidedAt != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Annulé le ${fmtDate(data.voidedAt!)}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.red800),
                          ),
                        ],
                        if (data.voidReason != null && data.voidReason!.isNotEmpty) ...[
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Motif : ${data.voidReason}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.red800),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8, color: PdfColors.grey500),
              pw.SizedBox(height: 6),

              // 6. Pied de reçu
              pw.Center(
                child: pw.Text(
                  'Merci pour votre confiance · ${data.atelierName}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Écrit le fichier PDF dans le dossier temporaire du système et renvoie le [File].
  Future<File> saveToTemporary(ReceiptData data, Uint8List pdfBytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = buildFileName(data);
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  static pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9.5,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

