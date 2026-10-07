import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/map_camera.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const granada = LatLng(11.9299, -85.9560);
  const masaya = LatLng(11.9744, -86.0942);
  const phone = Size(411, 914);

  test('proyectar y volver da el mismo punto', () {
    final back = MapCamera.unproject(MapCamera.project(granada, 15.5), 15.5);

    expect(back.latitude, closeTo(granada.latitude, 1e-9));
    expect(back.longitude, closeTo(granada.longitude, 1e-9));
  });

  test('en el zoom 0 el mundo mide 512 puntos, como en MapLibre', () {
    expect(MapCamera.project(const LatLng(0, -180), 0), const Offset(0, 256));
    expect(MapCamera.project(const LatLng(0, 0), 0), const Offset(256, 256));
    expect(MapCamera.project(const LatLng(0, 0), 1), const Offset(512, 512));
  });

  test('un solo lugar queda al centro con el zoom máximo', () {
    final camera = MapCamera.fit([granada], size: phone, maxZoom: 15.5);

    expect(camera.zoom, 15.5);
    expect(camera.toScreen(granada, phone), phone.center(Offset.zero));
  });

  test('el encuadre deja los puntos dentro del margen', () {
    const padding = EdgeInsets.fromLTRB(72, 130, 72, 120);
    final camera = MapCamera.fit(
      [granada, masaya],
      size: phone,
      padding: padding,
      maxZoom: 18,
    );
    final area = padding.deflateRect(Offset.zero & phone);

    for (final point in [granada, masaya]) {
      final onScreen = camera.toScreen(point, phone);
      expect(area.inflate(0.5).contains(onScreen), isTrue, reason: '$point');
    }
    // Llena el ancho libre: se acerca todo lo que puede.
    final a = camera.toScreen(granada, phone);
    final b = camera.toScreen(masaya, phone);
    expect((a.dx - b.dx).abs(), closeTo(area.width, 0.5));
  });
}
