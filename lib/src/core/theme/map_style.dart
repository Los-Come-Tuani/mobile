import 'dart:convert';
import 'dart:ui';

import '../../data/models/route_map.dart';
import 'app_colors.dart';

/// Estilo del mapa de K'Plan, en el formato que lee MapLibre Native.
///
/// Las calles siguen las capas del estilo Positron de OpenFreeMap (esquema
/// OpenMapTiles, datos de OpenStreetMap), pintadas con la paleta de la app. No
/// trae íconos de lugares ni escudos de carreteras: en el mapa sólo resaltan
/// nuestras paradas.
///
/// Encima de las calles van el círculo de precisión del GPS y las líneas del
/// recorrido. Son capas de dos fuentes GeoJSON que nacen vacías y la app
/// actualiza con el recorrido y la ubicación de cada momento.
abstract final class KPlanMapStyle {
  /// Fuente de las calles en el estilo.
  static const String source = 'openmaptiles';

  /// Fuente GeoJSON con los tramos del recorrido (líneas). Cada tramo lleva en
  /// [segmentProperty] el nombre de su [RouteSegmentStyle].
  static const String routeSource = 'kplan-route';

  /// Fuente GeoJSON con el círculo de precisión del GPS (un polígono).
  static const String accuracySource = 'kplan-accuracy';

  /// Propiedad de cada tramo con el nombre de su [RouteSegmentStyle].
  static const String segmentProperty = 'style';

  /// TileJSON de OpenFreeMap. MapLibre lo lee solo: la URL de los tiles cambia
  /// con cada actualización semanal del planeta.
  static const String tilesUrl = 'https://tiles.openfreemap.org/planet';

  /// Glifos de las etiquetas. OpenFreeMap sólo sirve las familias de abajo.
  static const String glyphsUrl =
      'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf';

  static const String regularFont = 'Noto Sans Regular';
  static const String boldFont = 'Noto Sans Bold';
  static const String italicFont = 'Noto Sans Italic';

  /// MapLibre cuenta el zoom sobre tiles de 512 px; flutter_map, sobre tiles de
  /// 256 px. A la misma escala el zoom de MapLibre es 1 menos. Los niveles de
  /// abajo se escribieron con el zoom que mostraba la app, así que se restan
  /// aquí para que calles, edificios y etiquetas aparezcan a la misma escala.
  static const double zoomShift = 1;

  /// El estilo ya serializado, listo para dárselo a MapLibre.
  static final String json = jsonEncode(build());

  /// El estilo como mapa. Las capas de calles van primero, luego el círculo de
  /// precisión y al final el recorrido.
  static Map<String, dynamic> build() {
    const minorRoads = ['minor', 'service', 'track'];
    const majorRoads = ['primary', 'secondary', 'tertiary', 'trunk'];

    return {
      'version': 8,
      'id': 'kplan',
      'name': "K'Plan",
      'glyphs': glyphsUrl,
      'sources': {
        source: {'type': 'vector', 'url': tilesUrl},
        routeSource: _emptyGeoJson,
        accuracySource: _emptyGeoJson,
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
        ..._accuracyLayers(),
        for (final segment in _routeOrder) ..._routeLayersOf(segment),
      ],
    };
  }

  // ── Recorrido y precisión ─────────────────────────────────────────────────

  static const Map<String, Object> _emptyGeoJson = {
    'type': 'geojson',
    'data': {'type': 'FeatureCollection', 'features': <Object>[]},
  };

  /// De abajo hacia arriba, como se dibujaban las líneas: el tramo hacia la
  /// siguiente parada sobre lo recorrido, y eso sobre lo que falta.
  static const List<RouteSegmentStyle> _routeOrder = [
    RouteSegmentStyle.skipped,
    RouteSegmentStyle.preview,
    RouteSegmentStyle.upcoming,
    RouteSegmentStyle.done,
    RouteSegmentStyle.current,
  ];

  /// Lo que el borde suma al ancho de la línea (el borde se pinta como una
  /// línea más gruesa debajo, del color de las calles).
  static const double _routeBorder = 1.5;

  /// El círculo de precisión, debajo de las líneas: relleno tenue y aro fino.
  static List<Map<String, dynamic>> _accuracyLayers() => [
    {
      'id': 'accuracy-fill',
      'type': 'fill',
      'source': accuracySource,
      'paint': {
        'fill-color': _hex(AppColors.userLocation),
        'fill-opacity': 0.14,
      },
    },
    {
      'id': 'accuracy-outline',
      'type': 'line',
      'source': accuracySource,
      'paint': {
        'line-color': _hex(AppColors.userLocation),
        'line-opacity': 0.4,
        'line-width': 1,
      },
    },
  ];

  static List<Map<String, dynamic>> _routeLayersOf(RouteSegmentStyle segment) =>
      switch (segment) {
        RouteSegmentStyle.skipped => [
          _routeLine(
            segment,
            color: AppColors.routeSkipped,
            width: 3,
            dash: _dashed(const [8, 7], width: 3),
          ),
        ],
        RouteSegmentStyle.preview => [
          _routeLine(
            segment,
            color: AppColors.routeDone,
            width: 4,
            dash: _dashed(const [12, 8], width: 4),
          ),
        ],
        RouteSegmentStyle.upcoming => [
          _routeLine(
            segment,
            color: AppColors.mapRoad,
            width: 4.5 + _routeBorder,
            isCasing: true,
          ),
          _routeLine(segment, color: AppColors.routeUpcoming, width: 4.5),
        ],
        RouteSegmentStyle.done => [
          _routeLine(
            segment,
            color: AppColors.mapRoad,
            width: 5 + _routeBorder,
            isCasing: true,
          ),
          _routeLine(segment, color: AppColors.routeDone, width: 5),
        ],
        // Puntos redondos: rayas de largo cero con extremos redondos, separados
        // 1.9 veces el ancho.
        RouteSegmentStyle.current => [
          _routeLine(
            segment,
            color: AppColors.routeCurrent,
            width: 6,
            dash: const [0, 1.9],
          ),
        ],
      };

  /// MapLibre mide las rayas en múltiplos del ancho de la línea, no en
  /// píxeles.
  static List<double> _dashed(List<double> pixels, {required double width}) => [
    for (final length in pixels) length / width,
  ];

  static Map<String, dynamic> _routeLine(
    RouteSegmentStyle segment, {
    required Color color,
    required double width,
    List<num>? dash,
    bool isCasing = false,
  }) => {
    'id': 'route-${segment.name}${isCasing ? '-casing' : ''}',
    'type': 'line',
    'source': routeSource,
    'filter': [
      '==',
      ['get', segmentProperty],
      segment.name,
    ],
    'layout': {'line-cap': 'round', 'line-join': 'round'},
    'paint': {
      'line-color': _hex(color),
      'line-width': width,
      'line-dasharray': ?dash,
    },
  };

  // ── Piezas del estilo ─────────────────────────────────────────────────────

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
  /// [toZoom] (con el zoom de la app: [zoomShift] los acomoda a MapLibre).
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
    fromZoom - zoomShift,
    from,
    toZoom - zoomShift,
    to,
  ];

  static double? _shift(double? zoom) => zoom == null ? null : zoom - zoomShift;

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
    'minzoom': ?_shift(minzoom),
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
    'minzoom': ?_shift(minzoom),
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
    required String font,
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
    'minzoom': ?_shift(minzoom),
    'maxzoom': ?_shift(maxzoom),
    'filter': ?filter,
    'layout': {
      'text-field': _name,
      'text-size': size,
      'text-font': [font],
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
