import '../ui.dart';
import 'client_detail_screen.dart' show fmtMeasure;

/// Saisie rapide : les champs sont pré-remplis avec les dernières mesures du client.
class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({super.key, required this.clientId});
  final String clientId;
  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final Map<String, TextEditingController> _c = {};
  final _note = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final last = context.read<AppStore>().measurementsOf(widget.clientId).firstOrNull;
    for (final l in kMeasureLabels) {
      _c[l] = TextEditingController(text: last?.values[l] == null ? '' : fmtMeasure(last!.values[l]!));
    }
    for (final e in (last?.values.entries ?? const <MapEntry<String, double>>[])) {
      _c.putIfAbsent(e.key, () => TextEditingController(text: fmtMeasure(e.value)));
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _addCustom() async {
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => const _AddCustomMeasureDialog(),
    );
    if (label != null && label.isNotEmpty && !_c.containsKey(label)) {
      setState(() => _c[label] = TextEditingController());
    }
  }

  Future<void> _save() async {
    final values = <String, double>{};
    _c.forEach((k, ctrl) {
      final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
      if (v != null && v > 0) values[k] = v;
    });
    if (values.isEmpty) return toast(context, 'Saisissez au moins une mesure');
    await context.read<AppStore>().saveMeasurement(Measurement(
          id: newId(), clientId: widget.clientId, takenAt: _date, values: values, note: _note.text.trim()));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 32 - 12) / 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Mensurations (cm)'), backgroundColor: Pal.chalk),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        StaggeredFadeIn(
          index: 0,
          child: DateField(label: 'Date', value: _date, onChanged: (d) => setState(() => _date = d ?? _date), firstYear: 2020),
        ),
        const SizedBox(height: 14),
        StaggeredFadeIn(
          index: 1,
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            for (final e in _c.entries)
              SizedBox(
                width: w,
                child: TextField(
                  controller: e.value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: deco(e.key, suffix: 'cm'),
                ),
              ),
          ]),
        ),
        StaggeredFadeIn(
          index: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: _addCustom, icon: const Icon(Icons.add), label: const Text('Ajouter une mesure')),
          ),
        ),
        const SizedBox(height: 6),
        StaggeredFadeIn(
          index: 3,
          child: TextField(controller: _note, maxLines: 2, textCapitalization: TextCapitalization.sentences, decoration: deco('Remarque (facultatif)')),
        ),
        const SizedBox(height: 24),
        StaggeredFadeIn(
          index: 4,
          child: FilledButton(onPressed: _save, child: const Text('Enregistrer les mesures')),
        ),
      ]),
    );
  }
}

class _AddCustomMeasureDialog extends StatefulWidget {
  const _AddCustomMeasureDialog();

  @override
  State<_AddCustomMeasureDialog> createState() => _AddCustomMeasureDialogState();
}

class _AddCustomMeasureDialogState extends State<_AddCustomMeasureDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une mesure'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: deco('Nom de la mesure'),
        onSubmitted: (val) => Navigator.pop(context, val.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Ajouter')),
      ],
    );
  }
}
