/// Utilitaires de tri insensible à la casse et aux accents.
String removeDiacritics(String str) {
  const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÌÍÎÏìíîïÙÚÛÜùúûüÿÑñÇç';
  const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeIIIIiiiiUUUUuuuuyNnCc';
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

int compareCaseAndAccentInsensitive(String a, String b) {
  final cleanA = removeDiacritics(a.trim().toLowerCase());
  final cleanB = removeDiacritics(b.trim().toLowerCase());
  final cmp = cleanA.compareTo(cleanB);
  if (cmp != 0) return cmp;
  return a.compareTo(b);
}
