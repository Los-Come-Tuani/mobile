import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/map_style.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  final style = KPlanMapStyle.build(
    regularFont: 'Poppins_regular',
    boldFont: 'Poppins_600',
    italicFont: 'Poppins_italic',
  );
  final layers = style['layers'] as List<dynamic>;

  test('el estilo se lee completo, sin red', () {
    final theme = ThemeReader().read(style);

    expect(theme.id, 'kplan');
    expect(theme.version, KPlanMapStyle.version);
    // Ninguna capa se descarta por no entenderse.
    expect(theme.layers, hasLength(layers.length));
  });

  test('sólo pide tiles a la fuente de OpenFreeMap', () {
    expect(ThemeReader().read(style).tileSources, {KPlanMapStyle.source});
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
  });
}
