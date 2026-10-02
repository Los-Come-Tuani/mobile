import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/map_camera.dart';
import 'package:latlong2/latlong.dart';

/// Granada: el punto de encuentro y las seis paradas del circuito.
const _salida = LatLng(11.9344, -85.9560);
const _catedral = LatLng(11.9299, -85.9561);
const _muelle = LatLng(11.9265, -85.9420);
const _recorrido = [
  _salida,
  _catedral,
  LatLng(11.9304, -85.9564),
  LatLng(11.9310, -85.9520),
  LatLng(11.9325, -85.9548),
  LatLng(11.9288, -85.9575),
  _muelle,
];

/// Un teléfono de verdad (411 x 914 px lógicos).
const _phone = Size(411, 914);

/// Lo que ocupan [points] en pantalla.
Rect _onScreen(List<LatLng> points, MapCameraTarget camera, Size size) {
  final offsets = [
    for (final point in points) MapProjection.toScreen(point, camera, size),
  ];
  return Rect.fromLTRB(
    offsets.map((o) => o.dx).reduce(math.min),
    offsets.map((o) => o.dy).reduce(math.min),
    offsets.map((o) => o.dx).reduce(math.max),
    offsets.map((o) => o.dy).reduce(math.max),
  );
}

void main() {
  group('proyección', () {
    test('a zoom 0 el mundo mide 512 px', () {
      expect(MapProjection.worldSize(0), 512);
      expect(
        MapProjection.project(const LatLng(0, 0), 0),
        const Offset(256, 256),
      );
      expect(MapProjection.project(const LatLng(0, -180), 0).dx, 0);
      expect(MapProjection.project(const LatLng(0, 180), 0).dx, 512);
    });

    test('cada nivel de zoom duplica los píxeles', () {
      final a = MapProjection.project(_catedral, 10);
      final b = MapProjection.project(_catedral, 11);

      expect(b.dx, closeTo(a.dx * 2, 1e-6));
      expect(b.dy, closeTo(a.dy * 2, 1e-6));
    });

    test('hacia el norte la y disminuye y hacia el este la x aumenta', () {
      final base = MapProjection.project(_catedral, 14);
      final north = MapProjection.project(
        LatLng(_catedral.latitude + 0.001, _catedral.longitude),
        14,
      );
      final east = MapProjection.project(
        LatLng(_catedral.latitude, _catedral.longitude + 0.001),
        14,
      );

      expect(north.dy, lessThan(base.dy));
      expect(east.dx, greaterThan(base.dx));
    });

    test('unproject deshace a project', () {
      const points = [
        _catedral,
        LatLng(0, 0),
        LatLng(-33.87, 151.21),
        LatLng(60, -120),
        LatLng(84, 10),
        LatLng(-84, -170),
      ];

      for (final point in points) {
        for (final zoom in [0.0, 3.5, 10.0, 15.5, 17.5]) {
          final back = MapProjection.unproject(
            MapProjection.project(point, zoom),
            zoom,
          );
          expect(back.latitude, closeTo(point.latitude, 1e-7));
          expect(back.longitude, closeTo(point.longitude, 1e-7));
        }
      }
    });

    test('los polos se recortan a los límites de Web Mercator', () {
      final pole = MapProjection.project(const LatLng(90, 0), 0);
      final limit = MapProjection.project(
        const LatLng(MapProjection.maxLatitude, 0),
        0,
      );

      expect(pole.dy.isFinite, isTrue);
      expect(pole.dy, closeTo(limit.dy, 1e-9));
    });

    test('la escala es la de MapLibre: 78 271.5 m por px a zoom 0', () {
      // La fórmula de Mapbox y MapLibre para tiles de 512 px.
      const zoom = 15.0;
      final metersPerPixel =
          78271.51696402048 *
          math.cos(_catedral.latitude * math.pi / 180) /
          math.pow(2, zoom);
      // 100 m hacia el este: un grado de longitud mide 111 319.49 m por el
      // coseno de la latitud.
      final degrees =
          100 / (111319.49 * math.cos(_catedral.latitude * math.pi / 180));

      final a = MapProjection.project(_catedral, zoom);
      final b = MapProjection.project(
        LatLng(_catedral.latitude, _catedral.longitude + degrees),
        zoom,
      );

      expect(b.dx - a.dx, closeTo(100 / metersPerPixel, 0.01));
    });

    test('el centro de la cámara queda en el centro de la pantalla', () {
      const camera = MapCameraTarget(center: _catedral, zoom: 15);

      expect(
        MapProjection.toScreen(_catedral, camera, _phone),
        _phone.center(Offset.zero),
      );
    });

    test('un punto al noreste de la cámara cae arriba a la derecha', () {
      const camera = MapCameraTarget(center: _catedral, zoom: 15);
      final spot = MapProjection.toScreen(_salida, camera, _phone);
      final east = MapProjection.toScreen(
        const LatLng(11.9299, -85.9500),
        camera,
        _phone,
      );

      expect(spot.dy, lessThan(_phone.height / 2));
      expect(east.dx, greaterThan(_phone.width / 2));
    });
  });

  group('fit', () {
    test('un solo punto queda en el zoom máximo, en el centro', () {
      final camera = MapProjection.fit(
        const [_catedral],
        size: _phone,
        padding: const EdgeInsets.all(40),
        maxZoom: 15.5,
      );

      expect(camera.zoom, 15.5);
      expect(camera.center.latitude, closeTo(_catedral.latitude, 1e-9));
      expect(camera.center.longitude, closeTo(_catedral.longitude, 1e-9));
    });

    test('el recorrido cabe dentro del padding, aprovechando el espacio', () {
      const padding = EdgeInsets.fromLTRB(72, 120, 72, 380);
      final camera = MapProjection.fit(
        _recorrido,
        size: _phone,
        padding: padding,
        minZoom: 3,
        maxZoom: 15.5,
      );
      final bounds = _onScreen(_recorrido, camera, _phone);

      expect(bounds.left, greaterThanOrEqualTo(padding.left - 1e-6));
      expect(bounds.top, greaterThanOrEqualTo(padding.top - 1e-6));
      expect(bounds.right, lessThanOrEqualTo(_phone.width - padding.right));
      expect(bounds.bottom, lessThanOrEqualTo(_phone.height - padding.bottom));

      // Toca el límite en el eje que manda: el zoom es el más cercano posible.
      final freeWidth = _phone.width - padding.horizontal;
      final freeHeight = _phone.height - padding.vertical;
      expect(
        math.max(bounds.width / freeWidth, bounds.height / freeHeight),
        closeTo(1, 1e-6),
      );
    });

    test('un padding desparejo centra los puntos en el área libre', () {
      const padding = EdgeInsets.fromLTRB(20, 120, 90, 380);
      final camera = MapProjection.fit(
        _recorrido,
        size: _phone,
        padding: padding,
        maxZoom: 18,
      );
      final bounds = _onScreen(_recorrido, camera, _phone);

      final free = Rect.fromLTRB(
        padding.left,
        padding.top,
        _phone.width - padding.right,
        _phone.height - padding.bottom,
      );
      expect(bounds.center.dx, closeTo(free.center.dx, 1e-6));
      expect(bounds.center.dy, closeTo(free.center.dy, 1e-6));
    });

    test('un solo punto también se acomoda en el área libre', () {
      const padding = EdgeInsets.fromLTRB(64, 64, 64, 300);
      final camera = MapProjection.fit(
        const [_catedral],
        size: _phone,
        padding: padding,
        maxZoom: 15.5,
      );
      final spot = MapProjection.toScreen(_catedral, camera, _phone);

      expect(spot.dx, closeTo(_phone.width / 2, 1e-6));
      expect(spot.dy, closeTo((64 + _phone.height - 300) / 2, 1e-6));
    });

    test('puntos al doble de distancia piden un nivel menos de zoom', () {
      MapCameraTarget fitEastWest(double degrees) => MapProjection.fit(
        [_catedral, LatLng(_catedral.latitude, _catedral.longitude + degrees)],
        size: _phone,
        maxZoom: 22,
      );

      final near = fitEastWest(0.004);
      final far = fitEastWest(0.008);

      expect(near.zoom - far.zoom, closeTo(1, 1e-9));
    });

    test('no pasa del zoom máximo aunque los puntos estén pegados', () {
      final camera = MapProjection.fit(
        const [_catedral, LatLng(11.92990001, -85.95610001)],
        size: _phone,
        maxZoom: 15.5,
      );

      expect(camera.zoom, 15.5);
    });

    test('sin espacio libre o con puntos muy lejanos queda en el mínimo', () {
      final crowded = MapProjection.fit(
        _recorrido,
        size: const Size(100, 100),
        padding: const EdgeInsets.all(80),
        minZoom: 3,
      );
      final worldwide = MapProjection.fit(
        const [LatLng(-50, -170), LatLng(50, 170)],
        size: _phone,
        minZoom: 3,
      );

      expect(crowded.zoom, 3);
      expect(worldwide.zoom, 3);
    });

    test('sin puntos no falla', () {
      final camera = MapProjection.fit(const [], size: _phone, minZoom: 3);

      expect(camera.zoom, 3);
    });
  });
}
