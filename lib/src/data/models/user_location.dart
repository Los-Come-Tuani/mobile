import 'package:latlong2/latlong.dart';

/// Dónde está el turista según el GPS del teléfono.
class UserLocation {
  const UserLocation({required this.point, this.heading, this.accuracy = 0});

  final LatLng point;

  /// Hacia dónde se mueve, en grados desde el norte; `null` si está quieto.
  final double? heading;

  /// Radio de error, en metros.
  final double accuracy;
}
