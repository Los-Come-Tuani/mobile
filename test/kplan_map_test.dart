import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/core/utils/map_camera.dart';
import 'package:k_plan_mobile/src/data/models/route_map.dart';
import 'package:k_plan_mobile/src/data/models/trip_progress.dart';
import 'package:k_plan_mobile/src/data/models/user_location.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/kplan_map.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/map_engine.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/map_pins.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/route_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Un motor que no dibuja nada: guarda lo que `KPlanMap` le pide.
class _FakeEngine implements MapEngine {
  MapEngineConfig? config;

  @override
  Widget build(BuildContext context, MapEngineConfig config) {
    this.config = config;
    return const SizedBox.expand();
  }
}

class _Move {
  const _Move(this.target, this.animate);

  final MapCameraTarget target;
  final Duration? animate;
}

/// El mapa nativo de mentira: anota las órdenes que recibe.
class _FakeBase implements MapBase {
  final moves = <_Move>[];
  final routes = <String>[];
  final accuracies = <String>[];

  @override
  Future<void> moveTo(MapCameraTarget target, {Duration? animate}) async =>
      moves.add(_Move(target, animate));

  @override
  Future<void> setRoute(String geoJson) async => routes.add(geoJson);

  @override
  Future<void> setAccuracy(String geoJson) async => accuracies.add(geoJson);
}

const _size = Size(411, 800);
const _catedral = LatLng(11.9299, -85.9561);
const _granada = [
  _catedral,
  LatLng(11.9310, -85.9520),
  LatLng(11.9265, -85.9420),
];

RouteMap _preview(List<LatLng> points, {LatLng? start}) => RouteMap(
  kind: RouteMapKind.preview,
  title: 'Granada',
  start: start,
  points: [
    for (var i = 0; i < points.length; i++)
      RouteMapPoint(
        id: 'p$i',
        name: 'Parada $i',
        point: points[i],
        number: i + 1,
      ),
  ],
);

/// El viaje: la primera parada hecha, la segunda es la siguiente.
RouteMap _trip() => RouteMap(
  kind: RouteMapKind.trip,
  title: 'Granada',
  points: [
    for (var i = 0; i < _granada.length; i++)
      RouteMapPoint(
        id: 'p$i',
        name: 'Parada $i',
        point: _granada[i],
        number: i + 1,
        status: switch (i) {
          0 => TripStopStatus.done,
          1 => TripStopStatus.next,
          _ => TripStopStatus.pending,
        },
      ),
  ],
);

