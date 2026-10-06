import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_access_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_access_request.dart';
import 'package:k_plan_mobile/src/data/models/user.dart';
import 'package:logger/logger.dart';

import 'support/fake_api.dart';

/// Sin Google: estas pruebas entran con correo y contraseña.
class _NoGoogle implements GoogleIdTokenProvider {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

GuideDocument _file(String name) =>
    GuideDocument(name: name, uri: Uri.file('/tmp/$name'));

GuideAccessRequest _request() => GuideAccessRequest(
  fullName: 'Ana Gómez',
  phone: '+505 8888 0000',
  contactEmail: 'ana@example.com',
  coverage: GuideCoverage.national,
  languages: const ['Español'],
  experience: '3 años en recorridos culturales',
  identityDocument: _file('identidad.pdf'),
  inturCredential: _file('credencial-intur.pdf'),
);

void main() {
  // Los registros de red ensucian la salida de las pruebas.
  setUpAll(() => Logger.level = Level.off);

  tearDown(() => ApiClient.configureForTest());

  group('el rol que da el API', () {
    test('viene en la sesión: guía, traductora o turista', () {
      final guide = User.fromApi(apiUser(role: 'guia'));
      final translator = User.fromApi(apiUser(role: 'traductor'));
      final tourist = User.fromApi(apiUser());

      expect(guide.isGuide, isTrue);
      expect(guide.providesServices, isTrue);
      expect(translator.isTranslator, isTrue);
      expect(translator.isGuide, isFalse);
      expect(translator.providesServices, isTrue);
      expect(tourist.role, 'turista');
      expect(tourist.providesServices, isFalse);
    });

    test('una cuenta sin rol no ofrece servicios', () {
      expect(User.fromApi(apiUser(role: null)).providesServices, isFalse);
    });
  });

  group('con el API real', () {
    /// Entra con una cuenta de [role] y devuelve el acceso de guía de esa sesión.
    Future<(AuthRepository, GuideAccessRepository)> signIn(String? role) async {
      FakeApi((request) {
        if (request.path.contains('logout')) return const FakeResponse(204);
        return loginOk(user: apiUser(role: role));
      }).connect();
      final auth = AuthRepository(google: _NoGoogle());
      final access = GuideAccessRepository(auth);
      await auth.login(email: 'ana@example.com', password: 'Clave-2026');
      return (auth, access);
    }

    test('una guía que habilitó el equipo entra a la app del guía', () async {
      final (_, access) = await signIn('guia');

      expect(access.status, GuideAccessStatus.approved);
      expect(access.isApproved, isTrue);
      access.dispose();
    });

    test('una traductora también', () async {
      final (_, access) = await signIn('traductor');

      expect(access.isApproved, isTrue);
      access.dispose();
    });

    test(
      'una turista no, y desde la app todavía no se puede postular',
      () async {
        final (_, access) = await signIn('turista');

        expect(access.status, GuideAccessStatus.none);
        expect(access.canApplyInApp, isFalse);

        // Ni se manda ni se aprueba sola, como en la demo.
        final result = await access.submit(_request());
        expect(result, isA<Failure<void>>());
        expect(access.status, GuideAccessStatus.none);
        access.dispose();
      },
    );

    test('quien mira el acceso se entera al entrar y al salir', () async {
      final (auth, access) = await signIn('guia');
      var changes = 0;
      access.addListener(() => changes++);

      await auth.logout();

      expect(changes, greaterThan(0));
      expect(access.isApproved, isFalse);
      access.dispose();
    });
  });

  group('en el modo demo', () {
    test('la postulación se puede hacer desde la app', () {
      final access = GuideAccessRepository(AuthRepository(google: _NoGoogle()));

      expect(access.canApplyInApp, isTrue);
      expect(access.status, GuideAccessStatus.none);
      access.dispose();
    });
  });
}
