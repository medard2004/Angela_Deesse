import '../ui.dart';

/// Renvoie l'identifiant du client enregistré (utile depuis le formulaire de commande).
class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.client});
  final Client? client;
  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.client?.name);
  late final _phone = TextEditingController(text: widget.client?.phone);
  late final _notes = TextEditingController(text: widget.client?.notes);

  @override
  void dispose() {
    for (final c in [_name, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final id = widget.client?.id ?? newId();
    await context.read<AppStore>().saveClient(
        Client(id: id, name: _name.text.trim(), phone: _phone.text.trim(), notes: _notes.text.trim()));
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.client == null ? 'Nouveau client' : 'Modifier le client'), backgroundColor: Pal.chalk),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            StaggeredFadeIn(
              index: 0,
              child: TextFormField(
                controller: _name, autofocus: widget.client == null,
                textCapitalization: TextCapitalization.words,
                decoration: deco('Nom'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Indiquez le nom' : null,
              ),
            ),
            const SizedBox(height: 14),
            StaggeredFadeIn(
              index: 1,
              child: TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: deco('Téléphone')),
            ),
            const SizedBox(height: 14),
            StaggeredFadeIn(
              index: 2,
              child: TextFormField(controller: _notes, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: deco('Notes')),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 3,
              child: FilledButton(onPressed: _save, child: const Text('Enregistrer')),
            ),
          ]),
        ),
      );
}
