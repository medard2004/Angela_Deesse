import 'dart:math' as math;
import '../ui.dart';

/// Modèle de données pour l'écran de reçu animé.
class ReceiptData {
  const ReceiptData({
    required this.receiptNo,
    required this.atelierName,
    required this.title,
    required this.beneficiaryName,
    required this.beneficiaryRole, // 'Apprenti(e)' ou 'Client(e)'
    this.beneficiaryPhone = '',
    required this.date,
    required this.amountPaid,
    this.note = '',
    required this.totalFee,
    required this.totalPaidToDate,
    required this.remainingAmount,
    this.nextDueDate,
    this.stampText = 'VERSÉ',
    this.itemDetail,
  });

  final String receiptNo;
  final String atelierName;
  final String title;
  final String beneficiaryName;
  final String beneficiaryRole;
  final String beneficiaryPhone;
  final DateTime date;
  final int amountPaid;
  final String note;
  final int totalFee;
  final int totalPaidToDate;
  final int remainingAmount;
  final DateTime? nextDueDate;
  final String stampText;
  final String? itemDetail;

  bool get isFullyPaid => remainingAmount <= 0;
}

/// Route avec fondu enchaîné de 300 ms conforme à la directive :
/// "Transition de page : PageRouteBuilder + FadeTransition (300 ms), pas de MaterialPageRoute."
class ReceiptPageRoute<T> extends PageRouteBuilder<T> {
  ReceiptPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
              reverseCurve: Curves.easeInOut,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        );
}

/// Ouvre l'écran de reçu avec la transition de fondu de 300 ms.
Future<void> openReceiptScreen(BuildContext context, ReceiptData data) =>
    Navigator.of(context).push(ReceiptPageRoute(builder: (_) => ReceiptScreen(data: data)));

