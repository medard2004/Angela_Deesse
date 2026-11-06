import '../ui.dart';
import '../data/services/contact_launcher.dart';
import '../data/utils/message_templates.dart';
import 'apprentice_screen.dart';
import 'receipt_screen.dart';

class ApprenticeDetailScreen extends StatelessWidget {
  const ApprenticeDetailScreen({super.key, required this.apprenticeId});
  final String apprenticeId;

  void _openReceipt(BuildContext context, Apprentice a, ApprenticePayment p) {
    final s = context.read<AppStore>();
    final receiptFormatted = p.receiptNumber.toString().padLeft(4, '0');
    final stamp = p.isVoided
        ? 'ANNULÉ'
        : (p.balanceAfter <= 0 ? 'SOLDÉ' : 'VERSÉ');

    openReceiptScreen(
      context,
      ReceiptData(
        receiptNo: receiptFormatted,
        atelierName: s.atelierName,
        title: 'Reçu de versement',
        beneficiaryName: a.name,
        beneficiaryRole: 'Apprenti(e)',
        beneficiaryPhone: a.phone,
        date: p.paidAt,
        amountPaid: p.amount,
        note: p.note.isEmpty ? 'Versement de formation' : p.note,
        totalFee: p.totalFeeAtPayment,
        totalPaidToDate: p.totalFeeAtPayment - p.balanceAfter,
        remainingAmount: p.balanceAfter,
        nextDueDate: a.nextDue,
        stampText: stamp,
        itemDetail: 'Formation couture',
        isVoided: p.isVoided,
        voidedAt: p.voidedAt,
        voidReason: p.voidReason,
      ),
    );
  }

