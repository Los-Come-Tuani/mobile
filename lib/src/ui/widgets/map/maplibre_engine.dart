import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart' as ml;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/map_style.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/map_camera.dart';
import 'map_engine.dart';

/// El motor del mapa de K'Plan: MapLibre Native, que dibuja las calles con la
/// GPU, reutiliza las conexiones y guarda los tiles en disco.
///
/// Las calles son de OpenFreeMap (datos de OpenStreetMap, gratis y sin API
/// key) con el estilo de [KPlanMapStyle]. Es la única pieza de la app que
/// conoce `package:maplibre`.
class MapLibreEngine implements MapEngine {
  const MapLibreEngine();

  /// Lo que MapLibre guarda de tiles en el teléfono: lo que ya se vio sigue
  /// ahí sin conexión.
  static const int tileCacheBytes = 150 * 1024 * 1024;

  @override
  Widget build(BuildContext context, MapEngineConfig config) =>
      _MapLibreBase(config: config);
}

class _MapLibreBase extends StatefulWidget {
  const _MapLibreBase({required this.config});

  final MapEngineConfig config;

  @override
  State<_MapLibreBase> createState() => _MapLibreBaseState();
}

class _MapLibreBaseState extends State<_MapLibreBase> {
  /// La caché se amplía una sola vez por sesión.
  static Future<void>? _tileCache;

  ml.MapController? _map;
  _NativeMapBase? _base;

  /// Se crea una vez por modo: MapLibre compara las opciones en cada cuadro.
  late ml.MapOptions _options = _optionsFor(widget.config);

  @override
  void initState() {
    super.initState();
    _tileCache ??= _raiseTileCache();
  }

  @override
  void didUpdateWidget(_MapLibreBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.interactive != widget.config.interactive) {
      _options = _optionsFor(widget.config);
    }
  }

  @override
  void dispose() {
    _base?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ml.MapLibreMap(
      options: _options,
      onMapCreated: (map) => _map = map,
      onStyleLoaded: _onStyleLoaded,
      onEvent: _onEvent,
    );
  }

  ml.MapOptions _optionsFor(MapEngineConfig config) => ml.MapOptions(
    // Un JSON y no una URL: el mapa no espera a la red para tener su papel.
    initStyle: KPlanMapStyle.json,
    initCenter: _geographic(config.initialCamera.center),
    initZoom: config.initialCamera.zoom,
    minZoom: config.minZoom,
    maxZoom: config.maxZoom,
    // Sin rotar ni inclinar: el norte siempre arriba, como los pines.
    gestures: config.interactive
        ? const ml.MapGestures.all(rotate: false, pitch: false)
        : const ml.MapGestures.none(),
    // El color del papel mientras Android crea la superficie del mapa.
    androidForegroundLoadColor: AppColors.mapLand,
  );

  void _onStyleLoaded(ml.StyleController style) {
    final map = _map;
    if (map == null || !mounted) return;
    _base?.dispose();
    final base = _NativeMapBase(
      map: map,
      style: style,
      onCameraChanged: (camera) => widget.config.onCameraChanged(camera),
    );
    _base = base;
    widget.config.onReady(base);
  }

  void _onEvent(ml.MapEvent event) {
    switch (event) {
      case ml.MapEventMoveCamera(:final camera):
        widget.config.onCameraChanged(_targetOf(camera));
      case ml.MapEventClick():
        widget.config.onTap?.call();
      default:
        break;
    }
  }

  static Future<void> _raiseTileCache() async {
    try {
      if (!ml.OfflineManager.isSupported) return;
      final manager = await ml.OfflineManager.createInstance();
      try {
        await manager.setMaximumAmbientCacheSize(
          bytes: MapLibreEngine.tileCacheBytes,
        );
      } finally {
        manager.dispose();
      }
    } catch (e) {
      log.w('MapLibreEngine: no se pudo ampliar la caché de tiles: $e');
    }
  }
}

/// Las órdenes de `KPlanMap` sobre el mapa nativo.
class _NativeMapBase implements MapBase {
  _NativeMapBase({
    required ml.MapController map,
    required ml.StyleController style,
    required this.onCameraChanged,
  }) : _map = map,
       _style = style;

  final ml.MapController _map;
  final ml.StyleController _style;
  final ValueChanged<MapCameraTarget> onCameraChanged;

  /// `false` cuando el mapa ya se cerró: MapLibre no admite órdenes después.
  bool _isAlive = true;

  void dispose() => _isAlive = false;

  @override
  Future<void> moveTo(MapCameraTarget target, {Duration? animate}) async {
    if (!_isAlive) return;
    final center = _geographic(target.center);
    try {
      if (animate == null) {
        await _map.moveCamera(center: center, zoom: target.zoom);
        // Con el zoom acotado por el mapa, la cámara puede no quedar donde se
        // pidió: se informa dónde quedó.
        if (_isAlive) onCameraChanged(_targetOf(_map.getCamera()));
      } else {
        await _map.animateCamera(
          center: center,
          zoom: target.zoom,
          nativeDuration: animate,
        );
      }
    } on Exception catch (e) {
      // Un movimiento nuevo (o el dedo) corta la animación en curso, y
      // MapLibre lo avisa como error: no es un fallo.
      if (!'$e'.contains(_cancelledMessage)) {
        log.w('MapLibreEngine.moveTo: $e');
      }
    }
  }

  /// Lo que dice el error de una animación cortada.
  static const String _cancelledMessage = 'cancelled';

  @override
  Future<void> setRoute(String geoJson) =>
      _update(KPlanMapStyle.routeSource, geoJson);

  @override
  Future<void> setAccuracy(String geoJson) =>
      _update(KPlanMapStyle.accuracySource, geoJson);

  Future<void> _update(String source, String geoJson) async {
    if (!_isAlive) return;
    try {
      await _style.updateGeoJsonSource(id: source, data: geoJson);
    } on Exception catch (e) {
      log.w('MapLibreEngine: no se pudo actualizar $source: $e');
    }
  }
}

ml.Geographic _geographic(LatLng point) =>
    ml.Geographic(lon: point.longitude, lat: point.latitude);

MapCameraTarget _targetOf(ml.MapCamera camera) => MapCameraTarget(
  center: LatLng(camera.center.lat, camera.center.lon),
  zoom: camera.zoom,
);
