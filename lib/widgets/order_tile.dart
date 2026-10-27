import '../ui.dart';
import '../screens/order_detail_screen.dart';

class OrderTile extends StatelessWidget {
  const OrderTile(this.order, {super.key});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final client = s.clientById(order.clientId);
    final rest = s.remainingOf(order);
    final late = order.isActive && daysUntil(order.deliveryDate) < 0;
    void open() => push(context, OrderDetailScreen(orderId: order.id));
    return Panel(
      onTap: open,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        PhotoThumb(order.photos.isEmpty ? null : order.photos.first, size: 50, radius: 14, onTap: open),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(client?.name ?? 'Client supprimé', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: -.2)),
            const SizedBox(height: 2),
            Text(order.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Pal.slate, fontSize: 12.5)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.event_outlined, size: 13, color: late ? Pal.thread : Pal.slate),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  order.isActive ? countdown(order.deliveryDate) : 'Livrée le ${fmtDate(order.deliveryDate)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: late ? Pal.thread : Pal.slate, fontWeight: late ? FontWeight.w700 : FontWeight.w600),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusChip(order.status, late: late),
          if (rest > 0) ...[
            const SizedBox(height: 6),
            Text(fcfa(rest), style: const TextStyle(color: Pal.thread, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ],
        ]),
      ]),
    );
  }
}
