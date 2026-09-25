import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Estilo de las calles del mapa de K'Plan.
///
/// Sigue las capas del estilo Positron de OpenFreeMap (esquema OpenMapTiles),
/// pintadas con la paleta de la app. No trae íconos de lugares ni escudos de
/// carreteras: en el mapa sólo resaltan nuestras paradas.
abstract final class KPlanMapStyle {
  /// Fuente de los tiles en el estilo: la llave de `TileProviders`.
  static const String source = 'openmaptiles';

  /// Súbelo al cambiar el estilo: invalida los tiles ya pintados en caché.
  static const String version = '1';

  static vtr.Theme? _theme;

  /// El estilo ya leído, con las etiquetas en Poppins como el resto de la app.
  static vtr.Theme get theme => _theme ??= vtr.ThemeReader().read(
    build(
      regularFont: AppTextStyles.mapLabel.fontFamily,
      boldFont: AppTextStyles.mapPlace.fontFamily,
      italicFont: AppTextStyles.mapWater.fontFamily,
    ),
  );

  /// El estilo en formato MapLibre. Sin fuentes, las etiquetas usan la del
  /// sistema.
  static Map<String, dynamic> build({
    String? regularFont,
    String? boldFont,
    String? italicFont,
  }) {
    const minorRoads = ['minor', 'service', 'track'];
    const majorRoads = ['primary', 'secondary', 'tertiary', 'trunk'];

    return {
      'version': 8,
      'id': 'kplan',
      'name': "K'Plan",
      'metadata': {'version': version},
      'sources': {
        source: {
          'type': 'vector',
          'url': 'https://tiles.openfreemap.org/planet',
        },
      },
      'layers': [
        {
          'id': 'background',
          'type': 'background',
          'paint': {'background-color': _hex(AppColors.mapLand)},
        },
        _fill(
          'landcover_grass',
          'landcover',
          filter: ['all', _polygons, _classIs('grass')],
          color: AppColors.mapPark,
          opacity: 0.55,
          minzoom: 9,
        ),
        _fill(
          'landcover_wood',
          'landcover',
          filter: ['all', _polygons, _classIs('wood')],
          color: AppColors.mapWood,
          opacity: _ramp(8, 0.3, 12, 0.85),
        ),
        _fill(
          'park',
          'park',
          filter: _polygons,
          color: AppColors.mapPark,
          opacity: 0.85,
        ),
        _fill(
          'landuse_residential',
          'landuse',
          filter: ['all', _polygons, _classIs('residential')],
          color: AppColors.mapBlock,
          opacity: 0.8,
        ),
        _fill(
          'water',
          'water',
          filter: [
            'all',
            _polygons,
            [
              '!=',
              ['get', 'brunnel'],
              'tunnel',
            ],
          ],
          color: AppColors.mapWater,
          outline: AppColors.mapWaterEdge,
        ),
        _line(
          'waterway',
          'waterway',
          filter: _lines,
          color: AppColors.mapWaterEdge,
          width: _ramp(8, 0.6, 20, 6, base: 1.3),
        ),
        _fill(
          'building',
          'building',
          color: AppColors.mapBuilding,
          outline: AppColors.mapBuildingOutline,
          minzoom: 13,
        ),
        _line(
          'highway_path',
          'transportation',
          filter: ['all', _lines, _classIs('path')],
          color: AppColors.mapRoadCasing,
          width: _ramp(14, 1, 20, 3),
          dash: const [3, 2],
          minzoom: 14,
        ),
        _line(
          'highway_minor_casing',
          'transportation',
          filter: ['all', _lines, _classIn(minorRoads)],
          color: AppColors.mapRoadCasing,
          width: _ramp(12, 1.2, 20, 24, base: 1.5),
          minzoom: 12,
        ),
        _line(
          'highway_minor',
          'transportation',
          filter: ['all', _lines, _classIn(minorRoads)],
          color: AppColors.mapRoad,
          width: _ramp(12, 0.5, 20, 20, base: 1.5),
          minzoom: 12,
        ),
        _line(
          'highway_major_casing',
          'transportation',
          filter: ['all', _lines, _classIn(majorRoads)],
          color: AppColors.mapRoadCasing,
          width: _ramp(9, 1.6, 20, 28, base: 1.4),
          minzoom: 9,
        ),
        _line(
          'highway_major',
          'transportation',
          filter: ['all', _lines, _classIn(majorRoads)],
          color: AppColors.mapRoad,
          width: _ramp(9, 0.8, 20, 24, base: 1.4),
          minzoom: 9,
        ),
        _line(
          'highway_motorway_casing',
          'transportation',
          filter: ['all', _lines, _classIs('motorway')],
          color: AppColors.outline,
          width: _ramp(5, 1, 20, 34, base: 1.4),
          minzoom: 5,
        ),
        _line(
          'highway_motorway',
          'transportation',
          filter: ['all', _lines, _classIs('motorway')],
          color: AppColors.mapRoad,
          width: _ramp(5, 0.5, 20, 30, base: 1.4),
          minzoom: 5,
        ),
        _line(
          'railway',
          'transportation',
          filter: ['all', _lines, _classIs('rail')],
          color: AppColors.outline,
          width: 1.2,
          dash: const [4, 3],
          minzoom: 12,
        ),
        _line(
          'boundary_country',
          'boundary',
          filter: [
            'all',
            [
              '==',
              ['get', 'admin_level'],
              2,
            ],
            [
              '!=',
              ['get', 'maritime'],
              1,
            ],
          ],
          color: AppColors.hintText,
          width: _ramp(3, 0.8, 10, 1.6),
          opacity: 0.7,
          dash: const [4, 3],
        ),
        _label(
          'water_name_line',
          'water_name',
          filter: _lines,
          color: AppColors.mapWaterLabel,
          size: 12,
          font: italicFont,
          alongLine: true,
        ),
        _label(
          'water_name_point',
          'water_name',
          filter: _points,
          color: AppColors.mapWaterLabel,
          size: _ramp(6, 11, 12, 15),
          font: italicFont,
          maxWidth: 6,
        ),
        _label(
          'waterway_name',
          'waterway',
          filter: _lines,
          color: AppColors.mapWaterLabel,
          size: 11,
          font: italicFont,
          alongLine: true,
          minzoom: 13,
        ),
        _label(
          'highway_name_minor',
          'transportation_name',
          filter: ['all', _lines, _classIn(minorRoads)],
          color: AppColors.mapLabel,
          size: 11,
          font: regularFont,
          alongLine: true,
          minzoom: 15,
        ),
        _label(
          'highway_name_major',
          'transportation_name',
          filter: ['all', _lines, _classIn(majorRoads)],
          color: AppColors.mapLabel,
          size: 12,
          font: regularFont,
          alongLine: true,
          minzoom: 13,
        ),
        _label(
          'place_neighbourhood',
          'place',
          filter: _classIn(const ['suburb', 'quarter', 'neighbourhood']),
          color: AppColors.mapLabel,
          size: 10,
          font: regularFont,
          uppercase: true,
          maxWidth: 8,
          minzoom: 12,
        ),
        _label(
          'place_village',
          'place',
          filter: _classIn(const ['village', 'hamlet']),
          color: AppColors.primaryText,
          size: 12,
          font: regularFont,
          maxWidth: 8,
          minzoom: 10,
        ),
        _label(
          'place_town',
          'place',
          filter: _classIs('town'),
          color: AppColors.primaryText,
          size: _ramp(8, 12, 14, 15),
          font: boldFont,
          maxWidth: 8,
          minzoom: 8,
        ),
        _label(
          'place_city',
          'place',
          filter: _classIs('city'),
          color: AppColors.primaryText,
          size: _ramp(5, 12, 12, 18),
          font: boldFont,
          maxWidth: 8,
          minzoom: 5,
        ),
        _label(
          'place_country',
          'place',
          filter: _classIs('country'),
          color: AppColors.primaryText,
          size: 13,
          font: boldFont,
          uppercase: true,
          maxzoom: 8,
        ),
      ],
    };
  }

