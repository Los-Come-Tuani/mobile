import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/route_map_builder.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/user_location.dart';
import 'map_camera.dart';
import 'map_surface.dart';
import 'native_map.dart';
import 'paper_map.dart';
import 'paper_texture.dart';

export 'map_camera.dart' show MapCamera;
export 'map_surface.dart' show KPlanMapController, MapZoom;

/// El mapa de K'Plan: las calles de OpenFreeMap dibujadas por MapLibre con la
/// paleta de la app, el papel encima y el recorrido con sus pines.
///
/// MapLibre sólo corre en Android e iOS; en las pruebas y en escritorio queda
/// el papel con los pines y las líneas, que siguen sirviendo para orientarse.
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

  /// El encuadre del recorrido en un mapa de [size]: en un viaje, el turista
  /// y lo que falta.
  static MapCamera fitFor(
    RouteMap map, {
    LatLng? user,
    EdgeInsets padding = EdgeInsets.zero,
    required Size size,
  }) => fitRoute(map, user: user, padding: padding, size: size);

  static final bool _hasMapLibre =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  State<KPlanMap> createState() => _KPlanMapState();
}

class _KPlanMapState extends State<KPlanMap> {
  KPlanMapController? _ownController;

  KPlanMapController get _controller =>
      widget.controller ?? (_ownController ??= KPlanMapController());

  @override
  void didUpdateWidget(KPlanMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final size = _controller.size;
    if (widget.interactive || size == null) return;
    final before = RouteMapBuilder.focus(
      oldWidget.map,
      user: oldWidget.user?.point,
    );
    final after = RouteMapBuilder.focus(widget.map, user: widget.user?.point);
    if (!listEquals(before, after)) {
      _controller.flyTo(
        KPlanMap.fitFor(
          widget.map,
          user: widget.user?.point,
          padding: widget.padding,
          size: size,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = KPlanMap._hasMapLibre
        ? NativeMap(
            map: widget.map,
            user: widget.user,
            controller: _controller,
            interactive: widget.interactive,
            compact: widget.compact,
            padding: widget.padding,
            selectedId: widget.selectedId,
            onPointTap: widget.onPointTap,
            onMapTap: widget.onMapTap,
          )
        : PaperMap(
            map: widget.map,
            user: widget.user,
            controller: _controller,
            interactive: widget.interactive,
            compact: widget.compact,
            padding: widget.padding,
            selectedId: widget.selectedId,
            onPointTap: widget.onPointTap,
            onMapTap: widget.onMapTap,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.mapLand),
        surface,
        const Positioned.fill(child: PaperTexture()),
        if (widget.showAttribution)
          const Positioned(left: 6, bottom: 6, child: MapAttribution()),
      ],
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
