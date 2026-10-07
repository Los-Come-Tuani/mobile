import 'dart:async';
import 'dart:convert';
import 'dart:math' show Point;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/map_style.dart';
import '../../../core/utils/logger.dart';
import 'map_camera.dart';
import 'map_icon_renderer.dart';
import 'map_pins.dart';
import 'map_scene.dart';
import 'map_surface.dart';
import 'route_line_style.dart';

/// El mapa con MapLibre: las calles, los tramos, los pines y el turista los
/// dibuja la GPU como capas del propio mapa, así que no se atrasan al
/// moverlo.
class NativeMap extends MapSurfaceWidget {
  const NativeMap({
    super.key,
    required super.map,
    required super.controller,
    required super.interactive,
    required super.compact,
    required super.padding,
    super.user,
    super.selectedId,
    super.onPointTap,
    super.onMapTap,
  });

  @override
  State<NativeMap> createState() => _NativeMapState();
}

abstract final class _Ids {
  static const accuracy = 'kplan-accuracy';
  static const route = 'kplan-route';
  static const pins = 'kplan-pins';
  static const user = 'kplan-user';

  static const pulseLayer = 'kplan-pulse';
  static const labelsLayer = 'kplan-labels';
  static const mainLabelsLayer = 'kplan-labels-main';

  static const sources = [accuracy, route, pins, user];
}

