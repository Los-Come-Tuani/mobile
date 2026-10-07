import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/map_style.dart';

void main() {
  final style = KPlanMapStyle.build();
  final layers = (style['layers'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  Map<String, dynamic> section(Map<String, dynamic> layer, String key) =>
      layer[key] as Map<String, dynamic>? ?? const {};

  test('el JSON que recibe MapLibre es el mismo estilo', () {
    expect(jsonDecode(KPlanMapStyle.json), style);
    expect(style['version'], 8);
  });

  test('sólo pide tiles a OpenFreeMap, sin API key', () {
    final sources = style['sources'] as Map<String, dynamic>;

    expect(sources.keys, [KPlanMapStyle.source]);
    expect(
      (sources[KPlanMapStyle.source] as Map)['url'],
      'https://tiles.openfreemap.org/planet',
    );
    for (final layer in layers.skip(1)) {
      expect(layer['source'], KPlanMapStyle.source, reason: '${layer['id']}');
    }
  });

  test('las etiquetas usan fuentes que sirve OpenFreeMap', () {
    const served = {
      KPlanMapStyle.regularFont,
      KPlanMapStyle.boldFont,
      KPlanMapStyle.italicFont,
    };
    final labels = layers.where((layer) => layer['type'] == 'symbol');

    expect(style['glyphs'], startsWith('https://tiles.openfreemap.org/fonts/'));
    expect(labels, isNotEmpty);
    for (final label in labels) {
      expect(
        section(label, 'layout')['text-font'],
        everyElement(isIn(served)),
        reason: '${label['id']}',
      );
    }
  });

  test('no usa íconos: en el mapa sólo resaltan nuestras paradas', () {
    final withIcons = layers.where(
      (layer) => section(layer, 'layout').containsKey('icon-image'),
    );

    expect(style.containsKey('sprite'), isFalse);
    expect(withIcons, isEmpty);
  });

  test('cada capa tiene un id distinto', () {
    final ids = [for (final layer in layers) layer['id']];

    expect(ids.toSet(), hasLength(ids.length));
  });
}
