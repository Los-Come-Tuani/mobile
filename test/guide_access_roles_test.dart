import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/provider_api.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_access_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_access_request.dart';
import 'package:k_plan_mobile/src/data/models/provider.dart';
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

Map<String, dynamic> _provider(String status, [List<String>? services]) => {
  'id': 'p-1',
  'status': status,
  'services': services ?? ['guia'],
};

Map<String, dynamic> _document(String type, {String status = 'uploaded'}) => {
  'id': 'd-$type',
  'type': {'code': type, 'label': type},
  'number': '1',
  'issued_on': '2024-01-10',
  'expires_on': null,
  'file': {'key': 'provider-document/$type.jpg', 'url': null},
  'status': status,
  'review': null,
  'uploaded_at': '2026-10-07T15:00:00Z',
};

/// Lo que responde `GET /provider-application/mine/`.
Map<String, dynamic> _mine({
  String status = 'submitted',
  String provider = 'in_review',
}) => {
  'id': 'req-1',
  'procedure': 'application',
  'status': status,
  'submitted_at': '2026-10-07T15:00:00Z',
  'resolved_at': null,
  'resolution': null,
  'provider': {
    ..._provider(provider),
    'approved_at': provider == 'active' ? '2026-10-07T16:00:00Z' : null,
  },
  'profile': {
    'services': ['guia'],
    'city_id': null,
    'phone': '+505 8888 0000',
    'presentation': 'Leyendas.',
    'languages': [
      {'code': 'es', 'level': 'native'},
    ],
    'carries_tourists': false,
  },
  'documents': [_document('cedula'), _document('licencia_intur')],
  'missing': <Object>[],
};