class _NativeMapState extends State<NativeMap>
    with SingleTickerProviderStateMixin
    implements MapSurface {
  /// Espacio entre la punta del pin y su nombre.
  static const double _labelGap = 3;

  /// Cada cuánto se mueve el halo: más seguido no se nota y ocupa el canal
  /// con el mapa nativo.
  static const Duration _pulseFrame = Duration(milliseconds: 40);

  static const Map<String, dynamic> _empty = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  ml.MapLibreMapController? _map;
  MapCamera? _initialCamera;
  Size _size = Size.zero;
  bool _styleReady = false;

  /// Las imágenes que ya tiene el estilo y lo último que recibió cada fuente.
  final _icons = <String>{};
  final _sent = <String, String>{};
  MapScene? _scene;
  Future<void> _sync = Future.value();
  bool _syncQueued = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: PinPulse.period,
  )..addListener(_onPulseTick);
  final _pulseClock = Stopwatch()..start();
  Duration _lastPulse = Duration.zero;
  bool _pulseBusy = false;

  @override
  Size get size => _size;

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
  }

  @override
  void didUpdateWidget(NativeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach(this);
      widget.controller.attach(this);
    }
    if (oldWidget.map != widget.map ||
        oldWidget.user != widget.user ||
        oldWidget.selectedId != widget.selectedId ||
        oldWidget.compact != widget.compact) {
      _scheduleSync();
    }
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    _map?.onFeatureTapped.remove(_onFeatureTapped);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Future<MapCamera?> camera() async {
    final position = await _map?.queryCameraPosition();
    if (position == null) return null;
    return MapCamera(_fromMl(position.target), position.zoom);
  }

  @override
  Future<void> flyTo(MapCamera target) async {
    await _map?.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(target: _toMl(target.center), zoom: target.zoom),
      ),
      duration: const Duration(milliseconds: 500),
    );
  }

  void _onMapCreated(ml.MapLibreMapController map) {
    _map = map..onFeatureTapped.add(_onFeatureTapped);
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    // Un estilo recién cargado no trae nuestras fuentes ni imágenes.
    _styleReady = false;
    _icons.clear();
    _sent.clear();
    try {
      await _addLayers(map);
      _styleReady = true;
      _scheduleSync();
    } catch (e) {
      log.w('NativeMap: no se pudieron agregar las capas: $e');
    }
  }

  void _onFeatureTapped(
    Point<double> point,
    ml.LatLng coordinates,
    String id,
    String layerId,
    ml.Annotation? annotation,
  ) {
    final tapped = _scene?.pins.where((pin) => pin.id == id).firstOrNull;
    final routePoint = tapped?.point;
    if (routePoint != null) {
      widget.onPointTap?.call(routePoint);
    } else {
      widget.onMapTap?.call();
    }
  }

  /// Las actualizaciones van en fila: cada una espera las imágenes que
  /// necesita y la siguiente no pisa a la anterior. Como cada una lee el
  /// widget de ese momento, basta con una en espera.
  void _scheduleSync() {
    if (!_styleReady || _syncQueued) return;
    _syncQueued = true;
    _sync = _sync
        .then((_) {
          _syncQueued = false;
          return _syncNow();
        })
        .catchError((Object e) {
          log.w('NativeMap: no se pudo actualizar el mapa: $e');
        });
  }

  Future<void> _syncNow() async {
    final map = _map;
    if (map == null || !mounted || !_styleReady) return;
    final view = View.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final scene = MapScene.of(
      widget.map,
      user: widget.user,
      selectedId: widget.selectedId,
      compact: widget.compact,
    );

    for (final icon in scene.icons) {
      if (_icons.contains(icon.name)) continue;
      final png = await MapIconRenderer.render(
        icon.widget,
        view: view,
        pixelRatio: pixelRatio,
      );
      if (!mounted || map != _map || !_styleReady) return;
      await map.addImage(icon.name, png);
      _icons.add(icon.name);
    }

    final data = {
      _Ids.accuracy: scene.accuracyGeoJson(),
      _Ids.route: scene.routeGeoJson(),
      _Ids.pins: scene.pinsGeoJson(),
      _Ids.user: scene.userGeoJson(),
    };
    for (final MapEntry(key: source, value: geojson) in data.entries) {
      final encoded = jsonEncode(geojson);
      if (_sent[source] == encoded) continue;
      await map.setGeoJsonSource(source, geojson);
      _sent[source] = encoded;
    }
    _scene = scene;

    final pulses = scene.pins.any((pin) => pin.pulse != null);
    if (pulses && !_pulse.isAnimating) {
      unawaited(_pulse.repeat());
    } else if (!pulses && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  void _onPulseTick() {
    final map = _map;
    final now = _pulseClock.elapsed;
    if (map == null || !_styleReady || _pulseBusy) return;
    if (now - _lastPulse < _pulseFrame) return;
    _lastPulse = now;
    _pulseBusy = true;
    unawaited(
      map
          .setLayerProperties(_Ids.pulseLayer, _pulseAt(_pulse.value))
          .then((_) {}, onError: (Object _) {})
          .whenComplete(() => _pulseBusy = false),
    );
  }

  /// `setLayerProperties` deja en su valor de fábrica lo que no se pase:
  /// cada cuadro lleva todas las propiedades del halo.
  static ml.CircleLayerProperties _pulseAt(double t) =>
      ml.CircleLayerProperties(
        circleRadius: PinPulse.radiusAt(t),
        circleOpacity: PinPulse.opacityAt(t),
        circleColor: const ['get', 'pulse'],
        circleTranslate: [0.0, -StopPin.headAbovePoint(emphasized: true)],
      );

  Future<void> _addLayers(ml.MapLibreMapController map) async {
    for (final source in _Ids.sources) {
      await map.addGeoJsonSource(source, _empty);
    }

    await map.addFillLayer(
      _Ids.accuracy,
      'kplan-accuracy-fill',
      ml.FillLayerProperties(
        fillColor: MapScene.hexOf(AppColors.userLocation),
        fillOpacity: 0.14,
      ),
      enableInteraction: false,
    );
    await map.addLineLayer(
      _Ids.accuracy,
      'kplan-accuracy-edge',
      ml.LineLayerProperties(
        lineColor: MapScene.hexOf(AppColors.userLocation),
        lineOpacity: 0.4,
        lineWidth: 1.0,
      ),
      enableInteraction: false,
    );

    for (final style in RouteLineStyle.drawOrder) {
      final line = RouteLineStyle.of(style);
      final filter = [
        '==',
        ['get', 'style'],
        style.name,
      ];
      if (line.bordered) {
        await map.addLineLayer(
          _Ids.route,
          'kplan-route-${style.name}-border',
          ml.LineLayerProperties(
            lineColor: MapScene.hexOf(RouteLineStyle.borderColor),
            lineWidth: line.width + 2 * RouteLineStyle.borderWidth,
            lineCap: 'round',
            lineJoin: 'round',
          ),
          filter: filter,
          enableInteraction: false,
        );
      }
      await map.addLineLayer(
        _Ids.route,
        'kplan-route-${style.name}',
        ml.LineLayerProperties(
          lineColor: MapScene.hexOf(line.color),
          lineWidth: line.width,
          lineCap: 'round',
          lineJoin: 'round',
          lineDasharray: line.dash,
        ),
        filter: filter,
        enableInteraction: false,
      );
    }

    await map.addCircleLayer(
      _Ids.pins,
      _Ids.pulseLayer,
      _pulseAt(0),
      filter: const ['has', 'pulse'],
      enableInteraction: false,
    );
    await map.addSymbolLayer(
      _Ids.pins,
      'kplan-pins',
      const ml.SymbolLayerProperties(
        iconImage: ['get', 'icon'],
        iconAnchor: 'bottom',
        iconOffset: [0.0, MapIconRenderer.margin],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        symbolSortKey: ['get', 'order'],
      ),
    );
    // De cerca, los nombres que no se encimen; primero los de las primeras
    // paradas.
    await map.addSymbolLayer(
      _Ids.pins,
      _Ids.labelsLayer,
      _labelProperties(allowOverlap: false),
      filter: const [
        'all',
        ['has', 'label'],
        [
          '!',
          ['get', 'always'],
        ],
      ],
      minzoom: MapZoom.labels,
    );
    await map.addSymbolLayer(
      _Ids.pins,
      _Ids.mainLabelsLayer,
      _labelProperties(allowOverlap: true),
      filter: const [
        'all',
        ['has', 'label'],
        ['get', 'always'],
      ],
    );
    await map.addSymbolLayer(
      _Ids.user,
      'kplan-user-marker',
      const ml.SymbolLayerProperties(
        iconImage: ['get', 'icon'],
        iconRotate: ['get', 'heading'],
        iconRotationAlignment: 'map',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
    );
  }

  static ml.SymbolLayerProperties _labelProperties({
    required bool allowOverlap,
  }) => ml.SymbolLayerProperties(
    iconImage: const ['get', 'label'],
    iconAnchor: 'top',
    iconOffset: const [0.0, _labelGap - MapIconRenderer.margin],
    iconAllowOverlap: allowOverlap,
    symbolSortKey: const [
      '*',
      -1,
      ['get', 'order'],
    ],
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        if (_size.isEmpty || !_size.isFinite) return const SizedBox.shrink();
        final initial = _initialCamera ??= fitRoute(
          widget.map,
          user: widget.user?.point,
          padding: widget.padding,
          size: _size,
        );
        return ml.MapLibreMap(
          styleString: KPlanMapStyle.json,
          initialCameraPosition: ml.CameraPosition(
            target: _toMl(initial.center),
            zoom: initial.zoom,
          ),
          minMaxZoomPreference: const ml.MinMaxZoomPreference(
            MapZoom.min,
            MapZoom.max,
          ),
          gestureRecognizers: widget.interactive
              ? {
                  Factory<OneSequenceGestureRecognizer>(
                    EagerGestureRecognizer.new,
                  ),
                }
              : null,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          scrollGesturesEnabled: widget.interactive,
          zoomGesturesEnabled: widget.interactive,
          dragEnabled: false,
          compassEnabled: false,
          attributionButtonColor: AppColors.hintText,
          annotationOrder: const [],
          foregroundLoadColor: AppColors.mapLand,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onMapClick: (_, _) => widget.onMapTap?.call(),
        );
      },
    );
  }

  static ml.LatLng _toMl(LatLng point) =>
      ml.LatLng(point.latitude, point.longitude);

  static LatLng _fromMl(ml.LatLng point) =>
      LatLng(point.latitude, point.longitude);
}
