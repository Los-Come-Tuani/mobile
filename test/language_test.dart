import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/core/utils/formatters.dart';
import 'package:k_plan_mobile/src/core/utils/validators.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/language_repository.dart';
import 'package:k_plan_mobile/src/ui/core/base_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Probe extends BaseViewModel {}

/// Los nombres de variable de un mensaje ICU (simple, plural o select).
Set<String> _arguments(String text) {
  final names = <String>{};

  int skipSpaces(int j) {
    while (j < text.length && text[j].trim().isEmpty) {
      j++;
    }
    return j;
  }

  (String, int) word(int j) {
    final start = j;
    while (j < text.length && RegExp(r'\w').hasMatch(text[j])) {
      j++;
    }
    return (text.substring(start, j), j);
  }

  late int Function(int) argument;

  int body(int i, {required bool insideCase}) {
    while (i < text.length) {
      final c = text[i];
      if (c == '}') {
        if (insideCase) return i;
        i++;
      } else if (c == '{') {
        i = argument(i);
      } else {
        i++;
      }
    }
    return i;
  }

  argument = (int i) {
    var j = skipSpaces(i + 1);
    final (name, afterName) = word(j);
    j = skipSpaces(afterName);
    names.add(name);
    if (text[j] == '}') return j + 1;
    j = skipSpaces(j + 1);
    final (type, afterType) = word(j);
    j = skipSpaces(afterType);
    if (text[j] == '}') return j + 1;
    j++;
    if (const {'plural', 'select', 'selectordinal'}.contains(type)) {
      for (;;) {
        j = skipSpaces(j);
        if (text[j] == '}') return j + 1;
        while (text[j] != '{' && text[j] != '}') {
          j++;
        }
        j = body(j + 1, insideCase: true) + 1;
      }
    }
    while (text[j] != '}') {
      j++;
    }
    return j + 1;
  };

  body(0, insideCase: false);
  return names;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStrings.use(AppLanguage.es);
  });
  tearDown(() => AppStrings.use(AppLanguage.es));

  group('LanguageRepository', () {
    test(
      'arranca en español y con la pregunta del login sin contestar',
      () async {
        final repository = await LanguageRepository.load();

        expect(repository.language, AppLanguage.es);
        expect(repository.hasChosen, isFalse);
        expect(AppStrings.language, AppLanguage.es);
      },
    );

    test('elegir cambia toda la app al instante y se recuerda', () async {
      final repository = await LanguageRepository.load();
      var notified = 0;
      repository.addListener(() => notified++);

      await repository.choose(AppLanguage.en);

      expect(repository.language, AppLanguage.en);
      expect(repository.hasChosen, isTrue);
      expect(repository.locale, AppLanguage.en.locale);
      expect(AppStrings.language, AppLanguage.en);
      expect(AppStrings.current.commonBack, 'Back');
      expect(notified, 1);

      // La próxima vez que se abre la app ya no se pregunta.
      final next = await LanguageRepository.load();
      expect(next.language, AppLanguage.en);
      expect(next.hasChosen, isTrue);
    });

    test('elegir español también contesta la pregunta', () async {
      final repository = await LanguageRepository.load();

      await repository.choose(AppLanguage.es);

      expect(repository.hasChosen, isTrue);
      expect((await LanguageRepository.load()).hasChosen, isTrue);
    });

    test(
      'un valor guardado que no se conoce vuelve a español sin elegir',
      () async {
        SharedPreferences.setMockInitialValues({'app_language': 'fr'});

        final repository = await LanguageRepository.load();

        expect(repository.language, AppLanguage.es);
        expect(repository.hasChosen, isFalse);
      },
    );

    test('en memoria, con un idioma ya elegido, no pregunta', () {
      final repository = LanguageRepository.memory(chosen: AppLanguage.en);

      expect(repository.language, AppLanguage.en);
      expect(repository.hasChosen, isTrue);
      expect(LanguageRepository.memory().hasChosen, isFalse);
    });
  });

  group('AppStrings', () {
    test('cambia los textos de quien no tiene contexto', () {
      expect(
        AppStrings.current.commonSomethingWentWrong,
        'Algo salió mal, intenta de nuevo',
      );

      AppStrings.use(AppLanguage.en);

      expect(
        AppStrings.current.commonSomethingWentWrong,
        'Something went wrong, try again',
      );
    });

    test('los ViewModels avisan para volver a leer los textos que arman', () {
      final viewModel = _Probe();
      var notified = 0;
      viewModel.addListener(() => notified++);

      AppStrings.use(AppLanguage.en);
      AppStrings.use(AppLanguage.en);

      expect(notified, 1);

      viewModel.dispose();
      // Ya cerrado, no se le avisa (y no falla).
      AppStrings.use(AppLanguage.es);
    });

    test(
      'las categorías y los idiomas del catálogo se traducen al mostrarlos',
      () {
        final es = AppStrings.current;
        expect(es.categoryName('Gastronomía'), 'Gastronomía');

        AppStrings.use(AppLanguage.en);
        final en = AppStrings.current;

        expect(en.categoryName('Gastronomía'), 'Food');
        expect(en.categoryName('Historia'), 'History');
        expect(en.categoryName('Circuitos creativos'), 'Creative circuits');
        expect(en.languageName('Inglés'), 'English');
        expect(en.languageName('Alemán'), 'German');
        // Lo que no se conoce se muestra tal cual.
        expect(en.categoryName('Otra cosa'), 'Otra cosa');
        expect(en.languageName('Quechua'), 'Quechua');
      },
    );
  });

  group('Formatters', () {
    final saturday = DateTime(2026, 10, 3);
    final morning = DateTime(2026, 10, 3, 8, 30);
    final nineAm = DateTime(2026, 10, 3, 9);

    test('en español dan lo de siempre', () {
      expect(Formatters.compactDate(saturday), 'Sáb 3 oct');
      expect(Formatters.weekdayDate(DateTime(2026, 9, 26)), 'Sábado 26 sep');
      expect(Formatters.shortDate(DateTime(2026, 11, 16)), '16 nov 2026');
      expect(Formatters.dayAndMonth(DateTime(2026, 11, 16)), '16 nov');
      expect(Formatters.time(8, 30), '8:30 a.m.');
      expect(Formatters.clock(DateTime(2026, 1, 1, 14, 5)), '2:05 p.m.');
      expect(Formatters.timeRange(morning, nineAm), '8:30 – 9:00 a.m.');
      expect(Formatters.people(1), '1 persona');
      expect(Formatters.people(4), '4 personas');
      expect(
        Formatters.groupLabel(adults: 2, children: 1),
        'adultos x 2, niño x 1',
      );
      expect(Formatters.groupLabel(adults: 0, children: 0), 'Sin personas');
      expect(Formatters.remaining(Duration.zero), 'menos de 1 min');
      expect(Formatters.relativeDay(saturday, now: saturday), 'Hoy');
      expect(
        Formatters.timeAgo(
          saturday,
          now: saturday.add(const Duration(days: 1)),
        ),
        'hace 1 día',
      );
      expect(
        Formatters.timeAgo(
          saturday,
          now: saturday.add(const Duration(days: 3)),
        ),
        'hace 3 días',
      );
      expect(
        Formatters.timeAgo(
          saturday,
          now: saturday.add(const Duration(minutes: 5)),
        ),
        'hace 5 min',
      );
    });

    test('en inglés cambian palabras, orden y sufijo', () {
      AppStrings.use(AppLanguage.en);

      expect(Formatters.compactDate(saturday), 'Sat, Oct 3');
      expect(Formatters.weekdayDate(DateTime(2026, 9, 26)), 'Saturday, Sep 26');
      expect(Formatters.shortDate(DateTime(2026, 11, 16)), 'Nov 16, 2026');
      expect(Formatters.dayAndMonth(DateTime(2026, 11, 16)), 'Nov 16');
      expect(Formatters.time(8, 30), '8:30 AM');
      expect(Formatters.clock(DateTime(2026, 1, 1, 14, 5)), '2:05 PM');
      expect(Formatters.timeRange(morning, nineAm), '8:30 – 9:00 AM');
      expect(
        Formatters.timeRange(
          DateTime(2026, 1, 1, 11, 40),
          DateTime(2026, 1, 1, 12, 10),
        ),
        '11:40 AM – 12:10 PM',
      );
      expect(Formatters.people(1), '1 person');
      expect(Formatters.people(4), '4 people');
      expect(
        Formatters.groupLabel(adults: 2, children: 1),
        '2 adults, 1 child',
      );
      expect(
        Formatters.groupLabel(adults: 1, children: 2),
        '1 adult, 2 children',
      );
      expect(Formatters.groupLabel(adults: 0, children: 0), 'No people');
      expect(Formatters.remaining(Duration.zero), 'less than 1 min');
      expect(Formatters.relativeDay(saturday, now: saturday), 'Today');
      expect(
        Formatters.relativeDay(
          saturday,
          now: saturday.subtract(const Duration(days: 1)),
        ),
        'Tomorrow',
      );
      expect(Formatters.timeAgo(saturday, now: saturday), 'now');
      expect(
        Formatters.timeAgo(
          saturday,
          now: saturday.add(const Duration(days: 1)),
        ),
        '1 day ago',
      );
      expect(
        Formatters.timeAgo(
          saturday,
          now: saturday.add(const Duration(hours: 2)),
        ),
        '2 h ago',
      );
    });

    test('una hora de los datos se muestra en el formato del idioma', () {
      expect(Formatters.timeText('8:30 a.m.'), '8:30 a.m.');
      expect(Formatters.timeText('12:00 p.m.'), '12:00 p.m.');
      expect(Formatters.timeText('no es una hora'), 'no es una hora');

      AppStrings.use(AppLanguage.en);

      expect(Formatters.timeText('8:30 a.m.'), '8:30 AM');
      expect(Formatters.timeText('3:00 p.m.'), '3:00 PM');
      expect(Formatters.timeText('12:00 a.m.'), '12:00 AM');
      // Una hora ya en inglés también se entiende.
      expect(Formatters.timeText('3:00 PM'), '3:00 PM');
      expect(Formatters.timeText('no es una hora'), 'no es una hora');
    });

    test('lo que no depende del idioma es igual en los dos', () {
      for (final language in AppLanguage.values) {
        AppStrings.use(language);
        expect(Formatters.currency(250), 'C\$ 250');
        expect(Formatters.duration(const Duration(minutes: 260)), '4 h 20 min');
        expect(Formatters.distance(0.8), '800 m');
        expect(Formatters.distance(2.24), '2.2 km');
      }
    });
  });

  group('Validators', () {
    test('hablan el idioma de ese momento', () {
      expect(Validators.email(''), 'Ingresa tu correo electrónico');
      expect(Validators.password('123'), 'Mínimo 6 caracteres');
      expect(Validators.phone('12'), 'El teléfono no es válido');

      AppStrings.use(AppLanguage.en);

      expect(Validators.email(''), 'Enter your email');
      expect(Validators.email('no'), 'That email is not valid');
      expect(Validators.password('123'), 'At least 6 characters');
      expect(Validators.password('123', minLength: 8), 'At least 8 characters');
      expect(
        Validators.newPassword('abc'),
        'Use at least 8 characters with letters and numbers',
      );
      expect(Validators.phone('12'), 'That phone number is not valid');
      expect(
        Validators.username('a'),
        '3 to 20 letters, numbers, dots or underscores',
      );
      expect(Validators.email('ana@example.com'), isNull);
    });
  });

  group('ARB', () {
    Map<String, dynamic> read(String language) =>
        jsonDecode(File('lib/l10n/arb/app_$language.arb').readAsStringSync())
            as Map<String, dynamic>;

    Map<String, String> messages(Map<String, dynamic> arb) => {
      for (final entry in arb.entries)
        if (!entry.key.startsWith('@')) entry.key: entry.value as String,
    };

    final es = messages(read('es'));
    final en = messages(read('en'));

    test('español e inglés tienen exactamente las mismas llaves', () {
      expect(en.keys.toSet(), es.keys.toSet());
      expect(es, isNotEmpty);
    });

    test('cada texto usa las mismas variables en los dos idiomas', () {
      for (final key in es.keys) {
        expect(_arguments(en[key]!), _arguments(es[key]!), reason: key);
      }
    });

    test('todo texto con variables las declara con su tipo', () {
      final arb = read('es');
      for (final key in es.keys) {
        final used = _arguments(es[key]!);
        final declared =
            ((arb['@$key'] as Map<String, dynamic>?)?['placeholders']
                as Map<String, dynamic>?) ??
            const {};
        expect(declared.keys.toSet(), used, reason: key);
      }
    });

    test('ningún texto lleva rayas largas ni está vacío', () {
      for (final texts in [es, en]) {
        for (final entry in texts.entries) {
          expect(entry.value.trim(), isNotEmpty, reason: entry.key);
          expect(entry.value, isNot(contains('\u2014')), reason: entry.key);
        }
      }
    });
  });
}
