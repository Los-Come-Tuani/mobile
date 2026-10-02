import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/utils/formatters.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/core/utils/time_parser.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/tour_repository.dart';

/// Campos de texto que cambian de un idioma a otro, por archivo.
///
/// Todo lo demás (ids, claves lógicas como categorías o ciudades, nombres
/// propios, fotos, horas) tiene que ser idéntico: la lógica de la app busca
/// por esos valores, no por lo que se ve en pantalla.
const _translated = <String, Set<String>>{
  'circuits.json': {
    'shortTitle',
    'title',
    'subtitle',
    'durationShort',
    'difficulty',
    'description',
    'recommendations',
    'meetingPoint',
    'includes',
    'badgesNote',
    'notes',
    'timeAgo',
    'text',
    'organizer',
  },
  'circuit_groups.json': {'note'},
  'coupons.json': {'title', 'description', 'discountLabel'},
  'events.json': {'title', 'dateLabel', 'description'},
  'guides.json': {'bio', 'specialties', 'timeAgo', 'text'},
  'guide_jobs.json': {'circuitTitle'},
  'guide_trips.json': {'circuitTitle', 'meetingPoint', 'text'},
  'places.json': <String>{},
  'stops.json': {'name', 'address', 'description', 'tip'},
  'tourists.json': {'country', 'timeAgo', 'text'},
};

/// Subconjunto de [_translated] que en inglés nunca puede quedar igual al
/// español (los demás pueden ser nombres propios o reseñas ya escritas en
/// inglés).
const _alwaysTranslated = <String, Set<String>>{
  'circuits.json': {
    'title',
    'subtitle',
    'durationShort',
    'difficulty',
    'description',
    'recommendations',
    'includes',
    'badgesNote',
    'notes',
    'timeAgo',
    'text',
    'organizer',
  },
  'circuit_groups.json': {'note'},
  'coupons.json': {'title', 'description', 'discountLabel'},
  'events.json': {'dateLabel', 'description'},
  'guides.json': {'bio', 'specialties', 'timeAgo'},
  'guide_trips.json': {'circuitTitle'},
  'stops.json': {'description', 'tip'},
  'tourists.json': {'timeAgo', 'text'},
};

/// Campos que guardan una hora (`8:30 a.m.`) y que la app muestra con
/// `Formatters.timeText`.
const _timeKeys = {'startTimes', 'startTime', 'opensAt', 'closesAt'};

Object? _read(String path) => jsonDecode(File(path).readAsStringSync());

/// Compara [es] con [en] y devuelve los problemas encontrados.
///
/// Las hojas de texto sólo pueden diferir si su campo está en [translated].
List<String> _compare(
  Object? es,
  Object? en,
  String where,
  Set<String> translated, {
  String key = '',
}) {
  if (es is List && en is List) {
    if (es.length != en.length) {
      return ['$where: ${es.length} elementos en es y ${en.length} en en'];
    }
    return [
      for (var i = 0; i < es.length; i++)
        ..._compare(es[i], en[i], '$where[$i]', translated, key: key),
    ];
  }
  if (es is Map && en is Map) {
    final missing = es.keys.toSet().difference(en.keys.toSet());
    final extra = en.keys.toSet().difference(es.keys.toSet());
    if (missing.isNotEmpty || extra.isNotEmpty) {
      return ['$where: faltan $missing, sobran $extra'];
    }
    return [
      for (final k in es.keys)
        ..._compare(es[k], en[k], '$where.$k', translated, key: '$k'),
    ];
  }
  if (es.runtimeType != en.runtimeType) {
    return ['$where: ${es.runtimeType} en es y ${en.runtimeType} en en'];
  }
  if (es is String && translated.contains(key)) return const [];
  return es == en ? const [] : ['$where: "$es" en es y "$en" en en'];
}

/// Los textos que están bajo [keys] en cualquier nivel del documento.
Iterable<(String, String, String)> _leavesUnder(
  Object? es,
  Object? en,
  Set<String> keys,
  String where, {
  String key = '',
}) sync* {
  if (es is List && en is List) {
    for (var i = 0; i < es.length; i++) {
      yield* _leavesUnder(es[i], en[i], keys, '$where[$i]', key: key);
    }
  } else if (es is Map && en is Map) {
    for (final k in es.keys) {
      yield* _leavesUnder(es[k], en[k], keys, '$where.$k', key: '$k');
    }
  } else if (es is String && en is String && keys.contains(key)) {
    yield (where, es, en);
  }
}

