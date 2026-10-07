import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/l10n/l10n.dart';
import 'package:k_plan_mobile/src/ui/widgets/options_sheet.dart';

/// Una pantalla con un botón que abre la hoja y guarda lo que se eligió.
class _Host extends StatefulWidget {
  const _Host({required this.options, this.selected});

  final List<String> options;
  final String? selected;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? chosen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final value = await showOptionsSheet(
                context,
                title: 'Hora',
                options: widget.options,
                selected: widget.selected,
              );
              setState(() => chosen = value);
            },
            child: const Text('abrir'),
          ),
          Text('elegido: ${chosen ?? '-'}'),
        ],
      ),
    );
  }
}

Future<void> _open(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(MaterialApp(home: host));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => AppStrings.use(AppLanguage.es));

  const options = ['9:00 a.m.', '3:00 p.m.'];

  testWidgets('en español muestra las horas como vienen de los datos', (
    tester,
  ) async {
    await _open(tester, const _Host(options: options));

    expect(find.text('9:00 a.m.'), findsOneWidget);
    expect(find.text('3:00 p.m.'), findsOneWidget);
  });

  testWidgets('en inglés muestra las horas en formato inglés', (tester) async {
    AppStrings.use(AppLanguage.en);

    await _open(tester, const _Host(options: options));

    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('3:00 PM'), findsOneWidget);
    expect(find.text('9:00 a.m.'), findsNothing);
  });

  testWidgets('devuelve la opción original aunque se vea en otro formato', (
    tester,
  ) async {
    AppStrings.use(AppLanguage.en);

    await _open(tester, const _Host(options: options));
    await tester.tap(find.text('3:00 PM'));
    await tester.pumpAndSettle();

    expect(find.text('elegido: 3:00 p.m.'), findsOneWidget);
  });

  testWidgets('marca como elegida la misma hora guardada en el otro formato', (
    tester,
  ) async {
    AppStrings.use(AppLanguage.en);

    // La hora se guardó en español y ahora la app está en inglés.
    await _open(tester, const _Host(options: options, selected: '3:00 p.m.'));

    final checks = find.byIcon(Icons.check);
    expect(checks, findsOneWidget);
    expect(
      find.ancestor(of: checks, matching: find.byType(ListTile)),
      findsOneWidget,
    );
    final tile = tester.widget<ListTile>(
      find.ancestor(of: checks, matching: find.byType(ListTile)),
    );
    expect((tile.title as Text).data, '3:00 PM');
    expect(tile.selected, isTrue);
  });

  testWidgets('un texto que no es una hora se muestra tal cual', (
    tester,
  ) async {
    AppStrings.use(AppLanguage.en);

    await _open(
      tester,
      const _Host(options: ['Español', 'English'], selected: 'English'),
    );

    expect(find.text('Español'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
