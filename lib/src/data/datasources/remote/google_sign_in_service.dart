import 'package:flutter/foundation.dart';
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
/// estos valores es secreto (ver `docs/google.md` del repo del API): vienen de
/// `--dart-define-from-file=env/<entorno>.json`, y un build release sin archivo usa
/// [releaseServerClientId].
class GoogleSignInService implements GoogleIdTokenProvider {
  /// El Client ID Web de un build release sin `GOOGLE_SERVER_CLIENT_ID`: el de desarrollo,
  /// que el API de [ApiClient.releaseBaseUrl] debe tener en `GOOGLE_OAUTH_CLIENT_IDS`.
  static const String releaseServerClientId =
      '552338673379-b5qoepfp6ogt04gnuidonrl72itheg4s.apps.googleusercontent.com';

  /// Client ID de tipo Web: el `aud` del token que valida el API.
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: kReleaseMode ? releaseServerClientId : '',
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
    } finally {
      // Si el teléfono guarda la cuenta elegida, el siguiente intento (por ejemplo, tras
      // un error del API) entra solo con ella y no muestra el selector de cuentas.
      await signIn.signOut().catchError((_) {});
    }
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}
