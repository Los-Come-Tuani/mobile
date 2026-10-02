import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/map_camera.dart';

/// Lo que `KPlanMap` puede pedirle al mapa que el motor ya dibuja.
abstract interface class MapBase {
  /// Mueve la cámara a [target]; con [animate] la anima durante ese tiempo.
  Future<void> moveTo(MapCameraTarget target, {Duration? animate});

  /// Cambia las líneas del recorrido (un GeoJSON de `routeGeoJson`).
  Future<void> setRoute(String geoJson);

  /// Cambia el círculo de precisión del GPS (un GeoJSON de `accuracyGeoJson`).
  Future<void> setAccuracy(String geoJson);
}

/// Lo que `KPlanMap` le pide al motor para dibujar las calles.
class MapEngineConfig {
  const MapEngineConfig({
    required this.initialCamera,
    required this.interactive,
    required this.minZoom,
    required this.maxZoom,
    required this.onCameraChanged,
    required this.onReady,
    this.onTap,
  });

  /// Hacia dónde mira el mapa al crearse.
  final MapCameraTarget initialCamera;

  /// `false`: sin gestos (el mini mapa del home).
  final bool interactive;

  final double minZoom;
  final double maxZoom;

  /// La cámara se movió (por un gesto, una animación o un movimiento pedido).
  final ValueChanged<MapCameraTarget> onCameraChanged;

  /// El estilo ya cargó: desde aquí se pueden mandar datos al mapa.
  final ValueChanged<MapBase> onReady;

  /// Un toque sobre el mapa.
  final VoidCallback? onTap;
}

/// Quien dibuja las calles del mapa. Es la única pieza que conoce el motor
/// (MapLibre Native); el resto del mapa son widgets de Flutter encima.
///
/// `KPlanMap` lo busca con `context.read<MapEngine?>()`: sin motor (en las
/// pruebas) queda el papel con los pines.
abstract interface class MapEngine {
  Widget build(BuildContext context, MapEngineConfig config);
}

/// Lo que las pantallas le piden al mapa: dónde mira y hacia dónde moverlo.
///
/// Lo crea quien lo necesita (la pantalla del mapa) y se lo da a `KPlanMap`,
/// que lo mantiene al día.
class KPlanMapController {
  /// Lo que dura el vuelo de [flyTo].
  static const Duration flyDuration = Duration(milliseconds: 500);

  final ValueNotifier<MapCameraTarget?> _camera = ValueNotifier(null);
  MapBase? _base;
  MapCameraTarget? _pending;
  bool _isDisposed = false;

  /// El tamaño del mapa en pantalla. Lo pone `KPlanMap` al dibujarse.
  Size size = Size.zero;

  /// Hacia dónde mira el mapa ahora; `null` hasta que se dibuja por primera
  /// vez.
  MapCameraTarget? get camera => _camera.value;

  /// Avisa cada vez que la cámara se mueve.
  ValueListenable<MapCameraTarget?> get cameraListenable => _camera;

  /// Vuela hasta [center] y [zoom] con una animación corta.
  Future<void> flyTo(LatLng center, double zoom) => _move(
    MapCameraTarget(center: center, zoom: zoom),
    animate: flyDuration,
  );

  /// Salta a [center] y [zoom] sin animación.
  Future<void> moveTo(LatLng center, double zoom) =>
      _move(MapCameraTarget(center: center, zoom: zoom));

  Future<void> _move(MapCameraTarget target, {Duration? animate}) async {
    final base = _base;
    if (base == null) {
      // El motor todavía no está listo (o no hay): se anota el destino y se
      // aplica en cuanto el mapa exista.
      _pending = target;
      _camera.value = target;
      return;
    }
    await base.moveTo(target, animate: animate);
  }

  // ── Lo usa `KPlanMap` ───────────────────────────────────────────────────

  /// Un mapa nuevo empieza mirando hacia [camera].
  void reset(MapCameraTarget camera) {
    _pending = null;
    _camera.value = camera;
  }

  /// La cámara del mapa cambió.
  void report(MapCameraTarget camera) {
    if (!_isDisposed) _camera.value = camera;
  }

  /// El mapa ya puede recibir órdenes: se le manda el movimiento que quedó
  /// pendiente, si lo hubo.
  void attach(MapBase base) {
    _base = base;
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    unawaited(base.moveTo(pending));
  }

  /// El mapa se cerró. Si ya hay otro en su lugar, no se toca.
  void detach(MapBase base) {
    if (identical(_base, base)) _base = null;
  }

  void dispose() {
    _isDisposed = true;
    _camera.dispose();
  }
}
