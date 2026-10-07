import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/route_map_builder.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/trip_progress.dart';
import '../../../data/models/user_location.dart';
import 'map_pins.dart';

/// Una imagen del mapa: el widget que la dibuja y el nombre con que se
/// registra en MapLibre. El nombre depende sólo de lo que se ve, así que dos
/// pines iguales comparten imagen.
@immutable
class MapIcon {
  const MapIcon(this.name, this.widget);

  final String name;
  final Widget widget;
}

/// Un pin del mapa con su nombre debajo.
@immutable
class ScenePin {
  const ScenePin({
    required this.id,
    required this.position,
    required this.pin,
    required this.order,
    this.point,
    this.label,
    this.labelAlways = false,
    this.pulse,
  });

  final String id;
  final LatLng position;
  final MapIcon pin;

  /// Más alto, más arriba: lo que se dibuja encima con pines muy juntos.
  final int order;

  /// La parada o el evento; `null` en el pin de inicio, que no se toca.
  final RouteMapPoint? point;

  /// `null` si el pin va sin nombre.
  final MapIcon? label;

  /// `true` si el nombre se ve a cualquier zoom; si no, sólo de cerca.
  final bool labelAlways;

  /// Color del halo que late detrás; `null` si no se destaca.
  final Color? pulse;
}

/// Lo que va encima de las calles: los tramos del recorrido, los pines con
/// sus nombres y el turista.
class MapScene {
  MapScene._({required this.segments, required this.pins, required this.user});

  factory MapScene.of(
    RouteMap map, {
    UserLocation? user,
    String? selectedId,
    bool compact = false,
  }) {
    final start = map.start;
    final points = map.points;
    final pins = <ScenePin>[
      if (start != null)
        ScenePin(
          id: startId,
          position: start,
          pin: const MapIcon('pin/start', StartPin()),
          order: 0,
        ),
    ];

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final emphasized =
          point.id == selectedId ||
          (selectedId == null &&
              map.isTrip &&
              point.status == TripStopStatus.next);
      final labelAlways = map.kind == RouteMapKind.place || emphasized;
      final size = emphasized ? 'big' : 'small';
      final icon = point.isStop ? Icons.place : Icons.event;
      pins.add(
        ScenePin(
          id: point.id,
          point: point,
          position: point.point,
          pin: MapIcon(
            'pin/${point.status.name}/'
            '${point.number ?? (point.isStop ? 'place' : 'event')}/$size',
            StopPin(
              number: point.number,
              status: point.status,
              emphasized: emphasized,
              icon: icon,
            ),
          ),
          // Con paradas muy juntas, las primeras del recorrido quedan encima
          // y se pueden tocar; la destacada, encima de todas.
          order: emphasized ? points.length + 1 : points.length - i,
          label: compact && !labelAlways
              ? null
              : MapIcon(
                  'label/$size/${point.name}',
                  PinLabel(point.name, emphasized: emphasized),
                ),
          labelAlways: labelAlways,
          pulse: emphasized ? StopPin.colorFor(point.status) : null,
        ),
      );
    }
    pins.sort((a, b) => a.order.compareTo(b.order));

    return MapScene._(
      segments: RouteMapBuilder.segments(map, user: user?.point),
      pins: pins,
      user: user,
    );
  }

  /// El id del pin de inicio, que no es una parada.
  static const String startId = 'kplan-start';

  /// Más lejos que esto, el círculo de precisión del GPS no ayuda.
  static const double maxAccuracyMeters = 250;

  final List<RouteSegment> segments;

  /// De abajo hacia arriba.
  final List<ScenePin> pins;
  final UserLocation? user;

  /// La imagen del turista: un punto si está quieto, una flecha si se mueve.
  MapIcon? get userIcon {
    final user = this.user;
    if (user == null) return null;
    return user.heading == null
        ? const MapIcon('user/still', UserLocationMarker())
        : const MapIcon('user/moving', UserLocationMarker(heading: 0));
  }

  bool get showsAccuracy {
    final accuracy = user?.accuracy ?? 0;
    return accuracy > 0 && accuracy < maxAccuracyMeters;
  }

  /// Todas las imágenes que hacen falta, sin repetir.
  List<MapIcon> get icons {
    final byName = <String, MapIcon>{};
    for (final pin in pins) {
      byName[pin.pin.name] = pin.pin;
      final label = pin.label;
      if (label != null) byName[label.name] = label;
    }
    final userIcon = this.userIcon;
    if (userIcon != null) byName[userIcon.name] = userIcon;
    return byName.values.toList();
  }

  /// Los tramos, cada uno con su `style` para elegir cómo se pinta.
  Map<String, dynamic> routeGeoJson() => _collection([
    for (final segment in segments)
      {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [for (final point in segment.points) _lngLat(point)],
        },
        'properties': {'style': segment.style.name},
      },
  ]);

  /// Los pines: `icon` y `label` son nombres de imagen, `always` dice si el
  /// nombre se ve de lejos y `pulse` es el color del halo.
  Map<String, dynamic> pinsGeoJson() => _collection([
    for (final pin in pins)
      {
        'type': 'Feature',
        'id': pin.id,
        'geometry': {'type': 'Point', 'coordinates': _lngLat(pin.position)},
        'properties': {
          'icon': pin.pin.name,
          'label': ?pin.label?.name,
          'always': pin.labelAlways,
          'order': pin.order,
          if (pin.pulse case final pulse?) 'pulse': hexOf(pulse),
        },
      },
  ]);

  Map<String, dynamic> userGeoJson() {
    final user = this.user;
    final icon = userIcon;
    if (user == null || icon == null) return _collection(const []);
    return _collection([
      {
        'type': 'Feature',
        'geometry': {'type': 'Point', 'coordinates': _lngLat(user.point)},
        'properties': {'icon': icon.name, 'heading': user.heading ?? 0},
      },
    ]);
  }

  /// El círculo de precisión del GPS, como polígono: MapLibre mide los
  /// círculos en puntos de pantalla, no en metros.
  Map<String, dynamic> accuracyGeoJson() {
    final user = this.user;
    if (user == null || !showsAccuracy) return _collection(const []);
    const sides = 48;
    final center = user.point;
    final dLat = user.accuracy / _metersPerDegree;
    final dLng = dLat / math.cos(center.latitude * math.pi / 180);
    final ring = [
      for (var i = 0; i <= sides; i++)
        [
          center.longitude + dLng * math.cos(2 * math.pi * i / sides),
          center.latitude + dLat * math.sin(2 * math.pi * i / sides),
        ],
    ];
    return _collection([
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
        'properties': const <String, dynamic>{},
      },
    ]);
  }

  /// `#rrggbb`: el formato de color que entiende MapLibre.
  static String hexOf(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  static const double _metersPerDegree = 111320;

  static List<double> _lngLat(LatLng point) => [
    point.longitude,
    point.latitude,
  ];

  static Map<String, dynamic> _collection(
    List<Map<String, dynamic>> features,
  ) => {'type': 'FeatureCollection', 'features': features};
}