  static const List<Object> _polygons = [
    'match',
    ['geometry-type'],
    ['MultiPolygon', 'Polygon'],
    true,
    false,
  ];

  static const List<Object> _lines = [
    'match',
    ['geometry-type'],
    ['LineString', 'MultiLineString'],
    true,
    false,
  ];

  static const List<Object> _points = [
    'match',
    ['geometry-type'],
    ['Point', 'MultiPoint'],
    true,
    false,
  ];

  /// El nombre en español si el dato lo trae.
  static const List<Object> _name = [
    'coalesce',
    ['get', 'name:es'],
    ['get', 'name'],
  ];

  static List<Object> _classIs(String value) => [
    '==',
    ['get', 'class'],
    value,
  ];

  static List<Object> _classIn(List<String> values) => [
    'match',
    ['get', 'class'],
    values,
    true,
    false,
  ];

  /// Un valor que crece con el zoom, de [from] en [fromZoom] a [to] en
  /// [toZoom].
  static List<Object> _ramp(
    double fromZoom,
    num from,
    double toZoom,
    num to, {
    double base = 1,
  }) => [
    'interpolate',
    if (base == 1) ['linear'] else ['exponential', base],
    ['zoom'],
    fromZoom,
    from,
    toZoom,
    to,
  ];

  static Map<String, dynamic> _fill(
    String id,
    String sourceLayer, {
    Object? filter,
    required Color color,
    Object? opacity,
    Color? outline,
    double? minzoom,
  }) => {
    'id': id,
    'type': 'fill',
    'source': source,
    'source-layer': sourceLayer,
    'minzoom': ?minzoom,
    'filter': ?filter,
    'paint': {
      'fill-color': _hex(color),
      'fill-opacity': ?opacity,
      if (outline != null) 'fill-outline-color': _hex(outline),
    },
  };

