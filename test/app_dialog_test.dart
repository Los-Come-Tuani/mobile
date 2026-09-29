import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_colors.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/ui/widgets/app_dialog.dart';

const _noAnswer = 'sin respuesta';

/// Lo último que devolvió el diálogo abierto con [_open].
Object? _result;

/// Abre el diálogo de [show] desde una pantalla vacía, con la letra del
/// sistema a [textScale]. Cada vez es una app nueva, así que no queda ningún
/// diálogo abierto de antes.
Future<void> _open(
  WidgetTester tester,
  Future<Object?> Function(BuildContext context) show, {
  double textScale = 1,
}) async {
  _result = _noAnswer;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => _result = await show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Future<bool> _confirmDelete(BuildContext context) => showConfirmDialog(
  context,
  icon: Icons.delete_outline,
  title: '¿Eliminar "Granada"?',
  message: 'No se puede deshacer.',
  confirmLabel: 'Eliminar',
  destructive: true,
);

Future<String?> _askName(BuildContext context) => showTextInputDialog(
  context,
  title: 'Nuevo circuito',
  hint: 'Ej. Fin de semana en el sur',
  confirmLabel: 'Crear',
  emptyMessage: 'Ponle un nombre a tu circuito',
);

void main() {
  testWidgets('confirmar devuelve true; cancelar o tocar fuera, false', (
    tester,
  ) async {
    await _open(tester, _confirmDelete);
    expect(find.text('¿Eliminar "Granada"?'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(_result, isTrue);
    expect(find.byType(AppDialog), findsNothing);

    await _open(tester, _confirmDelete);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(_result, isFalse);

    await _open(tester, _confirmDelete);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(_result, isFalse);
  });

  testWidgets('los botones van lado a lado, también con letra muy grande', (
    tester,
  ) async {
    for (final textScale in [1.0, 2.5]) {
      await _open(tester, _confirmDelete, textScale: textScale);
      final cancel = tester.getCenter(find.text('Cancelar'));
      final confirm = tester.getCenter(find.text('Eliminar'));
      expect(cancel.dy, confirm.dy);
      expect(cancel.dx, lessThan(confirm.dx));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('con letra muy grande, las dos etiquetas se achican por igual', (
    tester,
  ) async {
    await _open(
      tester,
      (context) => showConfirmDialog(
        context,
        icon: Icons.person_search_outlined,
        title: 'No hemos encontrado esta cuenta',
        confirmLabel: 'Crear cuenta',
      ),
      textScale: 2.5,
    );
    final cancel = tester.getRect(find.text('Cancelar'));
    final confirm = tester.getRect(find.text('Crear cuenta'));
    expect(cancel.center.dy, moreOrLessEquals(confirm.center.dy));
    expect(cancel.height, moreOrLessEquals(confirm.height, epsilon: 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lo que borra va en rojo; lo demás, en terracota', (
    tester,
  ) async {
    await _open(tester, _confirmDelete);
    final destructive = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(destructive.style?.backgroundColor?.resolve({}), AppColors.error);

    await _open(
      tester,
      (context) => showConfirmDialog(
        context,
        icon: Icons.handshake_outlined,
        title: '¿Contratar a Ana?',
        confirmLabel: 'Contratar',
      ),
    );
    final standard = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(standard.style?.backgroundColor, isNull);
  });

  testWidgets('el lector de pantalla anuncia el diálogo por su título', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, _confirmDelete);

    expect(find.bySemanticsLabel('¿Eliminar "Granada"?'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('no acepta un texto vacío y lo devuelve sin espacios de más', (
    tester,
  ) async {
    await _open(tester, _askName);
    await tester.tap(find.text('Crear'));
    await tester.pump();
    expect(find.text('Ponle un nombre a tu circuito'), findsOneWidget);
    expect(_result, _noAnswer);

    await tester.enterText(find.byType(TextField), '  Fin de semana  ');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(_result, 'Fin de semana');

    await _open(tester, _askName);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(_result, isNull);
  });
}
