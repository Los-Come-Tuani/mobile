import 'formatters.dart';
import 'time_parser.dart';

/// Horas de salida de los circuitos que arma el usuario.
abstract final class StartTimes {
  /// Cada media hora, de 7:00 a.m. a 3:00 p.m. (en inglés, de 7:00 AM a 3:00
  /// PM). Se arma al pedirla, con el idioma de ahora: no la guardes.
  static List<String> get suggested => [
    for (var minutes = 7 * 60; minutes <= 15 * 60; minutes += 30)
      Formatters.minutesOfDay(minutes),
  ];

  /// [suggested] más [current] si es una hora a la medida (7:45 a.m.), en
  /// orden, para que siempre se pueda ver y volver a elegir.
  static List<String> including(String current) {
    final options = suggested;
    final minutes = TimeParser.minutesOfDay(current);
    if (minutes == null || options.contains(current)) return options;

    // La misma hora escrita en el otro idioma ("9:00 a.m." guardada en español
    // y vista en inglés) ya está en la lista: no se repite.
    final isSuggested = options.any(
      (option) => TimeParser.minutesOfDay(option) == minutes,
    );
    if (isSuggested) return options;

    return [...options, current]..sort(
      (a, b) => (TimeParser.minutesOfDay(a) ?? 0).compareTo(
        TimeParser.minutesOfDay(b) ?? 0,
      ),
    );
  }
}
