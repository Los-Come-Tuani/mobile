import 'formatters.dart';
import 'time_parser.dart';

/// Horas de salida de los circuitos que arma el usuario.
abstract final class StartTimes {
  /// Cada media hora, de 7:00 a.m. a 3:00 p.m.
  static final List<String> suggested = [
    for (var minutes = 7 * 60; minutes <= 15 * 60; minutes += 30)
      Formatters.minutesOfDay(minutes),
  ];

  /// [suggested] más [current] si es una hora a la medida (7:45 a.m.), en
  /// orden, para que siempre se pueda ver y volver a elegir.
  static List<String> including(String current) {
    final minutes = TimeParser.minutesOfDay(current);
    if (minutes == null || suggested.contains(current)) return suggested;
    return [...suggested, current]..sort(
      (a, b) => (TimeParser.minutesOfDay(a) ?? 0).compareTo(
        TimeParser.minutesOfDay(b) ?? 0,
      ),
    );
  }
}
