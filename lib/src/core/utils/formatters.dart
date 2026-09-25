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
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
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
