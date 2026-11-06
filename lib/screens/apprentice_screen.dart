import '../ui.dart';
import 'receipt_screen.dart';

class ApprenticeFormScreen extends StatefulWidget {
  const ApprenticeFormScreen({super.key, this.apprentice});
  final Apprentice? apprentice;
  @override
  State<ApprenticeFormScreen> createState() => _ApprenticeFormScreenState();
}

class _ApprenticeFormScreenState extends State<ApprenticeFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.apprentice?.name);
  late final _phone = TextEditingController(text: widget.apprentice?.phone);
  late final _fee = TextEditingController(text: widget.apprentice == null ? '' : '${widget.apprentice!.totalFee}');
  late final _initialPayment = TextEditingController();
  late final _notes = TextEditingController(text: widget.apprentice?.notes);
  late DateTime _start = widget.apprentice?.startDate ?? DateTime.now();
  late DateTime? _due = widget.apprentice?.nextDue;

  @override
  void initState() {
    super.initState();
    _fee.addListener(() => setState(() {}));
    _initialPayment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _fee, _initialPayment, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final isNew = widget.apprentice == null;
    final id = widget.apprentice?.id ?? newId();
    final totalFee = parseMoney(_fee.text);
    final initialPay = parseMoney(_initialPayment.text);

    if (isNew && initialPay > totalFee) {
      toast(context, 'Le premier versement ne peut pas dépasser le montant total');
      return;
    }

    final apprentice = Apprentice(
      id: id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      startDate: _start,
      totalFee: totalFee,
      nextDue: _due,
      notes: _notes.text.trim(),
    );

    final deposit = (isNew && initialPay > 0) ? initialPay : null;
    try {
      final p = await store.saveApprentice(
        apprentice,
        initialDeposit: deposit,
        depositNote: 'Acompte inscription',
      );
      if (mounted) {
        Navigator.pop(context);
        if (p != null) {
          openReceiptScreen(
            context,
            ReceiptData(
              receiptNo: 'APP-${p.receiptNo.toString().padLeft(4, '0')}',
              atelierName: store.atelierName,
              title: 'Reçu de versement apprenti',
              beneficiaryName: apprentice.name,
              beneficiaryRole: 'Apprenti(e)',
              beneficiaryPhone: apprentice.phone,
              date: p.paidAt,
              amountPaid: p.amount,
              note: p.note.isEmpty ? 'Acompte inscription formation' : p.note,
              totalFee: p.totalFeeAtPayment,
              totalPaidToDate: p.totalFeeAtPayment - p.balanceAfter,
              remainingAmount: p.balanceAfter,
              nextDueDate: apprentice.nextDue,
              stampText: p.balanceAfter <= 0 ? 'SOLDÉ' : 'VERSÉ',
              itemDetail: 'Formation couture',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        toast(context, e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '').replaceAll('StateError: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = parseMoney(_fee.text);
    final initial = parseMoney(_initialPayment.text);
    final rest = (total - initial).clamp(0, 1 << 40).toInt();
    final isNew = widget.apprentice == null;

    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Nouvel apprenti' : "Modifier l'apprenti"), backgroundColor: Pal.chalk),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          StaggeredFadeIn(
            index: 0,
            child: TextFormField(
              controller: _name, autofocus: isNew,
              textCapitalization: TextCapitalization.words, decoration: deco('Nom de l\'apprenti(e)'),
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
            child: moneyField(_fee, 'Montant total de la formation', validator: (v) => parseMoney(v ?? '') <= 0 ? 'Indiquez le montant' : null),
          ),
          if (isNew) ...[
            const SizedBox(height: 14),
            StaggeredFadeIn(
              index: 3,
              child: moneyField(
                _initialPayment,
                'Premier versement / acompte (facultatif)',
                validator: (v) {
                  final val = parseMoney(v ?? '');
                  if (val > total && total > 0) return 'Ne peut pas dépasser le montant total';
                  return null;
                },
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Pal.line),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total formation', style: TextStyle(color: Pal.slate, fontSize: 13)),
                        Text(fcfa(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Premier versement', style: TextStyle(color: Pal.slate, fontSize: 13)),
                        Text(initial > 0 ? fcfa(initial) : '0 FCFA', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Pal.cobalt)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reste à payer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                          rest == 0 && initial > 0 ? 'Soldé' : fcfa(rest),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: rest == 0 && initial > 0 ? Pal.sage : Pal.thread,
                          ),
                        ),
                      ],
                    ),
                    if (initial > 0) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 14, color: Pal.cobalt),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Un reçu officiel sera généré automatiquement avec le tampon de validation.',
                              style: TextStyle(color: Pal.cobalt, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 4,
            child: DateField(label: 'Début de la formation', value: _start, onChanged: (d) => setState(() => _start = d ?? _start)),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 5,
            child: DateField(label: 'Prochaine échéance de paiement', value: _due, allowClear: true, onChanged: (d) => setState(() => _due = d)),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 6,
            child: TextFormField(controller: _notes, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: deco('Notes')),
          ),
          const SizedBox(height: 24),
          StaggeredFadeIn(
            index: 7,
            child: FilledButton(onPressed: _save, child: Text(isNew ? 'Enregistrer et valider' : 'Enregistrer les modifications')),
          ),
        ]),
      ),
    );
  }
}
