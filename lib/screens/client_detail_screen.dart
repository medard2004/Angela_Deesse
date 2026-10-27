import '../ui.dart';
import '../widgets/order_tile.dart';
import 'client_form_screen.dart';
import 'measurement_form_screen.dart';
import 'order_form_screen.dart';

String fmtMeasure(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  Widget _values(Measurement m) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in m.values.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Pal.chalk, borderRadius: BorderRadius.circular(8)),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${e.key}  ', style: const TextStyle(color: Pal.slate, fontSize: 13)),
              TextSpan(text: '${fmtMeasure(e.value)} cm', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ])),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = s.clientById(clientId);
    if (c == null) return const Scaffold(body: Center(child: Text('Client introuvable')));
    final ms = s.measurementsOf(c.id);
    final orders = s.ordersOfClient(c.id);
    final rest = s.clientRemaining(c.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pal.chalk,
        title: const Text('Fiche client'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => push(context, ClientFormScreen(client: c))),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Supprimer ${c.name} ?', 'Ses mensurations, commandes et paiements seront supprimés.')) {
                await s.deleteClient(c.id);
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
                c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StaggeredFadeIn(
              index: 0,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (c.phone.isNotEmpty) Text(c.phone, style: const TextStyle(color: Pal.slate, fontSize: 13.5)),
              ]),
            ),
          ),
        ]),
        if (c.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StaggeredFadeIn(index: 1, child: Text(c.notes)),
          ),
        if (rest > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StaggeredFadeIn(
              index: 2,
              child: Text('Reste à payer : ${fcfa(rest)}', style: const TextStyle(color: Pal.thread, fontWeight: FontWeight.w700)),
            ),
          ),
        StaggeredFadeIn(
          index: 3,
          child: Heading('Mensurations', trailing: FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40), backgroundColor: Pal.tape, foregroundColor: Colors.white),
            onPressed: () => push(context, MeasurementFormScreen(clientId: c.id)),
            child: Text(ms.isEmpty ? 'Prendre les mesures' : 'Nouvelles mesures'),
          )),
        ),
        if (ms.isEmpty)
          const StaggeredFadeIn(index: 4, isCard: true, child: Panel(child: Text('Aucune mesure enregistrée.', style: TextStyle(color: Pal.slate))))
        else
          StaggeredFadeIn(
            index: 4,
            isCard: true,
            child: Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dernières mesures - ${fmtDate(ms.first.takenAt)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _values(ms.first),
                if (ms.first.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(ms.first.note, style: const TextStyle(color: Pal.slate))),
              ]),
            ),
          ),
        if (ms.length > 1)
          StaggeredFadeIn(
            index: 5,
            isCard: true,
            child: Panel(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text('Historique des mesures (${ms.length - 1})', style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in ms.skip(1)) ...[
                    Row(children: [
                      Expanded(child: Text(fmtDate(m.takenAt), style: const TextStyle(fontWeight: FontWeight.w700))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () async {
                          if (await confirm(context, 'Supprimer ces mesures ?', fmtDate(m.takenAt))) await s.deleteMeasurement(m.id);
                        },
                      ),
                    ]),
                    _values(m),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        StaggeredFadeIn(
          index: 6,
          child: Heading('Commandes', trailing: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle'),
            onPressed: () => push(context, OrderFormScreen(clientId: c.id)),
          )),
        ),
        if (orders.isEmpty) const StaggeredFadeIn(index: 7, isCard: true, child: Panel(child: Text('Aucune commande.', style: TextStyle(color: Pal.slate)))),
        for (var i = 0; i < orders.length; i++)
          StaggeredFadeIn(
            index: 8 + i,
            isCard: true,
            child: OrderTile(orders[i]),
          ),
      ]),
    );
  }
}