  Future<void> _promptVoidPayment(BuildContext context, AppStore s, ApprenticePayment payment) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le versement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant : ${fcfa(payment.amount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Motif d\'annulation',
                hintText: 'Ex: Erreur de saisie',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Pal.thread),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler le versement'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim();
      try {
        await s.voidApprenticePayment(payment.id, reason.isEmpty ? 'Annulé' : reason);
        if (context.mounted) {
          toast(context, 'Versement annulé');
        }
      } catch (e) {
        if (context.mounted) {
          toast(context, e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', ''));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final a = s.apprenticeById(apprenticeId);
    if (a == null) return const Scaffold(body: Center(child: Text('Apprenti introuvable')));
    final paid = s.apprenticePaid(a);
    final rest = s.apprenticeRemaining(a);
    final payments = s.paymentsOfApprentice(a.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pal.chalk,
        title: const Text('Fiche Apprenti'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => push(context, ApprenticeFormScreen(apprentice: a))),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (s.activePaymentsOfApprentice(a.id).isNotEmpty) {
                toast(context, 'Impossible de supprimer un apprenti ayant des versements actifs');
                return;
              }
              if (await confirm(context, 'Supprimer ${a.name} ?', 'Cette action supprimera l\'apprenti.')) {
                try {
                  await s.deleteApprentice(a.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    toast(context, e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', ''));
                  }
                }
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        Row(children: [
          MotionCircularScale(
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Pal.cobalt,
              foregroundColor: Colors.white,
              child: Text(
                a.name.isEmpty ? '?' : a.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StaggeredFadeIn(
              index: 0,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (a.phone.isNotEmpty)
                  Row(
                    children: [
                      Text(a.phone, style: const TextStyle(color: Pal.slate, fontSize: 13.5)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final launcher = context.read<ContactLauncher?>();
                          final res = await launcher?.call(a.phone);
                          if (res != null && !res.success && context.mounted) {
                            toast(context, res.errorMessage ?? 'Impossible de passer l\'appel');
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.phone_outlined, size: 18, color: Pal.cobalt),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final launcher = context.read<ContactLauncher?>();
                          final s = context.read<AppStore>();
                          final message = (a.nextDue != null && rest > 0)
                              ? MessageTemplates.echeanceApprenti(
                                  apprenti: a.name,
                                  dueDate: a.nextDue!,
                                  amount: rest,
                                  atelier: s.atelierName,
                                )
                              : null;
                          final res = await launcher?.whatsapp(a.phone, body: message);
                          if (res != null && !res.success && context.mounted) {
                            toast(context, res.errorMessage ?? 'Impossible d\'ouvrir WhatsApp');
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.chat_outlined, size: 18, color: Color(0xFF25D366)),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final launcher = context.read<ContactLauncher?>();
                          final s = context.read<AppStore>();
                          final message = (a.nextDue != null && rest > 0)
                              ? MessageTemplates.echeanceApprenti(
                                  apprenti: a.name,
                                  dueDate: a.nextDue!,
                                  amount: rest,
                                  atelier: s.atelierName,
                                )
                              : null;
                          final res = await launcher?.sms(a.phone, body: message);
                          if (res != null && !res.success && context.mounted) {
                            toast(context, res.errorMessage ?? 'Impossible d\'ouvrir les SMS');
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.sms_outlined, size: 18, color: Pal.slate),
                        ),
                      ),
                    ],
                  ),
                Text('Formation débutée le ${fmtDate(a.startDate)}', style: const TextStyle(color: Pal.slate, fontSize: 12)),
              ]),
            ),
          ),
        ]),
        if (a.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StaggeredFadeIn(index: 1, child: Text(a.notes)),
          ),
        const SizedBox(height: 14),
        StaggeredFadeIn(
          index: 2,
          isCard: true,
          child: Panel(
            child: Column(children: [
              _Row('Total de la formation', fcfa(a.totalFee)),
              _Row('Déjà versé', fcfa(paid), color: Pal.cobalt),
              _Row('Reste à payer', rest == 0 ? 'Soldé' : fcfa(rest), bold: true, color: rest == 0 ? Pal.sage : Pal.thread),
              if (a.nextDue != null && rest > 0)
                _Row('Prochaine échéance', '${fmtDate(a.nextDue!)}  -  ${countdown(a.nextDue!)}', color: daysUntil(a.nextDue!) < 0 ? Pal.thread : null),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: a.totalFee == 0 ? 0 : (paid / a.totalFee).clamp(0, 1).toDouble(),
                  minHeight: 8, backgroundColor: Pal.line, color: Pal.sage,
                ),
              ),
              const SizedBox(height: 14),
              if (rest > 0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Enregistrer un versement'),
                    onPressed: () => showPaymentSheet(
                      context,
                      title: 'Versement de ${a.name}',
                      max: rest,
                      onSave: (amount, note) async {
                        try {
                          final p = await s.addApprenticePayment(a.id, amount, note);
                          if (context.mounted) _openReceipt(context, a, p);
                        } catch (e) {
                          if (context.mounted) {
                            toast(context, e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '').replaceAll('StateError: ', ''));
                          }
                        }
                      },
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Pal.sage, size: 18),
                      SizedBox(width: 8),
                      Text('Formation entièrement soldée', style: TextStyle(color: Pal.sage, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ],
                  ),
                ),
            ]),
          ),
        ),
        const StaggeredFadeIn(index: 3, child: Heading('Historique des versements')),
        if (payments.isEmpty)
          const StaggeredFadeIn(index: 4, isCard: true, child: Panel(child: Text('Aucun versement enregistré pour le moment.', style: TextStyle(color: Pal.slate)))),
        for (var i = 0; i < payments.length; i++)
          StaggeredFadeIn(
            index: 4 + i,
            isCard: true,
            child: Opacity(
              opacity: payments[i].isVoided ? 0.55 : 1.0,
              child: Panel(
                onTap: () => _openReceipt(context, a, payments[i]),
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFEFF3FD), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long_rounded, color: Pal.cobalt, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        children: [
                          Text(fcfa(payments[i].amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          if (payments[i].isVoided) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Pal.thread.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Annulé${payments[i].voidReason != null && payments[i].voidReason!.isNotEmpty ? ' (${payments[i].voidReason})' : ''}',
                                style: const TextStyle(
                                  color: Pal.thread,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Reçu n°${payments[i].receiptNo.toString().padLeft(4, '0')}  ·  ${fmtDate(payments[i].paidAt)}${payments[i].note.isEmpty ? '' : '  ·  ${payments[i].note}'}',
                        style: const TextStyle(color: Pal.slate, fontSize: 12),
                      ),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Voir le reçu',
                    icon: const Icon(Icons.open_in_new_rounded, size: 19, color: Pal.cobalt),
                    onPressed: () => _openReceipt(context, a, payments[i]),
                  ),
                  if (!payments[i].isVoided)
                    IconButton(
                      tooltip: 'Annuler',
                      icon: const Icon(Icons.block, size: 19, color: Pal.thread),
                      onPressed: () => _promptVoidPayment(context, s, payments[i]),
                    ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false, this.color});
  final String label, value;
  final bool bold;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Pal.slate)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 17 : 15, color: color))),
        ]),
      );
}
