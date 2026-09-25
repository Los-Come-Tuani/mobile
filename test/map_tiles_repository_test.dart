import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/map_style.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/map_tiles_repository.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Responde como OpenFreeMap, sin salir a la red.
class _FakeOpenFreeMap implements HttpClientAdapter {
  _FakeOpenFreeMap({this.isOnline = true});

  final bool isOnline;
  final requests = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    if (!isOnline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Sin conexión',
      );
    }
    if (options.uri.path == '/planet') {
      return ResponseBody.fromString(
        jsonEncode({
          'tiles': ['https://tiles.openfreemap.org/planet/v1/{z}/{x}/{y}.pbf'],
          'maxzoom': 14,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.uri.path == '/planet/v1/14/4231/7612.pbf') {
      return ResponseBody.fromBytes([1, 2, 3], 200);
    }
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}

TypeMatcher<ProviderException> _providerError(int statusCode) =>
    isA<ProviderException>().having(
      (e) => e.statusCode,
      'statusCode',
      statusCode,
    );

void main() {
  test('lee la URL de los tiles del TileJSON y los pide por Dio', () async {
    final server = _FakeOpenFreeMap();
    final repository = MapTilesRepository(
      dio: Dio()..httpClientAdapter = server,
    );

    final tiles = (await repository.load()).get(KPlanMapStyle.source);

    expect(tiles.maximumZoom, 14);
    expect(await tiles.provide(TileIdentity(14, 4231, 7612)), [1, 2, 3]);
    expect(
      server.requests.last.toString(),
      'https://tiles.openfreemap.org/planet/v1/14/4231/7612.pbf',
    );

    // El TileJSON se lee una sola vez.
    await repository.load();
    expect(server.requests.where((uri) => uri.path == '/planet'), hasLength(1));
  });

  test('un tile que no existe llega como 404 y no se reintenta', () async {
    final repository = MapTilesRepository(
      dio: Dio()..httpClientAdapter = _FakeOpenFreeMap(),
    );
    final tiles = (await repository.load()).get(KPlanMapStyle.source);

    await expectLater(
      tiles.provide(TileIdentity(14, 1, 1)),
      throwsA(
        _providerError(
          404,
        ).having((e) => e.retryable, 'retryable', Retryable.none),
      ),
    );
  });

  test(
    'sin conexión sólo queda la caché y se reintenta en el próximo mapa',
    () async {
      final server = _FakeOpenFreeMap(isOnline: false);
      final repository = MapTilesRepository(
        dio: Dio()..httpClientAdapter = server,
      );

      final tiles = (await repository.load()).get(KPlanMapStyle.source);
      await expectLater(
        tiles.provide(TileIdentity(14, 4231, 7612)),
        throwsA(_providerError(404)),
      );

      await repository.load();
      expect(server.requests, hasLength(2));
    },
  );
}
