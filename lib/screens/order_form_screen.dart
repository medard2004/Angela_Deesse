import '../ui.dart';
import 'client_form_screen.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.order, this.clientId, this.modeleId});
  final Order? order;
  final String? clientId, modeleId;
  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.order?.title);
  late final _fabric = TextEditingController(text: widget.order?.fabric);
  late final _price = TextEditingController(text: widget.order == null ? '' : '${widget.order!.price}');
  final _deposit = TextEditingController();
  late String? _clientId = widget.order?.clientId ?? widget.clientId;
  late String? _modeleId = widget.order?.modeleId ?? widget.modeleId;
  late DateTime? _delivery = widget.order?.deliveryDate;
  late DateTime? _fitting = widget.order?.fittingDate;
  late OrderStatus _status = widget.order?.status ?? OrderStatus.attente;
  late final List<String> _photos = [...?widget.order?.photos];

  @override
  void initState() {
    super.initState();
    final m = context.read<AppStore>().modeleById(_modeleId);
    if (widget.order == null && m != null) _applyModele(m.id);
  }

  @override
  void dispose() {
    for (final c in [_title, _fabric, _price, _deposit]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyModele(String? id) {
    final m = context.read<AppStore>().modeleById(id);
    _modeleId = id;
    if (m == null) return;
    if (_title.text.trim().isEmpty) _title.text = m.name;
    if (m.photo != null && !_photos.contains(m.photo)) _photos.add(m.photo!);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_clientId == null) return toast(context, 'Choisissez un client');
    if (_delivery == null) return toast(context, 'Choisissez la date de livraison');
    final store = context.read<AppStore>();
    final o = Order(
      id: widget.order?.id ?? newId(),
      clientId: _clientId!,
      modeleId: _modeleId,
      title: _title.text.trim(),
      fabric: _fabric.text.trim(),
      price: parseMoney(_price.text),
      deliveryDate: _delivery!,
      fittingDate: _fitting,
      status: _status,
      photos: _photos,
      createdAt: widget.order?.createdAt ?? DateTime.now(),
    );
    await store.saveOrder(o);
    final dep = parseMoney(_deposit.text);
    if (widget.order == null && dep > 0) await store.addClientPayment(o.id, (dep > o.price ? o.price : dep), 'Acompte');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final editing = widget.order != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Modifier la commande' : 'Nouvelle commande')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          StaggeredFadeIn(
            index: 0,
            child: Row(children: [
              Expanded(
                child: PickerField<String>(
                  label: 'Client',
                  value: _clientId,
                  items: [for (final c in s.clients) (c.id, c.name)],
                  onChanged: (v) => setState(() => _clientId = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Nouveau client',
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () async {
                  final id = await Navigator.of(context).push<String>(FadePageRoute<String>(builder: (_) => const ClientFormScreen()));
                  if (id != null) setState(() => _clientId = id);
                },
              ),
            ]),
          ),
          const SizedBox(height: 14),
          if (s.modeles.isNotEmpty) ...[
            StaggeredFadeIn(
              index: 1,
              child: PickerField<String>(
                label: 'Réutiliser un modèle',
                value: _modeleId,
                allowClear: true,
                items: [for (final m in s.modeles) (m.id, m.name)],
                onChanged: (v) => setState(() => _applyModele(v)),
              ),
            ),
            const SizedBox(height: 14),
          ],
          StaggeredFadeIn(
            index: 2,
            child: TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: deco('Modèle / description', hint: 'Ex. Robe de soirée'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Indiquez le modèle' : null,
            ),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 3,
            child: TextFormField(controller: _fabric, decoration: deco('Tissu', hint: 'Ex. Wax bleu, 6 yards')),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 4,
            child: moneyField(_price, 'Prix total', validator: (v) => parseMoney(v ?? '') <= 0 ? 'Indiquez le prix' : null),
          ),
          if (!editing) ...[
            const SizedBox(height: 14),
            StaggeredFadeIn(
              index: 5,
              child: moneyField(_deposit, 'Acompte versé (facultatif)'),
            ),
          ],
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 6,
            child: DateField(label: 'Date de livraison', value: _delivery, onChanged: (d) => setState(() => _delivery = d)),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 7,
            child: DateField(label: "Date d'essayage (facultatif)", value: _fitting, allowClear: true, onChanged: (d) => setState(() => _fitting = d)),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 8,
            child: PickerField<OrderStatus>(
              label: 'Statut',
              value: _status,
              items: [for (final st in OrderStatus.values) (st, st.label)],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ),
          const SizedBox(height: 18),
          const StaggeredFadeIn(
            index: 9,
            child: Text('Photos', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 10,
            child: PhotoStrip(
              photos: _photos,
              onAdd: () async {
                final path = await pickPhoto(context);
                if (path != null) setState(() => _photos.add(path));
              },
              onRemove: (p) => setState(() => _photos.remove(p)),
            ),
          ),
          const SizedBox(height: 24),
          StaggeredFadeIn(
            index: 11,
            child: FilledButton(onPressed: _save, child: Text(editing ? 'Enregistrer' : 'Créer la commande')),
          ),
        ]),
      ),
    );
  }
}
