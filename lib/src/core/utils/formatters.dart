import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import 'time_parser.dart';

/// Formatos de presentación (moneda, fechas, horas) en un solo lugar.
///
/// Todos leen el idioma de ahora ([AppStrings]) en el momento de llamarse, así
/// que nunca guardes su resultado en un campo `static` o `const`.
abstract final class Formatters {
  /// Los nombres del calendario de cada idioma. Son datos del calendario, no
  /// textos de la interfaz: por eso viven aquí y no en los ARB.
  static const Map<AppLanguage, List<String>> _monthNames = {
    AppLanguage.es: [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ],
    AppLanguage.en: [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
  };

  static const Map<AppLanguage, List<String>> _weekdayNames = {
    AppLanguage.es: [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ],
    AppLanguage.en: [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
  };

  static const Map<AppLanguage, List<String>> _shortWeekdayNames = {
    AppLanguage.es: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
    AppLanguage.en: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  };

  static String _month(DateTime date) =>
      _monthNames[AppStrings.language]![date.month - 1];

  static String _weekday(DateTime date) =>
      _weekdayNames[AppStrings.language]![date.weekday - 1];

  static String _shortWeekday(DateTime date) =>
      _shortWeekdayNames[AppStrings.language]![date.weekday - 1];

  /// `250` -> `C$ 250`
  static String currency(num value) => 'C\$ ${value.toStringAsFixed(0)}';

  /// Cambia los espacios por espacios que no parten el renglón, para que
  /// `C$ 560` o `3 personas` nunca queden cortados.
  static String keepTogether(String text) => text.replaceAll(' ', '\u00A0');

  /// Datos cortos separados por ` · `; si no caben, el renglón se parte
  /// sólo entre dato y dato: `Vie 2 oct · 4:00 p.m. · 3 personas`.
  static String facts(Iterable<String> parts) =>
      parts.map(keepTogether).join(' · ');

  /// `DateTime(2026, 10, 3)` -> `Sáb 3 oct` (en inglés, `Sat, Oct 3`).
  static String compactDate(DateTime date) => AppStrings.current
      .formatCompactDate(_shortWeekday(date), dayAndMonth(date));

  /// "Hoy", "Mañana", "Ayer" o, si no, `Sáb 3 oct`.
  static String relativeDay(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(reference.year, reference.month, reference.day))
        .inDays;
    final l10n = AppStrings.current;
    return switch (days) {
      0 => l10n.formatToday,
      1 => l10n.formatTomorrow,
      -1 => l10n.formatYesterday,
      _ => compactDate(date),
    };
  }

  /// `hace 5 min`, `hace 2 h`, `hace 3 días` (en inglés, `5 min ago`).
  static String timeAgo(DateTime value, {DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(value);
    final l10n = AppStrings.current;
    if (elapsed.inMinutes < 1) return l10n.formatNow;
    if (elapsed.inHours < 1) return l10n.formatMinutesAgo(elapsed.inMinutes);
    if (elapsed.inDays < 1) return l10n.formatHoursAgo(elapsed.inHours);
    return l10n.formatDaysAgo(elapsed.inDays);
  }

  /// `DateTime(2026, 9, 26)` -> `Sábado 26 sep` (en inglés, `Saturday, Sep 26`).
  static String weekdayDate(DateTime date) =>
      AppStrings.current.formatWeekdayDate(_weekday(date), dayAndMonth(date));

  /// `DateTime(2026, 11, 16)` -> `16 nov 2026` (en inglés, `Nov 16, 2026`).
  static String shortDate(DateTime date) =>
      AppStrings.current.formatShortDate(date.day, _month(date), date.year);

  /// `DateTime(2026, 11, 16)` -> `16 nov` (en inglés, `Nov 16`).
  static String dayAndMonth(DateTime date) =>
      AppStrings.current.formatDayAndMonth(date.day, _month(date));

  /// `TimeOfDay(8, 30)` -> `8:30 a.m.` (en inglés, `8:30 AM`).
  static String time(int hour, int minute) {
    final l10n = AppStrings.current;
    final suffix = hour < 12 ? l10n.formatAm : l10n.formatPm;
    return '${_hourAndMinute(hour, minute)} $suffix';
  }

  /// `DateTime(…, 14, 5)` -> `2:05 p.m.`
  static String clock(DateTime value) => time(value.hour, value.minute);

  /// Minutos desde la medianoche: `900` -> `3:00 p.m.`
  static String minutesOfDay(int minutes) =>
      time(minutes ~/ 60 % 24, minutes % 60);

  /// Una hora como la guardan los datos de la app, igual en todos los idiomas:
  /// `510` -> `8:30 a.m.`. Es lo que lee [TimeParser.minutesOfDay].
  static String dataTime(int minutes) {
    final hour = minutes ~/ 60 % 24;
    return '${_hourAndMinute(hour, minutes % 60)} ${hour < 12 ? 'a.m.' : 'p.m.'}';
  }

  /// Una hora como la recibe el API: `510` -> `08:30`.
  static String time24h(int minutes) {
    final hour = (minutes ~/ 60 % 24).toString().padLeft(2, '0');
    return '$hour:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  /// Una hora que llega como texto en los datos (`"3:00 p.m."`) mostrada en
  /// el formato del idioma de ahora: `3:00 p.m.` o `3:00 PM`. Un texto que no
  /// es una hora se devuelve igual.
  ///
  /// Úsalo solo para mostrar: el texto de los datos también sirve de clave,
  /// y esa no se toca.
  static String timeText(String raw) {
    final minutes = TimeParser.minutesOfDay(raw);
    return minutes == null ? raw : minutesOfDay(minutes);
  }

  /// Franja horaria. Si las dos horas caen del mismo lado del mediodía, el
  /// sufijo va una sola vez: `8:30 – 9:00 a.m.`, pero
  /// `11:40 a.m. – 12:10 p.m.`.
  static String timeRange(DateTime from, DateTime to) {
    final sameDay =
        from.year == to.year && from.month == to.month && from.day == to.day;
    final sameHalf = sameDay && (from.hour < 12) == (to.hour < 12);
    if (!sameHalf) return '${clock(from)} – ${clock(to)}';
    return '${_hourAndMinute(from.hour, from.minute)} – ${clock(to)}';
  }

  /// `Duration(minutes: 260)` -> `4 h 20 min`; también `45 min` o `3 h`.
  static String duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }

  /// `0.8` -> `800 m`, `2.24` -> `2.2 km`.
  static String distance(double km) =>
      km < 1 ? '${(km * 100).round() * 10} m' : '${km.toStringAsFixed(1)} km';

  static String _hourAndMinute(int hour, int minute) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')}';
  }

  /// Tiempo restante: `23 h 05 min`, `45 min` o `menos de 1 min`.
  static String remaining(Duration value) {
    if (value.inMinutes < 1) return AppStrings.current.formatLessThanOneMinute;
    final minutes = value.inMinutes.remainder(60);
    if (value.inHours == 0) return '$minutes min';
    return '${value.inHours} h ${minutes.toString().padLeft(2, '0')} min';
  }

  /// `1` -> `1 persona`, `4` -> `4 personas` (en inglés, `1 person`,
  /// `4 people`).
  static String people(int count) => AppStrings.current.formatPeople(count);

  /// `2` -> `adultos x 2`, con plural correcto (en inglés, `2 adults`).
  static String groupLabel({required int adults, required int children}) {
    final l10n = AppStrings.current;
    final parts = <String>[
      if (adults > 0) l10n.formatAdults(adults),
      if (children > 0) l10n.formatChildren(children),
    ];
    return parts.isEmpty ? l10n.formatNoPeople : parts.join(', ');
  }
}
