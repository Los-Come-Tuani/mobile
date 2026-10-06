import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Los dos tokens de la sesión: el de acceso (3 horas) y el que lo renueva (1 día, de
/// un solo uso).
class SessionTokens {
  const SessionTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Dónde se guardan los tokens entre sesiones de la app.
///
/// Nunca en `shared_preferences` ni en un archivo: quien tenga el teléfono desbloqueado y
/// un explorador de archivos los leería. Viven en el almacén seguro del sistema
/// (Keychain en iOS, Keystore en Android).
abstract interface class SessionStore {
  Future<SessionTokens?> read();

  Future<void> write(SessionTokens tokens);

  Future<void> clear();
}

/// El almacén seguro del dispositivo.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'kplan.session.access';
  static const _refreshKey = 'kplan.session.refresh';

  final FlutterSecureStorage _storage;

  @override
  Future<SessionTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return SessionTokens(access: access, refresh: refresh);
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.access);
    await _storage.write(key: _refreshKey, value: tokens.refresh);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Sin disco: para las pruebas y para el modo demo, donde no hay sesión de verdad.
class MemorySessionStore implements SessionStore {
  SessionTokens? _tokens;

  @override
  Future<SessionTokens?> read() async => _tokens;

  @override
  Future<void> write(SessionTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
