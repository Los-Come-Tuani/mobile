import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:k_plan_mobile/src/data/datasources/local/session_store.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';

/// Lo que la app mandó al API en una petición.
class SentRequest {
  SentRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.data,
    this.query = const {},
  });

  final String method;
  final String path;
  final Map<String, dynamic> headers;
  final Object? data;

  /// Los parámetros de la URL (`?page=2&page_size=100`).
  final Map<String, dynamic> query;

  /// El cuerpo JSON como mapa (las peticiones de la app siempre mandan mapas).
  Map<String, dynamic> get body => (data as Map).cast<String, dynamic>();

  String? get authorization => headers['Authorization'] as String?;
}

/// La respuesta que el API falso da a una petición.
class FakeResponse {
  const FakeResponse(this.status, [this.body, this.headers = const {}]);

  final int status;
  final Object? body;
  final Map<String, List<String>> headers;
}

/// Un API falso para probar el cliente y los repositorios sin red: anota lo que llega y
/// responde con lo que decida [responder].
class FakeApi implements HttpClientAdapter {
  FakeApi(this.responder);

  final FutureOr<FakeResponse> Function(SentRequest request) responder;
  final List<SentRequest> requests = [];

  /// Cuántas veces se llamó a [path].
  int calls(String path) =>
      requests.where((request) => request.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = SentRequest(
      method: options.method,
      path: options.path,
      headers: Map.of(options.headers),
      data: options.data,
      query: Map.of(options.queryParameters),
    );
    requests.add(request);

    final response = await responder(request);
    final body = response.body == null ? '' : jsonEncode(response.body);
    return ResponseBody.fromString(
      body,
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...response.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}

  /// Conecta [ApiClient] a este API falso, con los tokens solo en memoria.
  void connect({SessionStore? store}) {
    ApiClient.configureForTest(
      baseUrl: 'http://api.test',
      adapter: this,
      store: store ?? MemorySessionStore(),
    );
  }
}

/// El usuario de la sesión tal como lo entrega el API.
Map<String, dynamic> apiUser({
  String id = 'user-1',
  String email = 'ana@example.com',
  String name = 'Ana Gómez',
  bool twoFactor = false,
  String? role = 'turista',
}) => {
  'id': id,
  'email': email,
  'first_name': name.split(' ').first,
  'last_name': name.split(' ').skip(1).join(' '),
  'name': name,
  'username': null,
  'birth_date': '1990-05-17',
  'nationality': 'NI',
  'status': 'active',
  'verified': true,
  'role': role,
  'groups': <Object>[],
  'permissions': <String>[],
  'organization_id': null,
  'two_factor': {'enabled': twoFactor, 'required': false},
  'created_at': '2026-10-05T21:40:00Z',
};

/// La respuesta de un inicio de sesión que salió bien.
FakeResponse loginOk({
  String access = 'access-1',
  String refresh = 'refresh-1',
  Map<String, dynamic>? user,
}) => FakeResponse(200, {
  'access': access,
  'refresh': refresh,
  'user': user ?? apiUser(),
});

/// El error que manda el API: `{ "detail": ..., "field_errors": ... }`.
FakeResponse apiError(
  int status,
  String detail, {
  Map<String, String>? fields,
  Map<String, List<String>> headers = const {},
}) =>
    FakeResponse(status, {'detail': detail, 'field_errors': ?fields}, headers);
