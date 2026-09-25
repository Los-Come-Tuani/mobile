/// Lee las horas y duraciones que llegan como texto en los JSON
/// ("3:00 p.m.", "1 h 30 min").
abstract final class TimeParser {
  static final RegExp _clock = RegExp(
    r'^(\d{1,2}):(\d{2})\s*([ap])\.?\s*m\.?$',
  );
  static final RegExp _hours = RegExp(r'(\d+)\s*h');
  static final RegExp _minutes = RegExp(r'(\d+)\s*min');

  /// Minutos desde la medianoche: `"3:00 p.m."` -> `900`. `null` si el texto
  /// no es una hora.
  static int? minutesOfDay(String time) {
    final match = _clock.firstMatch(time.trim().toLowerCase());
    if (match == null) return null;
    final hour = int.parse(match[1]!) % 12 + (match[3] == 'p' ? 12 : 0);
    return hour * 60 + int.parse(match[2]!);
  }

  /// `"1 h 30 min"` -> 90 minutos; también `"45 min"` o `"2 h"`.
  /// [Duration.zero] si el texto no trae horas ni minutos (p. ej. "1 día").
  static Duration duration(String text) {
    final lower = text.toLowerCase();
    final hours = int.tryParse(_hours.firstMatch(lower)?[1] ?? '') ?? 0;
    final minutes = int.tryParse(_minutes.firstMatch(lower)?[1] ?? '') ?? 0;
    return Duration(hours: hours, minutes: minutes);
  }

  /// El día de [day] a la hora [time]; a medianoche si la hora no se
  /// entiende.
  static DateTime at(DateTime day, String time) => DateTime(
    day.year,
    day.month,
    day.day,
  ).add(Duration(minutes: minutesOfDay(time) ?? 0));
}
