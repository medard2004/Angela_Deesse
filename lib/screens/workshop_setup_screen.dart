import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../shell/app_shell.dart';
import '../widgets/common.dart';

/// Étape 3 : Configuration ultra-rapide de l'atelier
/// - Nom de l'atelier
/// - Quartier / Ville
/// - Upload de logo (optionnel)
class WorkshopSetupScreen extends StatefulWidget {
  const WorkshopSetupScreen({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  State<WorkshopSetupScreen> createState() => _WorkshopSetupScreenState();
}

class _WorkshopSetupScreenState extends State<WorkshopSetupScreen> {
  final _nameController = TextEditingController(text: 'Miva Couture');
  final _locationController = TextEditingController(text: 'Tokoin, Lomé');
  String? _customLogoPath;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final photo = await pickPhoto(context);
    if (photo != null) {
      setState(() => _customLogoPath = photo);
    }
  }

  void _finish() {
    final name = _nameController.text.trim().isEmpty ? 'Miva Couture' : _nameController.text.trim();
    final location = _locationController.text.trim().isEmpty ? 'Quartier Atelier' : _locationController.text.trim();

    final store = context.read<AppStore>();
    final newAtelier = Atelier(
      id: 'at_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      city: location,
      phone: widget.phoneNumber,
      country: 'Togo',
      currency: 'FCFA',
      specialties: 'Haute couture africaine',
      isActive: true,
    );

    store.addAtelier(newAtelier);
    store.authenticate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Atelier "$name" prêt ! Bienvenue.'),
        backgroundColor: Pal.statutPreteFg,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
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
              const SizedBox(height: 10),

              Text(
                'Votre Atelier',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Personnalisez votre espace en un instant',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 13.5,
                  color: colors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Upload du Logo rond avec badge caméra
              GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Pal.ocre, width: 2),
                        boxShadow: softShadow(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _customLogoPath != null
                          ? PhotoThumb(_customLogoPath, size: 110, radius: 55)
                          : Image.asset(
                              'assets/brand/png/emblem_512.png',
                              fit: BoxFit.contain,
                            ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Pal.terreBogolan,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 17,
                        color: Pal.cremeCoton,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: _pickLogo,
                style: TextButton.styleFrom(
                  foregroundColor: Pal.ocre,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                child: const Text('Changer le logo'),
              ),

              const SizedBox(height: 28),

              // 1. Nom de l'atelier
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nom de l\'atelier',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              TextField(
                controller: _nameController,
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ex: Miva Couture',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Pal.ocre, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.storefront_outlined, color: Pal.ocre),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Quartier / Ville
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quartier / Ville',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              TextField(
                controller: _locationController,
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ex: Tokoin, Lomé',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Pal.ocre, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Pal.ocre),
                ),
              ),

              const Spacer(),

              // Bouton Terminer / Ouvrir l'atelier
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _finish,
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.terreBogolan,
                    foregroundColor: Pal.cremeCoton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ouvrir mon atelier',
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

