import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/map_camera.dart';
import '../../../core/utils/route_map_builder.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/trip_progress.dart';
import '../../../data/models/user_location.dart';
import 'map_engine.dart';
import 'map_marker_layer.dart';
import 'map_pins.dart';
import 'paper_texture.dart';
import 'route_geojson.dart';

/// El mapa de K'Plan: las calles de OpenFreeMap con la paleta de la app, el
/// papel encima y el recorrido con sus pines.
///
/// Las calles, el círculo de precisión y las líneas del recorrido las dibuja el
/// motor del mapa ([MapEngine], MapLibre Native con la GPU). El papel, los
/// pines y el marcador del usuario son widgets de Flutter encima, colocados con
/// la cámara que el motor va informando.
///
/// Mientras cargan las calles (o sin conexión) queda el papel con los pines; las
/// líneas aparecen en cuanto carga el estilo, que no espera a la red.
class KPlanMap extends StatefulWidget {
  const KPlanMap({
    super.key,
    required this.map,
    this.user,
    this.controller,
    this.interactive = true,
    this.compact = false,
    this.padding = const EdgeInsets.all(40),
    this.selectedId,
    this.onPointTap,
    this.onMapTap,
    this.showAttribution = true,
  });

  final RouteMap map;
  final UserLocation? user;

  /// Para mover la cámara y saber dónde está. No puede cambiar mientras el
  /// mapa exista.
  final KPlanMapController? controller;

  /// `false` en el home: sin gestos, y se vuelve a encuadrar solo cuando
  /// cambia el recorrido o la ubicación.
  final bool interactive;

  /// Mapa chico: sólo la parada destacada lleva su nombre.
  final bool compact;

  /// Margen al encuadrar, para que los pines no queden bajo los controles.
  final EdgeInsets padding;

  /// La parada elegida en la pantalla del mapa; se destaca como la siguiente.
  final String? selectedId;
  final ValueChanged<RouteMapPoint>? onPointTap;

  /// Un toque sobre el mapa, fuera de los pines.
  final VoidCallback? onMapTap;

  /// La pantalla del mapa la pone ella misma, encima de su tarjeta.
  final bool showAttribution;

  /// Los límites de zoom del mapa, con la escala de MapLibre (1 menos que la de
  /// flutter_map a la misma distancia).
  static const double minZoom = 3;
  static const double maxZoom = 17.5;

  /// Más cerca que esto, un solo lugar llenaría la pantalla.
  static const double fitMaxZoom = 15.5;

  /// El encuadre del recorrido en un mapa de [size]: en un viaje, el turista y
  /// lo que falta.
  static MapCameraTarget cameraFor(
    RouteMap map, {
    required Size size,
    LatLng? user,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return MapProjection.fit(
      RouteMapBuilder.focus(map, user: user),
      size: size,
      padding: padding,
      minZoom: minZoom,
      maxZoom: fitMaxZoom,
    );
  }

  @override
  State<KPlanMap> createState() => _KPlanMapState();
}

class _KPlanMapState extends State<KPlanMap> {
  KPlanMapController? _ownController;
  MapEngine? _engine;
  MapBase? _base;

  /// Hacia dónde mira el mapa al crearse: se calcula con el tamaño real.
  MapCameraTarget? _initialCamera;

  /// Lo último que se mandó al mapa, para no repetir lo que no cambió.
  String? _routeSent;
  String? _accuracySent;

  KPlanMapController get _controller =>
      widget.controller ?? (_ownController ??= KPlanMapController());

  @override
  void initState() {
    super.initState();
    _engine = context.read<MapEngine?>();
  }

  @override
  void didUpdateWidget(KPlanMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      oldWidget.controller == widget.controller,
      'El controlador de KPlanMap no puede cambiar.',
    );
    _sendData();
    if (widget.interactive || _base == null) return;
    final before = RouteMapBuilder.focus(
      oldWidget.map,
      user: oldWidget.user?.point,
    );
    final after = RouteMapBuilder.focus(widget.map, user: widget.user?.point);
    if (!listEquals(before, after)) _fitCamera();
  }

  @override
  void dispose() {
    final base = _base;
    if (base != null) (widget.controller ?? _ownController)?.detach(base);
    _ownController?.dispose();
    super.dispose();
  }

  MapCameraTarget _startAt(Size size) {
    final camera = KPlanMap.cameraFor(
      widget.map,
      size: size,
      user: widget.user?.point,
      padding: widget.padding,
    );
    _controller.reset(camera);
    return camera;
  }

  /// El estilo cargó: ya se pueden mandar datos.
  void _onReady(MapBase base) {
    if (!mounted) return;
    _base = base;
    _controller.attach(base);
    _routeSent = null;
    _accuracySent = null;
    _sendData();
    // Lo que pasó mientras el mapa arrancaba.
    if (!widget.interactive) _fitCamera();
  }

  /// Manda al mapa el recorrido y la precisión, si cambiaron.
  void _sendData() {
    final base = _base;
    if (base == null) return;

    final route = routeGeoJson(
      RouteMapBuilder.segments(widget.map, user: widget.user?.point),
    );
    if (route != _routeSent) {
      _routeSent = route;
      unawaited(base.setRoute(route));
    }

    final accuracy = accuracyGeoJson(widget.user);
    if (accuracy != _accuracySent) {
      _accuracySent = accuracy;
      unawaited(base.setAccuracy(accuracy));
    }
  }

