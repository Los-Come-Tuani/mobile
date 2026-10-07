// La postulación de guías y traductores contra un API de verdad: los documentos se suben
// al almacenamiento por la URL firmada y el API comprueba que llegaron. Hace falta lo mismo
// que en `api_contract_test.dart` y, además, el almacenamiento configurado en el API
// (`STORAGE_*`; en local sirve un S3 de prueba con CORS):
//
//   KPLAN_API_URL=http://localhost:8080 KPLAN_MAIL_LOG=<archivo donde el API imprime los correos> flutter test test/integration
//
// Crea una cuenta de guía nueva en cada corrida: úsalas solo con una base de desarrollo.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/google_sign_in_service.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/provider_api.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/auth_repository.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/guide_access_repository.dart';
import 'package:k_plan_mobile/src/data/models/guide_access_request.dart';
import 'package:k_plan_mobile/src/data/models/login_outcome.dart';
import 'package:k_plan_mobile/src/data/models/provider.dart';
import 'package:logger/logger.dart';

class _NoGoogle implements GoogleIdTokenProvider {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  final apiUrl = Platform.environment['KPLAN_API_URL'];
  final mailLog = Platform.environment['KPLAN_MAIL_LOG'];
  final skip = (apiUrl == null || mailLog == null)
      ? 'Define KPLAN_API_URL y KPLAN_MAIL_LOG para probar contra un API real.'
      : null;

  setUpAll(() => Logger.level = Level.off);
  setUp(() {
    // un PDF mínimo en lugar de un archivo del teléfono
    ProviderApi.readFile = (file) async =>
        Uint8List.fromList(utf8.encode('%PDF-1.4\n% ${file.name}\n%%EOF\n'));
  });
  tearDown(() {
    ProviderApi.reset();
    ApiClient.configureForTest();
  });

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

  List<DocumentDraft> documentsFor(List<CredentialType> types) {
    final today = DateTime.now();
    return [
      for (final type in types)
        DocumentDraft(
          typeCode: type.code,
          number: 'N-${type.code}',
          issuedOn: today.subtract(const Duration(days: 200)),
          expiresOn: type.requiresExpiry
              ? today.add(const Duration(days: 400))
              : null,
          file: GuideDocument(
            name: '${type.code}.pdf',
            uri: Uri.parse('file:///${type.code}.pdf'),
          ),
        ),
    ];
  }

  test(
    'se postula como guía con sus documentos y, mientras la revisan, solo ve su solicitud',
    () async {
      ApiClient.configureForTest(baseUrl: apiUrl, store: MemorySessionStore());
      final auth = AuthRepository(google: _NoGoogle());
      final access = GuideAccessRepository(auth);

      // Los catálogos salen del API: ciudades, idiomas y qué documentos se piden.
      final catalogs =
          ((await access.catalogs()) as Ok<ProviderCatalogs>).value;
      expect(catalogs.cities, isNotEmpty);
      expect(catalogs.languages.map((item) => item.code), contains('en'));
      final required = CredentialType.requiredFor(
        catalogs.credentialTypes,
        services: const [ProviderServices.guide],
        carriesTourists: false,
      );
      expect(
        required.map((type) => type.code),
        unorderedEquals(['cedula', 'record_policia', 'licencia_intur']),
      );
      final city = catalogs.cities.first;

      final email =
          'guia-app-${DateTime.now().millisecondsSinceEpoch}@example.com';
      const password = 'Clave-Prueba-2026';
      final offset = (await File(mailLog!).readAsString()).length;
      expect(await auth.sendVerificationCode(email), isA<Ok<void>>());
      final code = await codeSince(offset);
      expect(await auth.verifyCode(email: email, code: code), isA<Ok<void>>());

      final applied = await access.apply(
        ProviderApplicationDraft(
          fullName: 'Rosa Téllez Prueba',
          email: email,
          code: code,
          password: password,
          birthDate: DateTime(1988, 3, 2),
          nationality: 'NI',
          profile: ProviderProfileData(
            services: const [ProviderServices.guide],
            cityId: city.id,
            phone: '+505 8888 0000',
            presentation: 'Recorridos a pie por el centro.',
            languages: const [
              ProviderLanguage(code: 'es', level: 'native'),
              ProviderLanguage(code: 'en', level: 'advanced'),
            ],
          ),
          documents: documentsFor(required),
        ),
      );
      expect(
        applied.isOk,
        isTrue,
        reason: applied is Failure<void> ? applied.message : null,
      );

      // La cuenta queda dentro, pero mientras la revisan no es guía ni turista.
      expect(auth.currentUser?.email, email);
      expect(auth.currentUser?.provider?.status, ProviderStatus.inReview);
      expect(auth.currentUser?.provider?.services, [ProviderServices.guide]);
      expect(access.isLimitedToStatus, isTrue);
      expect(access.isApproved, isFalse);

      expect((await access.refresh()).isOk, isTrue);
      final application = access.application!;
      expect(application.status, ApplicationStatus.submitted);
      expect(application.isRenewal, isFalse);
      expect(application.canResubmit, isFalse);
      expect(application.missing, isEmpty);
      expect(application.profile.cityId, city.id);
      expect(application.profile.services, [ProviderServices.guide]);
      expect(
        application.documents.map((document) => document.typeCode),
        unorderedEquals(required.map((type) => type.code)),
      );
      for (final document in application.documents) {
        expect(document.status, DocumentStatus.uploaded);
        expect(document.review, isNull);
        expect(document.fileKey, isNotEmpty);
      }

      // Al volver a entrar sigue igual: la sesión dice en qué va.
      await auth.logout();
      expect(access.isLimitedToStatus, isFalse);
      final again = await auth.login(email: email, password: password);
      expect((again as Ok<LoginOutcome>).value, isA<LoggedIn>());
      expect(access.isLimitedToStatus, isTrue);
      await auth.logout();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'un código malo devuelve el mensaje del API y no deja la cuenta dentro',
    () async {
      ApiClient.configureForTest(baseUrl: apiUrl, store: MemorySessionStore());
      final auth = AuthRepository(google: _NoGoogle());
      final access = GuideAccessRepository(auth);
      final catalogs =
          ((await access.catalogs()) as Ok<ProviderCatalogs>).value;
      final required = CredentialType.requiredFor(
        catalogs.credentialTypes,
        services: const [ProviderServices.translator],
        carriesTourists: false,
      );

      final result = await access.apply(
        ProviderApplicationDraft(
          fullName: 'Prueba Sin Código',
          email:
              'sin-codigo-${DateTime.now().millisecondsSinceEpoch}@example.com',
          code: '000000',
          password: 'Clave-Prueba-2026',
          birthDate: DateTime(1990, 1, 1),
          nationality: 'NI',
          profile: const ProviderProfileData(
            services: [ProviderServices.translator],
            phone: '+505 8888 0000',
            languages: [ProviderLanguage(code: 'fr', level: 'advanced')],
          ),
          documents: documentsFor(required),
        ),
      );

      expect(result, isA<Failure<void>>());
      expect((result as Failure).message, isNotEmpty);
      expect(auth.isLoggedIn, isFalse);
    },
    skip: skip,
  );
}