  static Map<String, dynamic> _line(
    String id,
    String sourceLayer, {
    Object? filter,
    required Color color,
    required Object width,
    Object? opacity,
    List<num>? dash,
    double? minzoom,
  }) => {
    'id': id,
    'type': 'line',
    'source': source,
    'source-layer': sourceLayer,
    'minzoom': ?minzoom,
    'filter': ?filter,
    'layout': {'line-cap': 'round', 'line-join': 'round'},
    'paint': {
      'line-color': _hex(color),
      'line-width': width,
      'line-opacity': ?opacity,
      'line-dasharray': ?dash,
    },
  };

  static Map<String, dynamic> _label(
    String id,
    String sourceLayer, {
    Object? filter,
    required Color color,
    required Object size,
    String? font,
    bool alongLine = false,
    bool uppercase = false,
    double? maxWidth,
    double? minzoom,
    double? maxzoom,
  }) => {
    'id': id,
    'type': 'symbol',
    'source': source,
    'source-layer': sourceLayer,
    'minzoom': ?minzoom,
    'maxzoom': ?maxzoom,
    'filter': ?filter,
    'layout': {
      'text-field': _name,
      'text-size': size,
      if (font != null) 'text-font': [font],
      if (alongLine) ...{
        'symbol-placement': 'line',
        'text-rotation-alignment': 'map',
      },
      if (uppercase) ...{
        'text-transform': 'uppercase',
        'text-letter-spacing': 0.1,
      },
      'text-max-width': ?maxWidth,
    },
    'paint': {
      'text-color': _hex(color),
      'text-halo-color': _hex(AppColors.mapLabelHalo),
      'text-halo-width': 1.4,
    },
  };

  /// `#rrggbb`: el formato de color que entiende el estilo.
  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
