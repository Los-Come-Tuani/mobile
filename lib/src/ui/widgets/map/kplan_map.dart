import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/map_style.dart';
import '../../../core/utils/route_map_builder.dart';
import '../../../data/datasources/repository/map_tiles_repository.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/trip_progress.dart';
import '../../../data/models/user_location.dart';
import 'map_pins.dart';
import 'paper_texture.dart';
import 'route_layers.dart';

/// El mapa de K'Plan: las calles de OpenFreeMap con la paleta de la app, el
/// papel encima y el recorrido con sus pines.
///
/// Mientras cargan las calles (o sin conexión) queda el papel con los pines y
/// las líneas, que siguen sirviendo para orientarse.
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
  final MapController? controller;

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

  /// Más cerca que esto, un solo lugar llenaría la pantalla.
  static const double fitMaxZoom = 16.5;

  /// El encuadre del recorrido: en un viaje, el turista y lo que falta.
  static CameraFit fitFor(
    RouteMap map, {
    LatLng? user,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return CameraFit.coordinates(
      coordinates: RouteMapBuilder.focus(map, user: user),
      padding: padding,
      maxZoom: fitMaxZoom,
    );
  }

  @override
  State<KPlanMap> createState() => _KPlanMapState();
}

class _KPlanMapState extends State<KPlanMap> {
  MapController? _ownController;
  TileProviders? _tiles;
  bool _isReady = false;

  MapController get _controller =>
      widget.controller ?? (_ownController ??= MapController());

  @override
  void initState() {
    super.initState();
    context.read<MapTilesRepository?>()?.load().then((tiles) {
      if (mounted) setState(() => _tiles = tiles);
    });
  }

  @override
  void didUpdateWidget(KPlanMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interactive || !_isReady) return;
    final before = RouteMapBuilder.focus(
      oldWidget.map,
      user: oldWidget.user?.point,
    );
    final after = RouteMapBuilder.focus(widget.map, user: widget.user?.point);
    if (!listEquals(before, after)) {
      _controller.fitCamera(
        KPlanMap.fitFor(
          widget.map,
          user: widget.user?.point,
          padding: widget.padding,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final tiles = _tiles;

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCameraFit: KPlanMap.fitFor(
          widget.map,
          user: user?.point,
          padding: widget.padding,
        ),
        minZoom: 4,
        maxZoom: 18.5,
        backgroundColor: AppColors.mapLand,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
        onTap: widget.onMapTap == null ? null : (_, _) => widget.onMapTap!(),
        onMapReady: () => _isReady = true,
      ),
      children: [
        if (tiles != null)
          VectorTileLayer(
            theme: KPlanMapStyle.theme,
            tileProviders: tiles,
            fileCacheMaximumSizeInBytes: 150 * 1024 * 1024,
          ),
        const Positioned.fill(child: PaperTexture()),
        if (user != null && user.accuracy > 0 && user.accuracy < 250)
          CircleLayer(
            circles: [
              CircleMarker(
                point: user.point,
                radius: user.accuracy,
                useRadiusInMeter: true,
                color: AppColors.userLocation.withValues(alpha: 0.14),
                borderColor: AppColors.userLocation.withValues(alpha: 0.4),
                borderStrokeWidth: 1,
              ),
            ],
          ),
        PolylineLayer(
          polylines: routePolylines(
            RouteMapBuilder.segments(widget.map, user: user?.point),
          ),
        ),
        _PinsLayer(
          map: widget.map,
          selectedId: widget.selectedId,
          compact: widget.compact,
          onPointTap: widget.onPointTap,
        ),
        if (user != null)
          MarkerLayer(
            markers: [
              Marker(
                point: user.point,
                width: UserLocationMarker.size,
                height: UserLocationMarker.size,
                child: UserLocationMarker(heading: user.heading),
              ),
            ],
          ),
        if (widget.showAttribution)
          const Positioned(left: 6, bottom: 6, child: MapAttribution()),
      ],
    );
  }
}

/// Los pines del recorrido. Lee el zoom del mapa: de lejos sólo se nombra la
/// parada destacada, para no tapar las calles.
class _PinsLayer extends StatelessWidget {
  const _PinsLayer({
    required this.map,
    required this.selectedId,
    required this.compact,
    required this.onPointTap,
  });

  final RouteMap map;
  final String? selectedId;
  final bool compact;
  final ValueChanged<RouteMapPoint>? onPointTap;

  /// Desde este zoom todas las paradas llevan su nombre.
  static const double _labelsZoom = 15;

  static const double _labelGap = 3;

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom;
    final start = map.start;
    final regular = <Marker>[];
    final emphasized = <Marker>[];

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
          (!compact && zoom >= _labelsZoom);
      (isEmphasized ? emphasized : regular).add(
        _pointMarker(point, emphasized: isEmphasized, withLabel: withLabel),
      );
    }

    return MarkerLayer(
      markers: [
        if (start != null)
          Marker(
            point: start,
            width: StartPin.size.width,
            height: StartPin.size.height,
            alignment: Alignment.topCenter,
            child: const StartPin(),
          ),
        ...regular,
        ...emphasized,
      ],
    );
  }

  /// La punta del pin queda sobre el lugar y el nombre, debajo.
  Marker _pointMarker(
    RouteMapPoint point, {
    required bool emphasized,
    required bool withLabel,
  }) {
    final pin = StopPin.sizeFor(emphasized: emphasized);
    final width = withLabel ? PinLabel.maxWidth : pin.width;
    final height = pin.height + (withLabel ? _labelGap + PinLabel.height : 0);

    return Marker(
      key: ValueKey('pin-${point.id}'),
      point: point.point,
      width: width,
      height: height,
      alignment: Marker.computePixelAlignment(
        width: width,
        height: height,
        left: width / 2,
        top: pin.height,
      ),
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
