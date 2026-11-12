import '../ui.dart';
import 'apprentice_screen.dart';
import 'receipt_screen.dart';

class ApprenticeDetailScreen extends StatelessWidget {
  const ApprenticeDetailScreen({super.key, required this.apprenticeId});
  final String apprenticeId;

  void _openReceipt(BuildContext context, Apprentice a, ApprenticePayment p) {
    final s = context.read<AppStore>();
    final toDate = s.paymentsOfApprentice(a.id).where((x) => x.receiptNo <= p.receiptNo).fold(0, (t, x) => t + x.amount);
    final rest = (a.totalFee - toDate).clamp(0, 1 << 40).toInt();
    openReceiptScreen(
      context,
      ReceiptData(
        receiptNo: p.receiptNo.toString().padLeft(4, '0'),
        atelierName: s.atelierName,
        title: 'Reçu de versement',
        beneficiaryName: a.name,
        beneficiaryRole: 'Apprenti(e)',
        beneficiaryPhone: a.phone,
        date: p.paidAt,
        amountPaid: p.amount,
        note: p.note.isEmpty ? 'Versement de formation' : p.note,
        totalFee: a.totalFee,
        totalPaidToDate: toDate,
        remainingAmount: rest,
        nextDueDate: a.nextDue,
        stampText: rest <= 0 ? 'SOLDÉ' : 'VERSÉ',
        itemDetail: 'Formation couture',
      ),
    );
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
        title: const Text('Fiche Apprenti'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => push(context, ApprenticeFormScreen(apprentice: a))),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Supprimer ${a.name} ?', 'Son historique de paiements sera supprimé.')) {
                await s.deleteApprentice(a.id);
                if (context.mounted) Navigator.pop(context);
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
                if (a.phone.isNotEmpty) Text(a.phone, style: const TextStyle(color: Pal.slate, fontSize: 13.5)),
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
                        final p = await s.addApprenticePayment(a.id, amount, note);
                        if (context.mounted) _openReceipt(context, a, p);
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
                    Text(fcfa(payments[i].amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.close, size: 19, color: Pal.slate),
                  onPressed: () async {
                    if (await confirm(context, 'Supprimer ce versement ?', fcfa(payments[i].amount))) {
                      await s.deleteApprenticePayment(payments[i].id);
                    }
                  },
                ),
              ]),
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
