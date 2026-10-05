/// Texto que reemplaza a un valor sensible en los logs.
const String redactedValue = '***';

/// Claves cuyo valor jamás debe llegar a un log: credenciales, tokens, códigos de un
/// solo uso y secretos del 2FA. Se comparan en minúsculas y sin `_` ni `-`.
const Set<String> _sensitiveKeys = {
  'password',
  'password1',
  'password2',
  'currentpassword',
  'newpassword',
  'token',
  'access',
  'refresh',
  'challenge',
  'code',
  'codes',
  'secret',
  'uri',
  'idtoken',
  'authorization',
  'cookie',
  'setcookie',
  'xcsrftoken',
};

/// Copia [data] reemplazando por [redactedValue] el valor de toda clave sensible, a
/// cualquier profundidad. Sirve para registrar cuerpos de petición y respuesta
/// durante el desarrollo sin filtrar contraseñas ni tokens.
Object? redactSensitive(Object? data) {
  return switch (data) {
    Map<dynamic, dynamic> map => {
      for (final entry in map.entries)
        entry.key: _isSensitive('${entry.key}')
            ? redactedValue
            : redactSensitive(entry.value),
    },
    List<dynamic> list => [for (final item in list) redactSensitive(item)],
    _ => data,
  };
}

bool _isSensitive(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
  return _sensitiveKeys.contains(normalized);
}
