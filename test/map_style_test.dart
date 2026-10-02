import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_colors.dart';
import 'package:k_plan_mobile/src/core/theme/map_style.dart';
import 'package:k_plan_mobile/src/data/models/route_map.dart';

void main() {
  final style = KPlanMapStyle.build();
  final layers = [
    for (final layer in style['layers'] as List<dynamic>)
      layer as Map<String, dynamic>,
  ];
  final sources = style['sources'] as Map<String, dynamic>;

  Map<String, dynamic> layerById(String id) =>
      layers.singleWhere((layer) => layer['id'] == id);

  List<Object?> idsFrom(String source) => [
    for (final layer in layers)
      if (layer['source'] == source) layer['id'],
  ];

  test('el JSON serializado es el mismo estilo', () {
    expect(jsonDecode(KPlanMapStyle.json), jsonDecode(jsonEncode(style)));
    expect(style['version'], 8);
  });

  test('los ids no se repiten y cada capa usa una fuente que existe', () {
    final ids = [for (final layer in layers) layer['id']];
    expect(ids.toSet(), hasLength(ids.length));

    for (final layer in layers.where((l) => l['type'] != 'background')) {
      expect(sources, contains(layer['source']), reason: '${layer['id']}');
    }
  });

  test('las calles piden su capa a los tiles y el recorrido no', () {
    for (final layer in layers) {
      final isVector = layer['source'] == KPlanMapStyle.source;
      expect(
        layer.containsKey('source-layer'),
        isVector,
        reason: '${layer['id']}',
      );
    }
  });

  test('pide las calles y los glifos a OpenFreeMap', () {
    final streets = sources[KPlanMapStyle.source] as Map<String, dynamic>;
    expect(streets['type'], 'vector');
    expect(streets['url'], KPlanMapStyle.tilesUrl);
    expect(style['glyphs'], KPlanMapStyle.glyphsUrl);
  });

  test('las etiquetas sólo usan las fuentes que sirve OpenFreeMap', () {
    const served = {
      KPlanMapStyle.regularFont,
      KPlanMapStyle.boldFont,
      KPlanMapStyle.italicFont,
    };
    final labels = layers.where((layer) => layer['type'] == 'symbol');

    expect(labels, isNotEmpty);
    for (final layer in labels) {
      final fonts = (layer['layout'] as Map)['text-font'] as List<dynamic>;
      expect(served.containsAll(fonts.cast<String>()), isTrue);
    }
  });

  test('no usa íconos: en el mapa sólo resaltan nuestras paradas', () {
    final withIcons = layers.where(
      (layer) =>
          (layer['layout'] as Map<String, dynamic>?)?.containsKey(
            'icon-image',
          ) ??
          false,
    );

    expect(withIcons, isEmpty);
    expect(style.containsKey('sprite'), isFalse);
  });

  test('los niveles de zoom se corren 1 para los tiles de 512 px', () {
    // Con el zoom de la app, las calles menores aparecían en 12.
    expect(layerById('highway_minor')['minzoom'], 11);
    expect(layerById('building')['minzoom'], 12);
    expect(layerById('place_country')['maxzoom'], 7);

    final width =
        (layerById('highway_minor')['paint'] as Map)['line-width']
            as List<dynamic>;
    // ['interpolate', ['exponential', 1.5], ['zoom'], 11, 0.5, 19, 20]
    expect(width.sublist(3), [11, 0.5, 19, 20]);
  });

  group('recorrido y precisión', () {
    test('van sobre todas las calles y etiquetas', () {
      final ids = [for (final layer in layers) layer['id']];
      final lastStreet = layers.lastIndexWhere(
        (layer) => layer['source'] == KPlanMapStyle.source,
      );

      expect(ids.indexOf('accuracy-fill'), greaterThan(lastStreet));
      expect(ids.indexOf('route-skipped'), greaterThan(lastStreet));
      // El círculo queda debajo de las líneas.
      expect(
        ids.indexOf('accuracy-outline'),
        lessThan(ids.indexOf('route-skipped')),
      );
    });

    test('las fuentes GeoJSON nacen vacías', () {
      for (final id in [
        KPlanMapStyle.routeSource,
        KPlanMapStyle.accuracySource,
      ]) {
        final source = sources[id] as Map<String, dynamic>;
        expect(source['type'], 'geojson');
        expect(source['data'], {
          'type': 'FeatureCollection',
          'features': <Object>[],
        });
      }
    });

    test('las líneas van de lo menos a lo más importante', () {
      expect(idsFrom(KPlanMapStyle.routeSource), [
        'route-skipped',
        'route-preview',
        'route-upcoming-casing',
        'route-upcoming',
        'route-done-casing',
        'route-done',
        'route-current',
      ]);
    });

    test('cada estilo de tramo tiene su capa y la filtra por su nombre', () {
      for (final segment in RouteSegmentStyle.values) {
        final layer = layerById('route-${segment.name}');
        expect(layer['filter'], [
          '==',
          ['get', KPlanMapStyle.segmentProperty],
          segment.name,
        ]);
      }
    });

    test('el borde es una línea más gruesa del color de las calles', () {
      for (final segment in [
        RouteSegmentStyle.done,
        RouteSegmentStyle.upcoming,
      ]) {
        final casing =
            layerById('route-${segment.name}-casing')['paint'] as Map;
        final line = layerById('route-${segment.name}')['paint'] as Map;

        expect(casing['line-color'], '#fffcf3');
        expect(casing['line-width'] as num, (line['line-width'] as num) + 1.5);
      }
    });

    test('las rayas se miden en múltiplos del ancho', () {
      final skipped = layerById('route-skipped')['paint'] as Map;
      final preview = layerById('route-preview')['paint'] as Map;
      final current = layerById('route-current')['paint'] as Map;

      // 8 y 7 px de raya y espacio en una línea de 3 px.
      expect(skipped['line-dasharray'], [8 / 3, 7 / 3]);
      expect(preview['line-dasharray'], [3, 2]);
      // Puntos: rayas de largo cero, redondas.
      expect(current['line-dasharray'], [0, 1.9]);
      expect(
        (layerById('route-current')['layout'] as Map)['line-cap'],
        'round',
      );
    });

    test('el círculo de precisión usa el color del usuario', () {
      final fill = layerById('accuracy-fill')['paint'] as Map;
      final color = AppColors.userLocation.toARGB32() & 0xFFFFFF;

      expect(fill['fill-color'], '#${color.toRadixString(16).padLeft(6, '0')}');
      expect(fill['fill-opacity'], 0.14);
    });
  });
}