  void _fitCamera() {
    final size = _controller.size;
    if (size.isEmpty) return;
    final target = KPlanMap.cameraFor(
      widget.map,
      size: size,
      user: widget.user?.point,
      padding: widget.padding,
    );
    unawaited(_controller.moveTo(target.center, target.zoom));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final engine = _engine;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        controller.size = size;
        final initial = _initialCamera ??= _startAt(size);

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.mapLand),
            if (engine != null)
              engine.build(
                context,
                MapEngineConfig(
                  initialCamera: initial,
                  interactive: widget.interactive,
                  minZoom: KPlanMap.minZoom,
                  maxZoom: KPlanMap.maxZoom,
                  onCameraChanged: controller.report,
                  onReady: _onReady,
                  onTap: widget.onMapTap,
                ),
              ),
            const Positioned.fill(child: PaperTexture()),
            ValueListenableBuilder<MapCameraTarget?>(
              valueListenable: controller.cameraListenable,
              builder: (context, camera, _) => camera == null
                  ? const SizedBox.shrink()
                  : _markers(camera, size),
            ),
            if (widget.showAttribution)
              const Positioned(left: 6, bottom: 6, child: MapAttribution()),
          ],
        );
      },
    );
  }

  Widget _markers(MapCameraTarget camera, Size size) {
    final user = widget.user;
    return Stack(
      fit: StackFit.expand,
      children: [
        _PinsLayer(
          map: widget.map,
          camera: camera,
          size: size,
          selectedId: widget.selectedId,
          compact: widget.compact,
          onPointTap: widget.onPointTap,
        ),
        if (user != null)
          IgnorePointer(
            child: MapMarkerLayer(
              camera: camera,
              size: size,
              markers: [
                MapMarker(
                  point: user.point,
                  size: const Size.square(UserLocationMarker.size),
                  child: UserLocationMarker(heading: user.heading),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Los pines del recorrido. Lee el zoom de la cámara: de lejos sólo se nombra
/// la parada destacada, para no tapar las calles.
class _PinsLayer extends StatelessWidget {
  const _PinsLayer({
    required this.map,
    required this.camera,
    required this.size,
    required this.selectedId,
    required this.compact,
    required this.onPointTap,
  });

  final RouteMap map;
  final MapCameraTarget camera;
  final Size size;
  final String? selectedId;
  final bool compact;
  final ValueChanged<RouteMapPoint>? onPointTap;

  /// Desde este zoom todas las paradas llevan su nombre.
  static const double _labelsZoom = 14;

  static const double _labelGap = 3;

  @override
  Widget build(BuildContext context) {
    final start = map.start;
    final regular = <MapMarker>[];
    final emphasized = <MapMarker>[];

    // Al revés: con paradas muy juntas, las primeras del recorrido quedan
    // encima y se pueden tocar.
    for (final point in map.points.reversed) {
      final isEmphasized =
          point.id == selectedId ||
          (selectedId == null &&
              map.isTrip &&
              point.status == TripStopStatus.next);
      final withLabel =
          map.kind == RouteMapKind.place ||
          isEmphasized ||
          (!compact && camera.zoom >= _labelsZoom);
      (isEmphasized ? emphasized : regular).add(
        _pointMarker(point, emphasized: isEmphasized, withLabel: withLabel),
      );
    }

    return MapMarkerLayer(
      camera: camera,
      size: size,
      markers: [
        if (start != null)
          MapMarker(
            point: start,
            size: StartPin.size,
            anchor: Alignment.bottomCenter,
            child: const StartPin(),
          ),
        ...regular,
        ...emphasized,
      ],
    );
  }

  /// La punta del pin queda sobre el lugar y el nombre, debajo.
  MapMarker _pointMarker(
    RouteMapPoint point, {
    required bool emphasized,
    required bool withLabel,
  }) {
    final pin = StopPin.sizeFor(emphasized: emphasized);
    final width = withLabel ? PinLabel.maxWidth : pin.width;
    final height = pin.height + (withLabel ? _labelGap + PinLabel.height : 0);

    return MapMarker(
      key: ValueKey('pin-${point.id}'),
      point: point.point,
      size: Size(width, height),
      // La punta es el centro de la fila de arriba: a pin.height del borde
      // superior del marcador.
      anchor: Alignment(0, 2 * pin.height / height - 1),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: onPointTap == null ? null : () => onPointTap!(point),
        child: Column(
          children: [
            StopPin(
              number: point.number,
              status: point.status,
              emphasized: emphasized,
              icon: point.isStop ? Icons.place : Icons.event,
            ),
            if (withLabel) ...[
              const SizedBox(height: _labelGap),
              PinLabel(point.name, emphasized: emphasized),
            ],
          ],
        ),
      ),
    );
  }
}

/// La atribución que piden OpenFreeMap y OpenStreetMap a cambio de usar sus
/// mapas gratis.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  static final Uri _copyright = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(_copyright, mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary10.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '© OpenMapTiles © OpenStreetMap',
          style: AppTextStyles.caption.copyWith(fontSize: 9),
        ),
      ),
    );
  }
}
