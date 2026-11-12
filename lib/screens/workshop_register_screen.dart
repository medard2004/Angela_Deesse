import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../widgets/common.dart';
import 'otp_verification_screen.dart';

/// Écran d'inscription et de configuration d'un atelier SaaS (ou connexion).
class WorkshopRegisterScreen extends StatefulWidget {
  const WorkshopRegisterScreen({super.key, this.isAddingNew = false, this.initialIsLogin = false});
  final bool isAddingNew;
  final bool initialIsLogin;

  @override
  State<WorkshopRegisterScreen> createState() => _WorkshopRegisterScreenState();
}

class _WorkshopRegisterScreenState extends State<WorkshopRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isLogin = widget.initialIsLogin;
  final _workshopName = TextEditingController();
  final _ownerName = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();

  String _selectedCountry = 'Togo';
  String _selectedCurrency = 'FCFA';
  final List<String> _selectedSpecialties = ['Bazin brodé', 'Wax & Pagne'];

  final List<String> _countries = [
    'Togo',
    'Bénin',
    'Côte d\'Ivoire',
    'Sénégal',
    'Cameroun',
    'Mali',
    'Burkina Faso',
    'Guinée',
    'Gabon',
    'Congo',
    'France (Diaspora)',
  ];

  final List<String> _currencies = ['FCFA', 'GNF', 'EUR', 'USD'];

  final List<String> _availableSpecialties = [
    'Bazin brodé',
    'Wax & Pagne',
    'Kente & Faso Danfani',
    'Robes de mariée & soirée',
    'Costumes & Vestes',
    'Chemises & Tuniques',
    'Couture Enfants',
  ];

  @override
  void dispose() {
    _workshopName.dispose();
    _ownerName.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<AppStore>();
    final workshopName = _workshopName.text.trim().isEmpty ? 'Miva Couture' : _workshopName.text.trim();
    final phone = _phone.text.trim();

    if (!_isLogin) {
      final newAtelier = Atelier(
        id: 'at_${DateTime.now().millisecondsSinceEpoch}',
        name: workshopName,
        ownerName: _ownerName.text.trim().isEmpty ? 'Maître Couturier' : _ownerName.text.trim(),
        country: _selectedCountry,
        city: _city.text.trim().isEmpty ? 'Lomé' : _city.text.trim(),
        currency: _selectedCurrency,
        phone: phone,
        specialties: _selectedSpecialties.isEmpty
            ? 'Haute couture africaine'
            : _selectedSpecialties.join(', '),
        isActive: true,
      );
      store.addAtelier(newAtelier);
    }

    // Passage obligatoire par l'étape de vérification OTP
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: phone,
          workshopName: workshopName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isAddingNew
              ? 'Nouvel Atelier'
              : (_isLogin ? 'Connexion Atelier' : 'Inscription Atelier'),
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Logo centré
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Pal.ocre, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/brand/png/emblem_512.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(child: AfricanPatternDivider(height: 14)),
              const SizedBox(height: 12),

              // Onglet de bascule Inscription / Connexion (si pas en mode ajout)
              if (!widget.isAddingNew)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = false),
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !_isLogin ? Pal.terreBogolan : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'Créer un atelier',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: !_isLogin ? Pal.cremeCoton : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = true),
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _isLogin ? Pal.terreBogolan : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'Accéder à mon atelier',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _isLogin ? Pal.cremeCoton : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // En-tête explicatif
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: kBorderRadius,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.tagBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Pal.ocre, width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.storefront_outlined, color: Pal.ocre, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLogin ? 'Connexion Sécurisée' : 'Enregistrement de l\'Atelier',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLogin
                                ? 'Entrez votre numéro pour recevoir votre code d\'accès.'
                                : 'Configurez les paramètres de travail de votre salon de couture.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Champs du formulaire
              Text(
                'INFORMATIONS PRINCIPALES',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Pal.ocre,
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: deco('Téléphone / WhatsApp du Maître Artisan *', hint: '+228 90 00 00 00'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir votre numéro' : null,
              ),

              if (!_isLogin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _workshopName,
                  decoration: deco('Nom de l\'atelier ou salon de couture *', hint: 'Ex: Maison Miva Couture'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir le nom de l\'atelier' : null,
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerName,
                  decoration: deco('Nom du Maître Couturier / Styliste', hint: 'Ex: Maître Miva'),
                ),

                const SizedBox(height: 20),
                Text(
                  'LOCALISATION & DEVISE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: Pal.ocre,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: deco('Pays'),
                        dropdownColor: colors.surface,
                        items: _countries
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: colors.textPrimary, fontSize: 13.5))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCountry = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: deco('Devise'),
                        dropdownColor: colors.surface,
                        items: _currencies
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: colors.textPrimary, fontSize: 13.5))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCurrency = v);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _city,
                  decoration: deco('Ville & Quartier', hint: 'Ex: Lomé (Tokoin) ou Abidjan (Cocody)'),
                ),

                const SizedBox(height: 20),
                Text(
                  'SPÉCIALITÉS COUTURIÈRES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: Pal.ocre,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSpecialties.map((spec) {
                    final isSelected = _selectedSpecialties.contains(spec);
                    return FilterChip(
                      label: Text(spec),
                      selected: isSelected,
                      selectedColor: Pal.cremeCoton,
                      checkmarkColor: Pal.terreBogolan,
                      backgroundColor: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Pal.ocre : colors.border,
                        ),
                      ),
                      labelStyle: TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Pal.terreBogolan : colors.textPrimary,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedSpecialties.add(spec);
                          } else {
                            _selectedSpecialties.remove(spec);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 36),

              // Bouton Suivant -> OTP
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.terreBogolan,
                    foregroundColor: Pal.cremeCoton,
                    shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isLogin ? 'Recevoir mon code d\'accès' : 'Continuer vers la vérification',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
