// Pruebas contra un API de verdad: comprueban que la app y el contrato real coinciden
// (registro con código por correo, inicio de sesión, renovación de tokens, 2FA completo).
// No corren solas; hace falta un API local con el correo en consola:
//
//   KPLAN_API_URL=http://localhost:8080 KPLAN_MAIL_LOG=<archivo donde el API imprime los correos> flutter test test/integration
//
// Crean una cuenta de turista nueva en cada corrida: úsalas solo con una base de desarrollo.
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/security_repository.dart';
import 'package:k_plan_mobile/src/data/models/login_outcome.dart';
import 'package:logger/logger.dart';

class _NoGoogle implements GoogleIdTokenProvider {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

const _base32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/// El código de 6 dígitos que mostraría la app de autenticación (RFC 6238, SHA-1, 30 s).
String _totp(String secret) {
  final bits = secret
      .toUpperCase()
      .split('')
      .map((char) => _base32.indexOf(char).toRadixString(2).padLeft(5, '0'))
      .join();
  final key = Uint8List.fromList([
    for (var i = 0; i + 8 <= bits.length; i += 8)
      int.parse(bits.substring(i, i + 8), radix: 2),
  ]);
  final counter = ByteData(8)
    ..setInt64(0, DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 30);
  final hmac = Hmac(sha1, key).convert(counter.buffer.asUint8List()).bytes;
  final offset = hmac.last & 0x0f;
  final binary =
      ((hmac[offset] & 0x7f) << 24) |
      (hmac[offset + 1] << 16) |
      (hmac[offset + 2] << 8) |
      hmac[offset + 3];
  return (binary % 1000000).toString().padLeft(6, '0');
}

void main() {
  final apiUrl = Platform.environment['KPLAN_API_URL'];
  final mailLog = Platform.environment['KPLAN_MAIL_LOG'];
  final skip = (apiUrl == null || mailLog == null)
      ? 'Define KPLAN_API_URL y KPLAN_MAIL_LOG para probar contra un API real.'
      : null;

  setUpAll(() => Logger.level = Level.off);
  tearDown(() => ApiClient.configureForTest());

  /// El último código de 6 dígitos que el API imprimió en el log desde [offset].
  Future<String> codeSince(int offset) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final text = await File(mailLog!).readAsString();
      final tail = offset < text.length ? text.substring(offset) : '';
      final codes = RegExp(
        r'\b(\d{6})\b',
      ).allMatches(tail).map((m) => m.group(1)!).toList();
      if (codes.isNotEmpty) return codes.last;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    throw StateError('El API no imprimió ningún código.');
  }

  test(
    'crea una cuenta, renueva la sesión y completa el 2FA contra el API real',
    () async {
      final store = MemorySessionStore();
      ApiClient.configureForTest(baseUrl: apiUrl, store: store);
      final auth = AuthRepository(google: _NoGoogle());
      final security = SecurityRepository();

      final email = 'app-${DateTime.now().millisecondsSinceEpoch}@example.com';
      const password = 'Clave-Prueba-2026';

      // Registro con el código que llega al correo.
      final offset = (await File(mailLog!).readAsString()).length;
      expect(await auth.sendVerificationCode(email), isA<Ok<void>>());
      final code = await codeSince(offset);
      expect(await auth.verifyCode(email: email, code: code), isA<Ok<void>>());
      final registered = await auth.register(
        name: 'Ana María Prueba',
        email: email,
        password: password,
        code: code,
        birthDate: DateTime(1990, 5, 17),
        nationality: 'NI',
      );
      expect(
        registered,
        isA<Ok<dynamic>>(),
        reason: registered is Failure ? (registered as Failure).message : null,
      );
      expect(auth.currentUser?.email, email);
      expect(auth.currentUser?.firstName, 'Ana');
      expect(auth.currentUser?.lastName, 'María Prueba');
      expect(auth.currentUser?.nationality, 'NI');
      expect((await store.read())?.refresh, isNotEmpty);

      // El acceso vence: la app renueva con el refresh y sigue sin que se note.
      final tokens = (await store.read())!;
      await ApiClient.openSession(
        SessionTokens(access: 'vencido', refresh: tokens.refresh),
      );
      await auth.refreshUser();
      expect(auth.isLoggedIn, isTrue);
      expect((await store.read())?.access, isNot('vencido'));
      expect(
        (await store.read())?.refresh,
        isNot(tokens.refresh),
        reason: 'el refresh rota',
      );

      // 2FA: activar con un código real.
      final setup = ((await security.startSetup()) as Ok<TwoFactorSetup>).value;
      final codes =
          ((await security.confirm(_totp(setup.secret))) as Ok<List<String>>)
              .value;
      expect(codes, hasLength(10));
      final status = ((await security.status()) as Ok<TwoFactorStatus>).value;
      expect(status.enabled, isTrue);
      expect(status.recoveryCodes, 10);

      // Con 2FA, la contraseña sola ya no abre la sesión: llega el reto.
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      final login = await auth.login(email: email, password: password);
      final outcome = (login as Ok<LoginOutcome>).value;
      expect(outcome, isA<NeedsTwoFactor>());

      // Un código de recuperación sirve en lugar del de la app.
      final verified = await auth.verifyTwoFactor(
        challenge: (outcome as NeedsTwoFactor).challenge,
        code: codes.first,
      );
      expect(verified, isA<Ok<dynamic>>());
      expect(auth.currentUser?.twoFactorEnabled, isTrue);

      // Desactivar pide un código y la contraseña.
      expect(
        await security.disable(code: codes[1], password: password),
        isA<Ok<void>>(),
      );
      expect(
        ((await security.status()) as Ok<TwoFactorStatus>).value.enabled,
        isFalse,
      );

      // Cambiar la contraseña cierra la sesión.
      expect(
        await auth.changePassword(
          current: password,
          password: 'Otra-Clave-2026',
        ),
        isA<Ok<void>>(),
      );
      expect(auth.isLoggedIn, isFalse);
      final again = await auth.login(email: email, password: 'Otra-Clave-2026');
      expect((again as Ok<LoginOutcome>).value, isA<LoggedIn>());
      await auth.logout();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'una contraseña mala da el mismo mensaje y el API no revela si la cuenta existe',
    () async {
      ApiClient.configureForTest(baseUrl: apiUrl, store: MemorySessionStore());
      final auth = AuthRepository(google: _NoGoogle());

      final result = await auth.login(
        email: 'no-existe-${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'Clave-2026',
      );

      expect((result as Failure).message, 'Correo o contraseña incorrectos');
    },
    skip: skip,
  );
}