Iterable<String> _timesIn(Object? node, {String key = ''}) sync* {
  if (node is List) {
    for (final item in node) {
      yield* _timesIn(item, key: key);
    }
  } else if (node is Map) {
    for (final entry in node.entries) {
      yield* _timesIn(entry.value, key: '${entry.key}');
    }
  } else if (node is String && _timeKeys.contains(key)) {
    yield node;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppStrings.use(AppLanguage.es));

  group('Archivos del catálogo', () {
    final files =
        Directory('assets/mock')
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((name) => name.endsWith('.json'))
            .toList()
          ..sort();

    test(
      'cada archivo en español tiene su versión en inglés y está declarado',
      () {
        expect(files, isNotEmpty);
        expect(
          _translated.keys.toSet(),
          files.toSet(),
          reason:
              'Un archivo nuevo se agrega aquí con los campos que se '
              'traducen, y su copia va en assets/mock/en/',
        );
        for (final name in files) {
          expect(
            File('assets/mock/en/$name').existsSync(),
            isTrue,
            reason: 'Falta assets/mock/en/$name',
          );
        }
      },
    );

    for (final name in _translated.keys) {
      group(name, () {
        final es = _read('assets/mock/$name');
        final en = _read('assets/mock/en/$name');

        test('misma estructura; sólo cambian los campos traducibles', () {
          expect(_compare(es, en, name, _translated[name]!), isEmpty);
        });

        test('los campos que siempre se traducen no quedaron en español', () {
          final keys = _alwaysTranslated[name] ?? const <String>{};
          final untouched = [
            for (final (where, spanish, english) in _leavesUnder(
              es,
              en,
              keys,
              name,
            ))
              if (spanish == english) '$where: "$spanish"',
          ];
          expect(untouched, isEmpty);
        });

        test('toda hora se puede leer y mostrar en los dos idiomas', () {
          for (final time in _timesIn(es)) {
            final minutes = TimeParser.minutesOfDay(time);
            expect(minutes, isNotNull, reason: 'Hora ilegible: "$time"');
            AppStrings.use(AppLanguage.en);
            expect(
              Formatters.timeText(time),
              Formatters.minutesOfDay(minutes!),
            );
            AppStrings.use(AppLanguage.es);
            expect(Formatters.timeText(time), time);
          }
        });
      });
    }
  });

  group('TourRepository según el idioma de la app', () {
    late TourRepository repository;

    setUp(() => repository = TourRepository());

    Future<T> ok<T>(Future<Result<T>> pending) async {
      final result = await pending;
      expect(result, isA<Ok<T>>());
      return (result as Ok<T>).value;
    }

    test('en español devuelve el catálogo original', () async {
      final circuits = await ok(repository.getCircuits());
      final granada = circuits.firstWhere(
        (circuit) => circuit.id == 'granada-historias-sabores',
      );

      expect(granada.title, 'Granada, entre historias y sabores');
      expect(granada.difficulty, 'Fácil');
    });

    test(
      'en inglés devuelve el catálogo traducido con los mismos ids',
      () async {
        final spanish = await ok(repository.getCircuits());
        final spanishStops = await ok(repository.getStops());

        AppStrings.use(AppLanguage.en);
        final english = await ok(repository.getCircuits());
        final englishStops = await ok(repository.getStops());

        expect(
          english.map((circuit) => circuit.id),
          spanish.map((circuit) => circuit.id),
        );
        expect(
          english.firstWhere((c) => c.id == 'granada-historias-sabores').title,
          'Granada, stories and flavors',
        );
        expect(
          englishStops.map((stop) => stop.id),
          spanishStops.map((stop) => stop.id),
        );

        // Lo que la lógica compara o calcula no cambia con el idioma.
        for (var i = 0; i < english.length; i++) {
          expect(english[i].category, spanish[i].category);
          expect(english[i].city, spanish[i].city);
          expect(english[i].stopIds, spanish[i].stopIds);
          expect(english[i].startTimes, spanish[i].startTimes);
          expect(english[i].travelMode, spanish[i].travelMode);
        }
        for (var i = 0; i < englishStops.length; i++) {
          expect(englishStops[i].category, spanishStops[i].category);
          expect(
            englishStops[i].hours?.opensAt,
            spanishStops[i].hours?.opensAt,
          );
          expect(
            englishStops[i].hours?.closesAt,
            spanishStops[i].hours?.closesAt,
          );
        }
      },
    );

    test('cambiar de idioma no mezcla los textos de uno y otro', () async {
      Future<String> title() async {
        final circuit = await ok(repository.getCircuitById('leon-colonial'));
        return circuit.title;
      }

      expect(await title(), 'León, cuna de poetas y volcanes');
      AppStrings.use(AppLanguage.en);
      expect(await title(), 'León, cradle of poets and volcanoes');
      AppStrings.use(AppLanguage.es);
      expect(await title(), 'León, cuna de poetas y volcanes');
    });

    test('lugares, eventos y cupones también salen en inglés', () async {
      AppStrings.use(AppLanguage.en);

      final events = await ok(repository.getUpcomingEvents());
      final coupons = await ok(repository.getCoupons());

      expect(events, isNotEmpty);
      expect(coupons.first.title, "K'Plan welcome kit");
      expect(coupons.first.discountLabel, 'Gift');
    });
  });
}
