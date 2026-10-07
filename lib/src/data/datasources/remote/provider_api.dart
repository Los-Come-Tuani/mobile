import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/guide_access_request.dart';
import '../../models/provider.dart';
import 'api_client.dart';
import 'api_routes.dart';

/// Las rutas de guías y traductores del API (`docs/prestadores.md` del repo del API).
///
/// Los archivos no pasan por el API: se pide una URL firmada (`POST /upload/`) y el
/// archivo se sube con un `PUT` directo al almacenamiento. Con las cabeceras que firmó
/// el API: el almacenamiento rechaza otro tipo u otro tamaño.
abstract final class ProviderApi {
  /// El `PUT` al almacenamiento: sin la sesión del API (la URL ya va firmada).
  static Dio storage = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 2),
    ),
  );

  /// Cómo se leen los archivos del teléfono; las pruebas lo cambian.
  static Future<Uint8List> Function(GuideDocument file) readFile = (file) =>
      File.fromUri(file.uri).readAsBytes();

  static const _types = {
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// El tipo MIME por la extensión del archivo.
  static String contentTypeOf(String name) {
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    return _types[extension] ?? 'application/octet-stream';
  }

  static Dio get _api => ApiClient.instance;

  // ── Catálogos ─────────────────────────────────────────────────────────────

  static Future<List<CatalogOption>> cities() async {
    final response = await _api.get<List<dynamic>>(ApiRoutes.cities);
    return [
      for (final item in response.data ?? const [])
        CatalogOption(
          id: '${(item as Map)['id']}',
          code: '${item['code']}',
          label: '${item['name']}',
        ),
    ];
  }

  static Future<List<CatalogOption>> languages() async {
    final response = await _api.get<List<dynamic>>(ApiRoutes.languages);
    return [
      for (final item in response.data ?? const [])
        CatalogOption(
          id: '${(item as Map)['id']}',
          code: '${item['code']}',
          label: '${item['label']}',
        ),
    ];
  }

  static Future<List<CredentialType>> credentialTypes() async {
    final response = await _api.get<List<dynamic>>(ApiRoutes.credentialTypes);
    return [
      for (final item in response.data ?? const [])
        CredentialType.fromApi((item as Map).cast<String, dynamic>()),
    ];
  }

  // ── Archivos ──────────────────────────────────────────────────────────────

  /// Sube [file] y devuelve la clave con que se manda después.
  static Future<String> upload(
    GuideDocument file, {
    required String kind,
  }) async {
    final bytes = await readFile(file);
    final signed = await _api.post<Map<String, dynamic>>(
      ApiRoutes.upload,
      data: {
        'kind': kind,
        'content_type': contentTypeOf(file.name),
        'size': bytes.length,
      },
    );
    final body = signed.data ?? const {};
    final headers = (body['headers'] as Map? ?? const {}).map(
      (key, value) => MapEntry('$key', '$value'),
    );
    await storage.put<void>(
      '${body['url']}',
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {...headers, Headers.contentLengthHeader: bytes.length},
      ),
    );
    return '${body['key']}';
  }

  static Future<Map<String, Object?>> _document(DocumentDraft draft) async => {
    'type': draft.typeCode,
    'number': draft.number.trim(),
    'issued_on': isoDate(draft.issuedOn),
    'expires_on': draft.expiresOn == null ? null : isoDate(draft.expiresOn!),
    'file_key': await upload(draft.file, kind: 'provider-document'),
  };

  static Future<List<Map<String, Object?>>> _documents(
    List<DocumentDraft> drafts,
  ) async => [for (final draft in drafts) await _document(draft)];

  // ── Postularse, corregir y renovar ────────────────────────────────────────

  /// Crea la cuenta, el perfil y la solicitud. Devuelve el cuerpo con los tokens de la
  /// sesión (`access`, `refresh`, `user`) y la solicitud (`application`).
  static Future<Map<String, dynamic>> apply(
    ProviderApplicationDraft draft,
  ) async {
    final names = splitName(draft.fullName);
    final response = await _api.post<Map<String, dynamic>>(
      ApiRoutes.providerApplication,
      data: {
        'email': draft.email.trim(),
        'code': draft.code,
        'password': draft.password,
        'first_name': names.first,
        'last_name': names.last,
        'birth_date': isoDate(draft.birthDate!),
        'nationality': draft.nationality,
        ...draft.profile.toApi(),
        'documents': await _documents(draft.documents),
      },
    );
    return response.data ?? const {};
  }

  static Future<ProviderApplication> mine() async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiRoutes.providerApplicationMine,
    );
    return ProviderApplication.fromApi(response.data ?? const {});
  }

  /// Corrige lo rechazado: los datos del perfil y solo los documentos que se suben otra vez.
  static Future<ProviderApplication> resubmit(
    ProviderProfileData profile,
    List<DocumentDraft> documents,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiRoutes.providerResubmit,
      data: {...profile.toApi(), 'documents': await _documents(documents)},
    );
    return ProviderApplication.fromApi(response.data ?? const {});
  }

  static Future<ProviderApplication> renew(
    List<DocumentDraft> documents,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiRoutes.providerRenewal,
      data: {'documents': await _documents(documents)},
    );
    return ProviderApplication.fromApi(response.data ?? const {});
  }

  // ── Perfil público ────────────────────────────────────────────────────────

  static Future<ProviderSelf> profile() async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiRoutes.providerProfile,
    );
    return ProviderSelf.fromApi(response.data ?? const {});
  }

  /// Cambia lo descriptivo: solo lo que llega. [photo] sube una foto nueva.
  static Future<ProviderSelf> updateProfile({
    String? presentation,
    String? phone,
    List<ProviderLanguage>? languages,
    GuideDocument? photo,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      ApiRoutes.providerProfile,
      data: {
        'presentation': ?presentation,
        'phone': ?phone,
        if (languages != null)
          'languages': [for (final language in languages) language.toApi()],
        if (photo != null)
          'photo_key': await upload(photo, kind: 'provider-photo'),
      },
    );
    return ProviderSelf.fromApi(response.data ?? const {});
  }

  // ── Piezas ────────────────────────────────────────────────────────────────

  static String isoDate(DateTime date) =>
      date.toIso8601String().split('T').first;

  static ({String first, String last}) splitName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return (first: parts.first, last: parts.skip(1).join(' '));
  }

  @visibleForTesting
  static void reset() {
    storage = Dio();
    readFile = (file) => File.fromUri(file.uri).readAsBytes();
  }
}