/// Écran d'animation du reçu :
/// "ÉLÉMENT QUI SORT D'UNE FENTE, PUIS TAMPON, PUIS ACTIONS"
/// Timeline exacte : 5250 ms, contrôleur unique, courbes et intervalles stricts.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.data});
  final ReceiptData data;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Intervalles conformes à la directive (durée totale = 5250 ms)
  // 1) Sortie papier : 1050 -> 3950 ms (2900 ms) => Interval(0.200, 0.752, curve: Curves.easeInOutSine)
  late final Animation<Offset> _paperSlide;

  // 2) Tampon échelle : 4250 -> 4550 ms (300 ms) => Interval(0.810, 0.867, curve: Curves.easeIn)
  late final Animation<double> _stampScale;

  // 3) Tampon opacité : 4250 -> 4400 ms (150 ms) => Interval(0.810, 0.838, curve: Curves.easeOut)
  late final Animation<double> _stampOpacity;

  // 4) Indicateur d'état disparition : 4750 -> 4950 ms (200 ms) => Interval(0.905, 0.943), 1 -> 0
  late final Animation<double> _statusOpacity;

  // 5) Boutons d'action entrée : 5000 -> 5200 ms (200 ms) => Interval(0.952, 0.990), 0 -> 1
  late final Animation<double> _buttonsOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5250),
    );

    // Papier : offset départ (0, -1), offset final (0, 0), Curves.easeInOutSine
    _paperSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.200, 0.752, curve: Curves.easeInOutSine),
    ));

    // Tampon échelle : 2.3 -> 1.0, Curves.easeIn
    _stampScale = Tween<double>(
      begin: 2.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.810, 0.867, curve: Curves.easeIn),
    ));

    // Tampon opacité : 0.0 -> 0.9, Curves.easeOut
    _stampOpacity = Tween<double>(
      begin: 0.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.810, 0.838, curve: Curves.easeOut),
    ));

    // Indicateur d'état : 1.0 -> 0.0
    _statusOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.905, 0.943, curve: Curves.linear),
    ));

    // Boutons d'action : 0.0 -> 1.0
    _buttonsOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.952, 0.990, curve: Curves.linear),
    ));

    // Démarrage automatique à T0 (ouverture)
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shareWhatsApp() {
    toast(context, 'Reçu prêt pour envoi WhatsApp au ${widget.data.beneficiaryPhone.isNotEmpty ? widget.data.beneficiaryPhone : widget.data.beneficiaryName}');
  }

  void _downloadReceipt() {
    toast(context, 'Reçu N° ${widget.data.receiptNo} enregistré dans Téléchargements (PDF)');
  }

  void _printReceipt() {
    toast(context, 'Connexion à l\'imprimante de reçus... Impression lancée !');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final paperWidth = math.min(320.0, size.width - 36.0);
    // Hauteur du papier = environ 50 % de la hauteur de l'écran, selon directive
    final paperHeight = (size.height * 0.52).clamp(380.0, 470.0);
    const guideHeight = 22.0;
    final guideWidth = paperWidth + 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.data.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Fermer',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimer',
            onPressed: _printReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Télécharger',
            onPressed: _downloadReceipt,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Zone centrale avec guide fente, papier qui sort et tampon
            Expanded(
              child: Center(
                child: SizedBox(
                  width: guideWidth,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // B) Papier masqué par un ClipRect placé SOUS le guide
                      // Le ClipRect commence sous la lèvre de la fente (top: 14)
                      Positioned(
                        top: 14,
                        child: ClipRect(
                          child: SizedBox(
                            width: paperWidth,
                            height: paperHeight + 10,
                            child: SlideTransition(
                              position: _paperSlide,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Papier blanc avec bord inférieur en dents de scie
                                  ClipPath(
                                    clipper: const ZigzagClipper(toothWidth: 14, toothHeight: 9),
                                    child: Container(
                                      width: paperWidth,
                                      height: paperHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(25),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: _ReceiptPaperContent(data: widget.data, paperHeight: paperHeight),
                                    ),
                                  ),

                                  // C) Tampon circulaire centré horizontalement, placé aux ~2/3 de la hauteur,
                                  // incliné à -12° (-0.21 rad)
                                  Positioned(
                                    top: paperHeight * 0.58,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -0.21,
                                        child: ScaleTransition(
                                          scale: _stampScale,
                                          alignment: Alignment.center,
                                          child: FadeTransition(
                                            opacity: _stampOpacity,
                                            child: _StampBadge(text: widget.data.stampText),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // A) Le guide fixe (la fente / rail) au-dessus
                      // Reste FIXE pendant toute la séquence
                      Positioned(
                        top: 0,
                        child: _PrinterSlotGuide(width: guideWidth, height: guideHeight),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Zone inférieure : indicateur d'état (D) puis boutons d'action (E)
            SizedBox(
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // D) Indicateur d'état discret, centré en bas (petit texte gris + icône)
                  // Visible de 0 à 4750 ms, s'estompe de 4750 à 4950 ms
                  FadeTransition(
                    opacity: _statusOpacity,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Pal.slate,
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Impression du reçu...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Pal.slate,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // E) Deux boutons d'action : un secondaire (sombre) et un principal (clair)
                  // Apparaissent en fondu (0 -> 1) de 5000 à 5200 ms, sans glissement
                  FadeTransition(
                    opacity: _buttonsOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Bouton secondaire (sombre)
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Pal.ink,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Télécharger', maxLines: 1, overflow: TextOverflow.ellipsis),
                              onPressed: _downloadReceipt,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Bouton principal (clair / cobalt)
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Pal.cobalt,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 3,
                                shadowColor: Pal.cobalt.withAlpha(90),
                              ),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('WhatsApp', maxLines: 1, overflow: TextOverflow.ellipsis),
                              onPressed: _shareWhatsApp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// A) Guide fente : rail horizontal métallique fixe avec cavité centrale sombre.
class _PrinterSlotGuide extends StatelessWidget {
  const _PrinterSlotGuide({required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E394E), Color(0xFF181F2E)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF475569), width: 1),
      ),
      child: Center(
        child: Container(
          width: width - 28,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF07090F),
            borderRadius: BorderRadius.circular(3),
            boxShadow: const [
              BoxShadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// B) Clipper pour découper le bas du papier en dents de scie (zigzag).
class ZigzagClipper extends CustomClipper<Path> {
  const ZigzagClipper({this.toothWidth = 14.0, this.toothHeight = 8.0});
  final double toothWidth;
  final double toothHeight;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - toothHeight);

    final count = (size.width / toothWidth).floor();
    final actualToothWidth = size.width / count;

    for (int i = 0; i < count; i++) {
      final x1 = (i + 0.5) * actualToothWidth;
      final y1 = size.height;
      final x2 = (i + 1.0) * actualToothWidth;
      final y2 = size.height - toothHeight;
      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Contenu statique du reçu, déjà entièrement dessiné dès le début.
class _ReceiptPaperContent extends StatelessWidget {
  const _ReceiptPaperContent({required this.data, required this.paperHeight});
  final ReceiptData data;
  final double paperHeight;

  Widget _line(String label, String value, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Pal.slate, fontSize: 12)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 13.5 : 12.5,
                  color: color ?? Pal.ink,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête du reçu
                  Row(
                    children: [
                      Image.asset('assets/images/logo_mark.png', height: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.atelierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Text('REÇU DE VERSEMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Pal.cobalt, letterSpacing: 1.2)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F4FD), borderRadius: BorderRadius.circular(6)),
                        child: Text('N° ${data.receiptNo}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Pal.cobaltDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _DashedLine(),
                  const SizedBox(height: 5),

                  // Infos bénéficiaire
                  _line('Date', fmtDate(data.date)),
                  _line(data.beneficiaryRole, data.beneficiaryName, bold: true),
                  if (data.beneficiaryPhone.isNotEmpty) _line('Téléphone', data.beneficiaryPhone),
                  if (data.itemDetail != null && data.itemDetail!.isNotEmpty) _line('Détail', data.itemDetail!),
                  if (data.note.isNotEmpty) _line('Motif', data.note),

                  const SizedBox(height: 5),
                  const _DashedLine(),
                  const SizedBox(height: 5),

                  // Montant versé en grand
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD6E3FF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MONTANT VERSÉ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Pal.cobalt)),
                        Flexible(
                          child: Text(
                            fcfa(data.amountPaid),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Pal.cobalt),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),
                  _line('Total formation', fcfa(data.totalFee)),
                  _line('Cumul versé à ce jour', fcfa(data.totalPaidToDate)),
                  _line(
                    'Reste à payer',
                    data.isFullyPaid ? 'Soldé' : fcfa(data.remainingAmount),
                    bold: true,
                    color: data.isFullyPaid ? Pal.sage : Pal.thread,
                  ),
                  if (data.nextDueDate != null && !data.isFullyPaid)
                    _line('Prochaine échéance', fmtDate(data.nextDueDate!), color: Pal.orange),

                  const SizedBox(height: 8),

                  // Pied de ticket : code barres / remerciement discret
                  const Column(
                    children: [
                      _BarcodeArt(),
                      SizedBox(height: 4),
                      Text(
                        'Merci pour votre confiance · Angela Dress',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Pal.slate, fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ligne pointillée horizontale type reçu de caisse.
class _DashedLine extends StatelessWidget {
  const _DashedLine();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFC7D0E5))),
            );
          }),
        );
      },
    );
  }
}

/// Code-barres décoratif au bas du reçu.
class _BarcodeArt extends StatelessWidget {
  const _BarcodeArt();
  @override
  Widget build(BuildContext context) {
    final bars = [2, 1, 3, 1, 2, 4, 1, 3, 2, 1, 4, 2, 1, 3, 1, 2, 4, 1, 2, 3, 1, 4, 2, 1, 3];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final b in bars) ...[
          Container(width: b.toDouble(), height: 16, color: const Color(0xFF334155)),
          const SizedBox(width: 2),
        ],
      ],
    );
  }
}

/// C) Tampon circulaire (~30% de la largeur du papier), incliné à -12° (-0.21 rad)
class _StampBadge extends StatelessWidget {
  const _StampBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isCancelled = text.toUpperCase() == 'ANNULÉ';
    final color = isCancelled ? Pal.thread : Pal.cobalt;
    final icon = isCancelled ? Icons.cancel_outlined : Icons.verified_rounded;

    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(24),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(color: color.withAlpha(40), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(160), width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                text.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.6,
                ),
              ),
              Text(
                'ANGELA ATELIER',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 6.5,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
