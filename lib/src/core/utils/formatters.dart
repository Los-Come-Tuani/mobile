/// Formatos de presentación (moneda, fechas, horas) en un solo lugar.
abstract final class Formatters {
  static const List<String> _months = [
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
  ];

  static const List<String> _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// `250` -> `C$ 250`
  static String currency(num value) => 'C\$ ${value.toStringAsFixed(0)}';

  /// `DateTime(2026, 9, 26)` -> `Sábado 26 sep`
  static String weekdayDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]} ${dayAndMonth(date)}';

  /// `DateTime(2026, 11, 16)` -> `16 nov 2026`
  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// `DateTime(2026, 11, 16)` -> `16 nov`
  static String dayAndMonth(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  /// `TimeOfDay(8, 30)` -> `8:30 a.m.`
  static String time(int hour, int minute) {
    final suffix = hour < 12 ? 'a.m.' : 'p.m.';
    return '${_hourAndMinute(hour, minute)} $suffix';
  }

  /// `DateTime(…, 14, 5)` -> `2:05 p.m.`
  static String clock(DateTime value) => time(value.hour, value.minute);

  /// Minutos desde la medianoche: `900` -> `3:00 p.m.`
  static String minutesOfDay(int minutes) =>
      time(minutes ~/ 60 % 24, minutes % 60);

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
    if (value.inMinutes < 1) return 'menos de 1 min';
    final minutes = value.inMinutes.remainder(60);
    if (value.inHours == 0) return '$minutes min';
    return '${value.inHours} h ${minutes.toString().padLeft(2, '0')} min';
  }

  /// `1` -> `1 persona`, `4` -> `4 personas`.
  static String people(int count) =>
      '$count ${count == 1 ? 'persona' : 'personas'}';

  /// `2` -> `adulto x 2`, con plural correcto.
  static String groupLabel({required int adults, required int children}) {
    final parts = <String>[
      if (adults > 0) '${adults == 1 ? 'adulto' : 'adultos'} x $adults',
      if (children > 0) '${children == 1 ? 'niño' : 'niños'} x $children',
    ];
    return parts.isEmpty ? 'Sin personas' : parts.join(', ');
  }
}
