import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/route_map_builder.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/user_location.dart';
import 'map_camera.dart';

/// Los zoom del mapa, en la escala de MapLibre.
abstract final class MapZoom {
  static const double min = 3;
  static const double max = 19;

  /// Más cerca que esto, un solo lugar llenaría la pantalla.
  static const double fitMax = 15.5;

  /// Desde aquí todas las paradas llevan su nombre.
  static const double labels = 14;
}

/// El encuadre del recorrido: en un viaje, el turista y lo que falta.
MapCamera fitRoute(
  RouteMap map, {
  LatLng? user,
  EdgeInsets padding = EdgeInsets.zero,
  required Size size,
}) => MapCamera.fit(
  RouteMapBuilder.focus(map, user: user),
  size: size,
  padding: padding,
  maxZoom: MapZoom.fitMax,
);

/// Lo que se le puede pedir al mapa, lo dibuje MapLibre o el papel.
abstract interface class MapSurface {
  Size get size;

  /// Hacia dónde mira ahora; `null` si todavía no está listo.
  Future<MapCamera?> camera();

  /// Lleva la cámara a [target] con una animación corta.
  Future<void> flyTo(MapCamera target);
}

/// Mueve la cámara del mapa desde la pantalla que lo muestra.
class KPlanMapController {
  MapSurface? _surface;

  /// Lo llama el mapa al aparecer y al irse.
  void attach(MapSurface surface) => _surface = surface;

  void detach(MapSurface surface) {
    if (identical(_surface, surface)) _surface = null;
  }

  /// Tamaño del mapa; `null` si todavía no se muestra.
  Size? get size => _surface?.size;

  Future<MapCamera?> camera() async => _surface?.camera();

  Future<void> flyTo(MapCamera target) async => _surface?.flyTo(target);
}

/// Lo que recibe cada forma de dibujar el mapa.
abstract class MapSurfaceWidget extends StatefulWidget {
  const MapSurfaceWidget({
    super.key,
    required this.map,
    required this.controller,
    required this.interactive,
    required this.compact,
    required this.padding,
    this.user,
    this.selectedId,
    this.onPointTap,
    this.onMapTap,
  });

  final RouteMap map;
  final KPlanMapController controller;
  final bool interactive;
  final bool compact;

  /// Margen del primer encuadre.
  final EdgeInsets padding;
  final UserLocation? user;
  final String? selectedId;
  final ValueChanged<RouteMapPoint>? onPointTap;
  final VoidCallback? onMapTap;
}
