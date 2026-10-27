import '../ui.dart';
import 'client_detail_screen.dart';
import 'order_form_screen.dart';
import 'receipt_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  void _openReceiptForClientPayment(BuildContext context, Order o, Client? client, ClientPayment cp) {
    final s = context.read<AppStore>();
    final toDate = s.paymentsOfOrder(o.id).where((p) => p.paidAt.isBefore(cp.paidAt) || p.paidAt.isAtSameMomentAs(cp.paidAt)).fold(0, (sum, p) => sum + p.amount);
    final remaining = (o.price - toDate).clamp(0, 1 << 40).toInt();
    final cleanNo = cp.id.replaceAll(RegExp(r'[^0-9]'), '');
    openReceiptScreen(
      context,
      ReceiptData(
        receiptNo: cleanNo.isEmpty ? '0001' : cleanNo.padLeft(4, '0'),
        atelierName: s.atelierName,
        title: 'Reçu de paiement commande',
        beneficiaryName: client?.name ?? 'Client',
        beneficiaryRole: 'Client(e)',
        beneficiaryPhone: client?.phone ?? '',
        date: cp.paidAt,
        amountPaid: cp.amount,
        note: cp.note.isEmpty ? 'Paiement commande' : cp.note,
        totalFee: o.price,
        totalPaidToDate: toDate,
        remainingAmount: remaining,
        nextDueDate: o.deliveryDate,
        stampText: remaining <= 0 ? 'SOLDÉ' : 'PAYÉ',
        itemDetail: o.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final o = s.orderById(orderId);
    if (o == null) return const Scaffold(body: Center(child: Text('Commande introuvable')));
    final client = s.clientById(o.clientId);
    final paid = s.paidOf(o);
    final rest = s.remainingOf(o);
    final late = o.isActive && daysUntil(o.deliveryDate) < 0;
    final payments = s.paymentsOfOrder(o.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pal.chalk,
        title: const Text('Commande'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => push(context, OrderFormScreen(order: o))),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Supprimer la commande ?', 'Ses paiements seront aussi supprimés.')) {
                await s.deleteOrder(o.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        StaggeredFadeIn(
          index: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            if (client != null)
              InkWell(
                onTap: () => push(context, ClientDetailScreen(clientId: client.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(client.name, style: const TextStyle(color: Pal.slate, fontSize: 14, decoration: TextDecoration.underline)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        StaggeredFadeIn(
          index: 1,
          isCard: true,
          child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Avancement', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              VerticalProgressTimeline<OrderStatus>(
                steps: OrderStatus.values,
                currentStep: o.status,
                labelBuilder: (st) => st.label,
                onSelect: (st) => s.saveOrder(o.copyWith(status: st)),
              ),
              const Divider(height: 28),
              _Line(Icons.event_outlined, 'Livraison', '${fmtDate(o.deliveryDate)}${o.isActive ? '  -  ${countdown(o.deliveryDate)}' : ''}', color: late ? Pal.thread : null),
              if (o.fittingDate != null) _Line(Icons.straighten, 'Essayage', '${fmtDate(o.fittingDate!)}  -  ${countdown(o.fittingDate!)}'),
              if (o.fabric.isNotEmpty) _Line(Icons.texture, 'Tissu', o.fabric),
            ]),
          ),
        ),
        if (o.photos.isNotEmpty) ...[
          const StaggeredFadeIn(index: 2, child: Heading('Photos')),
          StaggeredFadeIn(
            index: 3,
            isCard: true,
            child: SizedBox(
              height: 120,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (var i = 0; i < o.photos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: StaggeredFadeIn(
                      index: i,
                      isCard: true,
                      child: PhotoThumb(o.photos[i], size: 120, radius: 14),
                    ),
                  ),
              ]),
            ),
          ),
          if (o.status == OrderStatus.livree)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.collections_outlined),
                label: const Text('Ajouter aux réalisations'),
                onPressed: () async {
                  for (final ph in o.photos) {
                    await s.saveRealisation(Realisation(id: newId(), photo: ph, clientId: o.clientId, caption: o.title, createdAt: DateTime.now()));
                  }
                  if (context.mounted) toast(context, 'Photos ajoutées à la galerie');
                },
              ),
            ),
        ],
        const StaggeredFadeIn(index: 4, child: Heading('Paiements')),
        StaggeredFadeIn(
          index: 5,
          isCard: true,
          child: Panel(
            child: Column(children: [
              _Money('Prix total', fcfa(o.price)),
              _Money('Déjà versé', fcfa(paid)),
              _Money('Reste à payer', fcfa(rest), bold: true, color: rest > 0 ? Pal.thread : Pal.sage),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: o.price == 0 ? 0 : (paid / o.price).clamp(0, 1).toDouble(),
                  minHeight: 8, backgroundColor: Pal.line, color: Pal.sage,
                ),
              ),
              if (rest > 0) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Enregistrer un paiement'),
                    onPressed: () => showPaymentSheet(
                      context,
                      title: 'Paiement de ${client?.name ?? 'client'}',
                      max: rest,
                      onSave: (amount, note) async {
                        await s.addClientPayment(o.id, amount, note);
                        if (context.mounted) {
                          final updatedPaid = s.paidOf(o);
                          final updatedRest = s.remainingOf(o);
                          openReceiptScreen(
                            context,
                            ReceiptData(
                              receiptNo: '${(DateTime.now().millisecondsSinceEpoch % 10000)}'.padLeft(4, '0'),
                              atelierName: s.atelierName,
                              title: 'Reçu de commande',
                              beneficiaryName: client?.name ?? 'Client',
                              beneficiaryRole: 'Client(e)',
                              beneficiaryPhone: client?.phone ?? '',
                              date: DateTime.now(),
                              amountPaid: amount,
                              note: note.isEmpty ? 'Acompte / règlement commande' : note,
                              totalFee: o.price,
                              totalPaidToDate: updatedPaid,
                              remainingAmount: updatedRest,
                              nextDueDate: o.deliveryDate,
                              stampText: updatedRest <= 0 ? 'SOLDÉ' : 'PAYÉ',
                              itemDetail: o.title,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
        if (payments.isNotEmpty) ...[
          const StaggeredFadeIn(index: 6, child: Heading('Historique des paiements')),
          for (var i = 0; i < payments.length; i++)
            StaggeredFadeIn(
              index: 7 + i,
              isCard: true,
              child: Panel(
                onTap: () => _openReceiptForClientPayment(context, o, client, payments[i]),
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fcfa(payments[i].amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${fmtDate(payments[i].paidAt)}${payments[i].note.isEmpty ? '' : '  -  ${payments[i].note}'}', style: const TextStyle(color: Pal.slate, fontSize: 13)),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Voir le reçu',
                    icon: const Icon(Icons.receipt_long_outlined, size: 20, color: Pal.cobalt),
                    onPressed: () => _openReceiptForClientPayment(context, o, client, payments[i]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () async {
                      if (await confirm(context, 'Supprimer ce paiement ?', fcfa(payments[i].amount))) await s.deleteClientPayment(payments[i].id);
                    },
                  ),
                ]),
              ),
            ),
        ],
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.label, this.value, {this.color});
  final IconData icon;
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Pal.slate),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Pal.slate))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
        ]),
      );
}

class _Money extends StatelessWidget {
  const _Money(this.label, this.value, {this.bold = false, this.color});
  final String label, value;
  final bool bold;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Pal.slate)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 17 : 15, color: color)),
        ]),
      );
}
