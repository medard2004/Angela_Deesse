/// Horloge abstraite pour injection de temps dans les repositories.
abstract class Clock {
  DateTime now();
}

/// Horloge système par défaut en millisecondes UTC.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
