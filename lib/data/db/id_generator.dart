import 'package:uuid/uuid.dart';

/// Générateur d'identifiants abstraits pour l'ensemble des entités de l'atelier.
/// Permet d'injecter un faux générateur déterministe lors des tests unitaires.
abstract class IdGenerator {
  String generate();
}

/// Implémentation de production utilisant les UUIDv7 (ordonnés dans le temps).
class UuidV7IdGenerator implements IdGenerator {
  const UuidV7IdGenerator([this._uuid = const Uuid()]);

  final Uuid _uuid;

  @override
  String generate() => _uuid.v7();
}
