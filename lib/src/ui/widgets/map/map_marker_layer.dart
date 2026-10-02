import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/map_camera.dart';

/// Un widget anclado a una coordenada del mapa.
@immutable
class MapMarker {
  const MapMarker({
    required this.point,
    required this.size,
    required this.child,
    this.anchor = Alignment.center,
    this.key,
  });

  final LatLng point;

  /// Debe ser el tamaño de [child].
  final Size size;
  final Widget child;

  /// Qué punto del marcador cae sobre [point]: el centro, la punta de abajo...
  /// (`Alignment.bottomCenter` deja el pin con su punta sobre el lugar).
  final Alignment anchor;

  /// Mantiene el estado del marcador (la animación de un pin) cuando cambia el
  /// orden.
  final Key? key;
}

/// Coloca widgets de Flutter sobre el mapa, en su coordenada.
///
/// La posición se calcula aquí con la proyección del mapa, a partir de la
/// cámara que éste va informando: no hace falta preguntarle nada al motor en
/// cada cuadro. Los toques sobre un marcador son del marcador; el resto pasa
/// al mapa de abajo.
class MapMarkerLayer extends StatelessWidget {
  const MapMarkerLayer({
    super.key,
    required this.camera,
    required this.size,
    required this.markers,
  });

  final MapCameraTarget camera;

  /// El tamaño del mapa.
  final Size size;
  final List<MapMarker> markers;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final marker in markers)
          _positioned(
            marker,
            MapProjection.toScreen(marker.point, camera, size),
          ),
      ],
    );
  }

  Widget _positioned(MapMarker marker, Offset screen) {
    final anchor = marker.anchor;
    return Positioned(
      key: marker.key,
      left: screen.dx - marker.size.width / 2 * (anchor.x + 1),
      top: screen.dy - marker.size.height / 2 * (anchor.y + 1),
      width: marker.size.width,
      height: marker.size.height,
      child: marker.child,
    );
  }
}
