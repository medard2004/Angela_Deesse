class PhoneNormalizationResult {
  final bool isValid;
  final String? e164; // ex: +22890112233
  final String? digitsOnly; // ex: 22890112233
  final String? error; // 'Aucun numéro enregistré' ou 'Numéro invalide'

  const PhoneNormalizationResult._({
    required this.isValid,
    this.e164,
    this.digitsOnly,
    this.error,
  });

  factory PhoneNormalizationResult.success({
    required String e164,
    required String digitsOnly,
  }) =>
      PhoneNormalizationResult._(
        isValid: true,
        e164: e164,
        digitsOnly: digitsOnly,
      );

  factory PhoneNormalizationResult.error(String message) =>
      PhoneNormalizationResult._(
        isValid: false,
        error: message,
      );
}

/// Normalise un numéro de téléphone sans jamais modifier le numéro stocké en base :
/// 1. Retire espaces, tirets, points, parenthèses.
/// 2. Préserve « + » initial ; convertit un « 00 » initial en « + ».
/// 3. Sinon préfixe l'indicatif [defaultCountryCode] (défaut '228', Togo).
/// 4. Ne supprime JAMAIS automatiquement un zéro initial.
/// 5. Valide 7 à 15 chiffres au total (norme E.164).
PhoneNormalizationResult normalizePhoneNumber(
  String? rawPhone, {
  String defaultCountryCode = '228',
}) {
  if (rawPhone == null || rawPhone.trim().isEmpty) {
    return PhoneNormalizationResult.error('Aucun numéro enregistré');
  }

  // 1. Nettoyage des séparateurs usuels
  var cleaned = rawPhone.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
  if (cleaned.isEmpty) {
    return PhoneNormalizationResult.error('Aucun numéro enregistré');
  }

  // 2. Gestion de l'indicatif initial
  if (cleaned.startsWith('00')) {
    cleaned = '+${cleaned.substring(2)}';
  } else if (!cleaned.startsWith('+')) {
    final cleanIndicatif = defaultCountryCode.replaceAll(RegExp(r'[^\d]'), '');
    cleaned = '+$cleanIndicatif$cleaned';
  }

  // Vérifier la structure : doit commencer par + suivi uniquement de chiffres
  if (!RegExp(r'^\+\d+$').hasMatch(cleaned)) {
    return PhoneNormalizationResult.error('Numéro invalide');
  }

  final digits = cleaned.substring(1); // sans le '+'
  // Norme E.164 : entre 7 et 15 chiffres
  if (digits.length < 7 || digits.length > 15) {
    return PhoneNormalizationResult.error('Numéro invalide');
  }

  return PhoneNormalizationResult.success(
    e164: cleaned,
    digitsOnly: digits,
  );
}