void main() {
  late _FakeEngine engine;

  setUp(() => engine = _FakeEngine());

  /// El mapa ocupa exactamente una pantalla de 411 x 800.
  Future<void> pumpMap(
    WidgetTester tester,
    KPlanMap map, {
    MapEngine? withEngine,
  }) async {
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Provider<MapEngine?>.value(
        value: withEngine,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: map),
        ),
      ),
    );
  }

  Future<void> pumpWithEngine(WidgetTester tester, KPlanMap map) =>
      pumpMap(tester, map, withEngine: engine);

  group('el motor', () {
    testWidgets('recibe el encuadre, los límites de zoom y los gestos', (
      tester,
    ) async {
      final map = _preview(_granada);
      await pumpWithEngine(tester, KPlanMap(map: map));
      final config = engine.config!;

      expect(
        config.initialCamera,
        KPlanMap.cameraFor(map, size: _size, padding: const EdgeInsets.all(40)),
      );
      expect(config.interactive, isTrue);
      expect(config.minZoom, KPlanMap.minZoom);
      expect(config.maxZoom, KPlanMap.maxZoom);
      expect(config.onTap, isNull);
    });

    testWidgets('el mini mapa no lleva gestos', (tester) async {
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), interactive: false),
      );

      expect(engine.config!.interactive, isFalse);
    });

    testWidgets('un toque sobre el mapa llega a quien lo pidió', (
      tester,
    ) async {
      var taps = 0;
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), onMapTap: () => taps++),
      );

      engine.config!.onTap!();

      expect(taps, 1);
    });
  });

  group('lo que se manda al mapa', () {
    testWidgets('el recorrido y la precisión salen en cuanto carga el estilo', (
      tester,
    ) async {
      await pumpWithEngine(tester, KPlanMap(map: _preview(_granada)));
      final base = _FakeBase();
      expect(base.routes, isEmpty);

      engine.config!.onReady(base);

      final route = jsonDecode(base.routes.single) as Map<String, dynamic>;
      // Tres paradas, dos tramos de vista previa.
      expect(route['features'], hasLength(2));
      expect(base.accuracies, [emptyGeoJson]);
    });

    testWidgets('sólo vuelve a mandar lo que cambió', (tester) async {
      final map = _preview(_granada);
      await pumpWithEngine(tester, KPlanMap(map: map));
      final base = _FakeBase();
      engine.config!.onReady(base);

      await pumpWithEngine(tester, KPlanMap(map: _preview(_granada)));
      expect(base.routes, hasLength(1));
      expect(base.accuracies, hasLength(1));

      // Llega el GPS: cambia el círculo; la vista previa no sigue al turista.
      const user = UserLocation(point: _catedral, accuracy: 30);
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), user: user),
      );
      expect(base.routes, hasLength(1));
      expect(base.accuracies, hasLength(2));
      expect(base.accuracies.last, accuracyGeoJson(user));
    });

    testWidgets('en un viaje, el tramo hacia la siguiente parada sale del '
        'turista', (tester) async {
      await pumpWithEngine(tester, KPlanMap(map: _trip()));
      final base = _FakeBase();
      engine.config!.onReady(base);

      const user = UserLocation(point: LatLng(11.9305, -85.9540), accuracy: 12);
      await pumpWithEngine(tester, KPlanMap(map: _trip(), user: user));

      expect(base.routes, hasLength(2));
      final current = (jsonDecode(base.routes.last)['features'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((f) => f['properties']['style'] == 'current');
      final coordinates = current['geometry']['coordinates'] as List;
      expect(coordinates.first, [user.point.longitude, user.point.latitude]);
    });

    testWidgets('el mini mapa se reencuadra sólo cuando cambia lo que enfoca', (
      tester,
    ) async {
      final first = _preview(_granada);
      await pumpWithEngine(tester, KPlanMap(map: first, interactive: false));
      final base = _FakeBase();
      engine.config!.onReady(base);
      const padding = EdgeInsets.all(40);
      final fitFirst = KPlanMap.cameraFor(first, size: _size, padding: padding);
      // Al cargar, se encuadra por si algo cambió mientras arrancaba.
      expect(base.moves.single.target, fitFirst);
      expect(base.moves.single.animate, isNull);

      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), interactive: false),
      );
      expect(base.moves, hasLength(1));

      final second = _preview(const [_catedral, LatLng(11.9500, -85.9300)]);
      await pumpWithEngine(tester, KPlanMap(map: second, interactive: false));
      expect(base.moves, hasLength(2));
      expect(
        base.moves.last.target,
        KPlanMap.cameraFor(second, size: _size, padding: padding),
      );
    });

    testWidgets('el mapa interactivo no se reencuadra solo', (tester) async {
      await pumpWithEngine(tester, KPlanMap(map: _preview(_granada)));
      final base = _FakeBase();
      engine.config!.onReady(base);

      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(const [_catedral, LatLng(11.9500, -85.9300)])),
      );

      expect(base.moves, isEmpty);
    });
  });

  group('los pines', () {
    testWidgets('su punta cae sobre el lugar, con o sin nombre', (
      tester,
    ) async {
      final map = _preview(_granada, start: const LatLng(11.9344, -85.9560));
      await pumpWithEngine(
        tester,
        KPlanMap(map: map, compact: true, selectedId: 'p1'),
      );
      final camera = engine.config!.initialCamera;

      Offset tipOf(Finder pin) => tester.getRect(pin).bottomCenter;
      Offset at(LatLng point) => MapProjection.toScreen(point, camera, _size);
      // Los pines se dibujan en orden inverso (los primeros quedan encima):
      // se buscan por su id, no por su lugar en el árbol.
      Finder pinOf(String id) => find.descendant(
        of: find.byKey(ValueKey('pin-$id')),
        matching: find.byType(StopPin),
      );

      // Sin nombre (mapa chico): la gota es todo el marcador.
      expect(find.byType(StopPin), findsNWidgets(3));
      expect(tipOf(pinOf('p0')), offsetMoreOrLessEquals(at(_granada[0])));
      expect(tipOf(pinOf('p2')), offsetMoreOrLessEquals(at(_granada[2])));
      // La destacada lleva su nombre debajo: el marcador es más alto que la
      // gota y aun así la punta queda en su sitio.
      expect(find.text('Parada 1'), findsOneWidget);
      expect(tipOf(pinOf('p1')), offsetMoreOrLessEquals(at(_granada[1])));

      expect(
        tipOf(find.byType(StartPin)),
        offsetMoreOrLessEquals(at(const LatLng(11.9344, -85.9560))),
      );
    });

    testWidgets('el marcador del usuario queda centrado en su posición', (
      tester,
    ) async {
      const user = UserLocation(point: LatLng(11.9305, -85.9540), heading: 90);
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), user: user),
      );
      final camera = engine.config!.initialCamera;

      expect(
        tester.getCenter(find.byType(UserLocationMarker)),
        offsetMoreOrLessEquals(
          MapProjection.toScreen(user.point, camera, _size),
        ),
      );
    });

    testWidgets('siguen a la cámara que informa el motor', (tester) async {
      await pumpWithEngine(tester, KPlanMap(map: _preview(_granada)));
      final before = tester.getCenter(find.text('1'));
      final camera = engine.config!.initialCamera;

      // La cámara se corre hacia el este: lo que hay se va hacia la izquierda.
      engine.config!.onCameraChanged(
        MapCameraTarget(
          center: LatLng(
            camera.center.latitude,
            camera.center.longitude + 0.002,
          ),
          zoom: camera.zoom,
        ),
      );
      await tester.pump();

      final after = tester.getCenter(find.text('1'));
      expect(after.dx, lessThan(before.dx));
      expect(after.dy, closeTo(before.dy, 1e-6));
    });

    testWidgets('los nombres aparecen al acercarse, salvo en el mapa chico', (
      tester,
    ) async {
      await pumpWithEngine(tester, KPlanMap(map: _preview(_granada)));
      final camera = engine.config!.initialCamera;
      MapCameraTarget at(double zoom) =>
          MapCameraTarget(center: camera.center, zoom: zoom);

      engine.config!.onCameraChanged(at(12));
      await tester.pump();
      expect(find.text('Parada 0'), findsNothing);

      engine.config!.onCameraChanged(at(14));
      await tester.pump();
      expect(find.text('Parada 0'), findsOneWidget);
      expect(find.text('Parada 2'), findsOneWidget);
    });

    testWidgets('tocar un pin avisa cuál', (tester) async {
      RouteMapPoint? tapped;
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), onPointTap: (p) => tapped = p),
      );

      await tester.tap(find.text('2'));

      expect(tapped?.id, 'p1');
    });

    testWidgets('sin motor queda el papel con los pines', (tester) async {
      await pumpMap(tester, KPlanMap(map: _preview(_granada)));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('© OpenMapTiles © OpenStreetMap'), findsOneWidget);
    });
  });

  group('el controlador', () {
    testWidgets('sabe el tamaño y la cámara del mapa', (tester) async {
      final controller = KPlanMapController();
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), controller: controller),
      );

      expect(controller.size, _size);
      expect(controller.camera, engine.config!.initialCamera);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('lo que el motor informa pasa al controlador', (tester) async {
      final controller = KPlanMapController();
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), controller: controller),
      );
      const moved = MapCameraTarget(center: _catedral, zoom: 15);

      engine.config!.onCameraChanged(moved);

      expect(controller.camera, moved);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('el vuelo pedido antes de que el mapa esté listo se aplica '
        'al estar listo', (tester) async {
      final controller = KPlanMapController();
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), controller: controller),
      );
      const target = MapCameraTarget(center: LatLng(11.93, -85.95), zoom: 16);

      controller.flyTo(target.center, target.zoom);
      // Los pines ya se mueven; el mapa, todavía no existe.
      expect(controller.camera, target);

      final base = _FakeBase();
      engine.config!.onReady(base);

      expect(base.moves.single.target, target);
      expect(base.moves.single.animate, isNull);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('con el mapa listo, flyTo anima y moveTo salta', (
      tester,
    ) async {
      final controller = KPlanMapController();
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), controller: controller),
      );
      final base = _FakeBase();
      engine.config!.onReady(base);

      controller.flyTo(_catedral, 16);
      controller.moveTo(_catedral, 15);

      expect(base.moves[0].animate, KPlanMapController.flyDuration);
      expect(base.moves[0].target.zoom, 16);
      expect(base.moves[1].animate, isNull);
      expect(base.moves[1].target.zoom, 15);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('al cerrarse el mapa ya no le manda órdenes', (tester) async {
      final controller = KPlanMapController();
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), controller: controller),
      );
      final base = _FakeBase();
      engine.config!.onReady(base);

      await tester.pumpWidget(const SizedBox());
      controller.flyTo(_catedral, 16);

      expect(base.moves, isEmpty);
      controller.dispose();
    });

    testWidgets('un mapa nuevo con el mismo controlador parte de su encuadre', (
      tester,
    ) async {
      final controller = KPlanMapController();
      await pumpWithEngine(
        tester,
        KPlanMap(map: _preview(_granada), controller: controller),
      );
      // Un vuelo que quedó sin aplicar no debe pasar al mapa siguiente.
      controller.flyTo(const LatLng(12, -86), 10);
      await tester.pumpWidget(const SizedBox());

      final other = _preview(const [_catedral, LatLng(11.9500, -85.9300)]);
      engine = _FakeEngine();
      await pumpWithEngine(
        tester,
        KPlanMap(map: other, controller: controller),
      );
      final base = _FakeBase();
      engine.config!.onReady(base);

      expect(base.moves, isEmpty);
      expect(
        controller.camera,
        KPlanMap.cameraFor(
          other,
          size: _size,
          padding: const EdgeInsets.all(40),
        ),
      );

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  });
}