void main() {
  // Los registros de red ensucian la salida de las pruebas.
  setUpAll(() => Logger.level = Level.off);

  tearDown(() {
    ApiClient.configureForTest();
    ProviderApi.reset();
  });

  group('el papel que da el API', () {
    test('viene en la sesión: guía, traductora o turista', () {
      final guide = User.fromApi(apiUser(role: 'guia'));
      final translator = User.fromApi(apiUser(role: 'traductor'));
      final tourist = User.fromApi(apiUser());

      expect(guide.isGuide, isTrue);
      expect(translator.isTranslator, isTrue);
      expect(tourist.providesServices, isFalse);
      expect(tourist.provider, isNull);
    });

    test('el perfil de prestador también', () {
      final user = User.fromApi({
        ...apiUser(role: null),
        'provider': _provider('in_review', ['guia', 'traductor']),
      });

      expect(user.provider?.status, ProviderStatus.inReview);
      expect(user.provider?.services, ['guia', 'traductor']);
    });
  });

  group('con el API real', () {
    /// Entra con una cuenta de [role] y perfil [provider] y devuelve su acceso de guía.
    Future<(AuthRepository, GuideAccessRepository, FakeApi)> signIn(
      String? role, {
      Map<String, dynamic>? provider,
    }) async {
      final api = FakeApi((request) {
        if (request.path.contains('logout')) return const FakeResponse(204);
        if (request.path == '/provider-application/mine/') {
          return FakeResponse(200, _mine());
        }
        return loginOk(
          user: {
            ...apiUser(role: role),
            'provider': provider,
          },
        );
      })..connect();
      final auth = AuthRepository(google: _NoGoogle());
      final access = GuideAccessRepository(auth);
      await auth.login(email: 'ana@example.com', password: 'Clave-2026');
      return (auth, access, api);
    }

    test('una turista no tiene acceso de guía', () async {
      final (_, access, _) = await signIn('turista');

      expect(access.status, GuideAccessStatus.none);
      expect(access.isLimitedToStatus, isFalse);
      access.dispose();
    });

    test('quien está en revisión solo ve su solicitud', () async {
      final (_, access, _) = await signIn(
        null,
        provider: _provider('in_review'),
      );

      expect(access.status, GuideAccessStatus.pending);
      expect(access.isLimitedToStatus, isTrue);

      await access.refresh();
      expect(access.application?.status, ApplicationStatus.submitted);
      expect(access.application?.documents.map((item) => item.typeCode), [
        'cedula',
        'licencia_intur',
      ]);
      access.dispose();
    });

    test('un guía aprobado entra a la app del guía', () async {
      final (_, access, _) = await signIn(
        'guia',
        provider: _provider('active'),
      );

      expect(access.isApproved, isTrue);
      expect(access.isSuspended, isFalse);
      access.dispose();
    });

    test('suspendido sigue entrando, para renovar', () async {
      final (_, access, _) = await signIn(
        'guia',
        provider: _provider('suspended'),
      );

      expect(access.isApproved, isTrue);
      expect(access.isSuspended, isTrue);
      access.dispose();
    });

    test('quien mira el acceso se entera al salir', () async {
      final (auth, access, _) = await signIn(
        'guia',
        provider: _provider('active'),
      );
      var changes = 0;
      access.addListener(() => changes++);

      await auth.logout();

      expect(changes, greaterThan(0));
      expect(access.isApproved, isFalse);
      access.dispose();
    });

    test(
      'postularse sube cada archivo firmado y deja la cuenta dentro',
      () async {
        final puts = <String>[];
        var uploads = 0;
        final api = FakeApi((request) {
          switch (request.path) {
            case '/upload/':
              uploads++;
              expect(request.body['kind'], 'provider-document');
              expect(request.body['content_type'], 'image/jpeg');
              return FakeResponse(201, {
                'key': 'provider-document/$uploads.jpg',
                'url': 'https://bucket.test/provider-document/$uploads.jpg',
                'method': 'PUT',
                'headers': {'Content-Type': 'image/jpeg'},
                'expires_in': 600,
                'max_bytes': 10485760,
              });
            case '/provider-application/':
              expect(request.body['code'], '123456');
              expect(request.body['first_name'], 'Ana');
              expect(request.body['services'], ['guia']);
              expect(
                (request.body['documents'] as List).map(
                  (item) => item['file_key'],
                ),
                ['provider-document/1.jpg', 'provider-document/2.jpg'],
              );
              return FakeResponse(201, {
                'access': 'access-1',
                'refresh': 'refresh-1',
                'user': {
                  ...apiUser(role: null),
                  'provider': _provider('in_review'),
                },
                'application': _mine(),
              });
          }
          return const FakeResponse(404);
        })..connect();
        final storage = FakeApi((request) {
          puts.add('${request.method} ${request.path}');
          return const FakeResponse(200);
        });
        ProviderApi.storage.httpClientAdapter = storage;
        ProviderApi.readFile = (_) async => Uint8List.fromList([1, 2, 3]);

        final auth = AuthRepository(google: _NoGoogle());
        final access = GuideAccessRepository(auth);
        final document = GuideDocument(name: 'cedula.jpg', uri: Uri.file('/x'));
        final result = await access.apply(
          ProviderApplicationDraft(
            fullName: 'Ana Gómez',
            email: 'ana@example.com',
            code: '123456',
            password: 'Clave-2026',
            birthDate: DateTime(1990, 5, 17),
            nationality: 'NI',
            profile: const ProviderProfileData(
              services: ['guia'],
              phone: '+505 8888 0000',
              languages: [ProviderLanguage(code: 'es', level: 'native')],
            ),
            documents: [
              DocumentDraft(
                typeCode: 'cedula',
                number: '1',
                issuedOn: DateTime(2024),
                expiresOn: DateTime(2034),
                file: document,
              ),
              DocumentDraft(
                typeCode: 'licencia_intur',
                number: '2',
                issuedOn: DateTime(2024),
                expiresOn: DateTime(2028),
                file: document,
              ),
            ],
          ),
        );

        expect(result, isA<Ok<void>>());
        expect(puts, hasLength(2));
        expect(puts.every((item) => item.startsWith('PUT ')), isTrue);
        expect(api.calls('/provider-application/'), 1);
        expect(auth.currentUser?.provider?.status, ProviderStatus.inReview);
        expect(access.isLimitedToStatus, isTrue);
        expect(access.application?.id, 'req-1');
        access.dispose();
      },
    );

    test('un error del API llega como mensaje', () async {
      FakeApi(
        (request) => apiError(
          400,
          'Revisa los campos marcados',
          fields: {'body.documents': 'Falta: Licencia o carné del INTUR.'},
        ),
      ).connect();
      final auth = AuthRepository(google: _NoGoogle());
      final access = GuideAccessRepository(auth);

      final result = await access.apply(
        ProviderApplicationDraft(
          fullName: 'Ana Gómez',
          email: 'ana@example.com',
          birthDate: DateTime(1990, 5, 17),
          profile: const ProviderProfileData(
            services: ['guia'],
            phone: '+505 8888 0000',
            languages: [],
          ),
          documents: const [],
        ),
      );

      expect(
        result,
        isA<Failure<void>>().having(
          (failure) => failure.message,
          'message',
          'Falta: Licencia o carné del INTUR.',
        ),
      );
      access.dispose();
    });
  });
}
