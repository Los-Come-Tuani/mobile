import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../core/theme/map_style.dart';
import '../../../core/utils/logger.dart';

/// De dónde salen las calles del mapa: OpenFreeMap, con datos de
/// OpenStreetMap. Es gratis, sin API key y sin límite de uso.
///
/// La URL de los tiles cambia con cada actualización semanal del planeta, por
/// eso se lee del TileJSON la primera vez que se abre un mapa y se recuerda
/// mientras la app siga abierta.
class MapTilesRepository {
  MapTilesRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  static const String tileJsonUrl = 'https://tiles.openfreemap.org/planet';

  /// Zoom máximo con datos en OpenFreeMap; más cerca se agrandan esos tiles.
  static const int _defaultMaxZoom = 14;

  final Dio _dio;
  TileProviders? _providers;
  Future<TileProviders>? _pending;

  /// Siempre devuelve tiles: si no hay conexión, unos que sólo muestran lo
  /// que ya quedó en la caché del teléfono, y se reintenta en el próximo
  /// mapa que se abra.
  Future<TileProviders> load() {
    final providers = _providers;
    if (providers != null) return Future.value(providers);
    return _pending ??= _fetch().whenComplete(() => _pending = null);
  }

  Future<TileProviders> _fetch() async {
    try {
      final response = await _dio.get<Object?>(tileJsonUrl);
      final body = response.data;
      final data = (body is String ? jsonDecode(body) : body) as Map;
      final tiles = data['tiles'] as List<dynamic>? ?? const [];
      if (tiles.isEmpty) {
        throw const FormatException('El TileJSON no trae la URL de los tiles');
      }
      final providers = TileProviders({
        KPlanMapStyle.source: _OpenFreeMapTiles(
          _dio,
          urlTemplate: '${tiles.first}',
          maximumZoom: (data['maxzoom'] as num?)?.toInt() ?? _defaultMaxZoom,
        ),
      });
      _providers = providers;
      return providers;
    } catch (e) {
      log.w('MapTilesRepository.load: $e');
      return TileProviders({KPlanMapStyle.source: _CachedOnlyProvider()});
    }
  }
}

/// Los tiles de OpenFreeMap, pedidos por las conexiones de [Dio], que se
/// reutilizan de un tile al siguiente: `NetworkVectorTileProvider` abre una
/// nueva (con su saludo TLS) por cada tile, y desde Centroamérica cada una
/// suma casi un segundo.
class _OpenFreeMapTiles extends VectorTileProvider {
  _OpenFreeMapTiles(
    this._dio, {
    required this.urlTemplate,
    required this.maximumZoom,
  });

  final Dio _dio;
  final String urlTemplate;

  @override
  final int maximumZoom;

  @override
  int get minimumZoom => 1;

  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final url = urlTemplate
        .replaceAll('{z}', '${tile.z}')
        .replaceAll('{x}', '${tile.x}')
        .replaceAll('{y}', '${tile.y}');
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data ?? const <int>[];
      return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw ProviderException(
        message: 'No se pudo cargar el tile ${tile.key()}: ${e.message}',
        statusCode: status,
        retryable: status == null || status >= 500
            ? Retryable.retry
            : Retryable.none,
      );
    }
  }
}

/// Sin conexión: la caché de `VectorTileLayer` responde antes de llegar aquí,
/// y lo que no esté guardado queda como papel en blanco (un 404 no se cachea).
class _CachedOnlyProvider extends VectorTileProvider {
  @override
  Future<Uint8List> provide(TileIdentity tile) async => throw ProviderException(
    message: 'Sin conexión: el tile no está en la caché',
    statusCode: 404,
    retryable: Retryable.none,
  );

  @override
  int get maximumZoom => MapTilesRepository._defaultMaxZoom;

  @override
  int get minimumZoom => 1;

  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;
}
