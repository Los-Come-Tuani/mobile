/// Lectura tolerante de los campos que manda el API: un dato que falta o llega
/// con otro tipo cae en un valor vacío en vez de romper la pantalla.
abstract final class ApiJson {
  static String str(Object? value) => value == null ? '' : '$value';

  static String? strOrNull(Object? value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  static int integer(Object? value) => switch (value) {
    final int v => v,
    final num v => v.round(),
    final String v => int.tryParse(v) ?? 0,
    _ => 0,
  };

  static int? integerOrNull(Object? value) =>
      value == null ? null : integer(value);

  static double? decimal(Object? value) => switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v),
    _ => null,
  };

  static Map<String, dynamic> map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : const {};

  /// Los objetos de una lista; lo que no es un objeto se ignora.
  static List<Map<String, dynamic>> rows(Object? value) => [
    for (final row in value is List ? value : const [])
      if (row is Map) row.cast<String, dynamic>(),
  ];

  /// `"2026-10-10"` o una fecha y hora ISO, en la zona del teléfono.
  static DateTime? date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    return parsed != null && parsed.isUtc ? parsed.toLocal() : parsed;
  }

  /// Solo el día de `"2026-10-10"`, sin hora.
  static DateTime day(Object? value) {
    final parsed = date(value) ?? DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// La URL de una imagen del API (`{ key, url }`); vacía si no hay.
  static String imageUrl(Object? value) => str(map(value)['url']);
}
