import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'otp_screen.dart';

/// Étape 1 : Saisie ultra-simple du numéro de téléphone
class AuthPhoneScreen extends StatefulWidget {
  const AuthPhoneScreen({super.key});

  @override
  State<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends State<AuthPhoneScreen> {
  final _phoneController = TextEditingController();
  String _countryCode = '+228'; // Par défaut Togo / Afrique de l'Ouest

  final List<({String code, String country})> _codes = const [
    (code: '+228', country: 'Togo'),
    (code: '+229', country: 'Bénin'),
    (code: '+225', country: 'Côte d\'Ivoire'),
    (code: '+221', country: 'Sénégal'),
    (code: '+237', country: 'Cameroun'),
    (code: '+223', country: 'Mali'),
    (code: '+226', country: 'Burkina Faso'),
    (code: '+224', country: 'Guinée'),
    (code: '+241', country: 'Gabon'),
    (code: '+242', country: 'Congo'),
    (code: '+33', country: 'France'),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre numéro de téléphone'),
          backgroundColor: Pal.statutAlerteFg,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullNumber = '$_countryCode $phone';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(phoneNumber: fullNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Médaillon officiel Miva Couture
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/brand/png/emblem_512.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Entrez votre numéro',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Nous vous enverrons un code de confirmation par SMS ou WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 13.5,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // Champ unique Numéro avec sélecteur d'indicatif
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                  boxShadow: softShadow(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    // Sélecteur indicatif
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _countryCode,
                        dropdownColor: colors.surface,
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        items: _codes
                            .map((c) => DropdownMenuItem(
                                  value: c.code,
                                  child: Text('${c.code} (${c.country})'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _countryCode = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 26, color: colors.border),
                    const SizedBox(width: 12),
                    // Champ numéro
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '90 12 34 56',
                          hintStyle: TextStyle(
                            color: colors.textSecondary.withAlpha(120),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bouton Suivant / Recevoir le code
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.terreBogolan,
                    foregroundColor: Pal.cremeCoton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Recevoir le code',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

