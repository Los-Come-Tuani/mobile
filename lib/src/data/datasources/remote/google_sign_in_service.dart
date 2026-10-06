import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

/// Quien entrega el token de identidad de Google. Se separa para poder probar el resto del
/// inicio de sesión sin el selector de cuentas de Google.
abstract interface class GoogleIdTokenProvider {
  /// El token de identidad de la cuenta elegida, o `null` si la persona canceló.
  Future<String?> obtainIdToken();

  Future<void> signOut();
}

/// Inicio de sesión con Google (`google_sign_in` 7).
///
/// El API valida el token con las llaves públicas de Google y comprueba que fue emitido
/// para el Client ID **Web**; por eso la app lo pasa como `serverClientId`. Ninguno de
/// estos valores es secreto (ver `docs/google.md` del repo del API), pero tampoco se
/// versionan: vienen de `--dart-define-from-file=env/<entorno>.json`.
class GoogleSignInService implements GoogleIdTokenProvider {
  /// Client ID de tipo Web: el `aud` del token que valida el API.
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Client ID de tipo iOS. Android no lo necesita.
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// El botón solo aparece con un API real y con el Client ID Web configurado: sin ellos
  /// el inicio de sesión con Google no puede funcionar.
  static bool get isAvailable =>
      ApiClient.isConfigured && serverClientId.isNotEmpty;

  bool _initialized = false;

  @override
  Future<String?> obtainIdToken() async {
    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize(
        clientId: iosClientId.isEmpty ? null : iosClientId,
        serverClientId: serverClientId,
      );
      _initialized = true;
    }

    try {
      final account = await signIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}
