import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_plan_mobile/src/router/routes.dart';
import 'package:k_plan_mobile/src/ui/not_found/view/not_found_view.dart';
import 'package:k_plan_mobile/src/ui/widgets/app_snack_bar.dart';
import 'package:k_plan_mobile/src/ui/widgets/crash_fallback.dart';
import 'package:k_plan_mobile/src/ui/widgets/error_state.dart';

void main() {
  /// Una app mínima con el inicio y la pantalla de una dirección que no existe.
  GoRouter routerAt(String location) => GoRouter(
    initialLocation: location,
    errorBuilder: (context, state) => const NotFoundView(),
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const Scaffold(body: Text('Inicio')),
      ),
    ],
  );

  testWidgets('una dirección desconocida ofrece volver al inicio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: routerAt('/esto-no-existe')),
    );
    await tester.pump();

    expect(find.text('No encontramos esta pantalla'), findsOneWidget);
    expect(find.textContaining('404'), findsNothing);

    await tester.tap(find.text('VOLVER AL INICIO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('el error de carga ofrece reintentar', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorState(
            message: 'No hay conexión a internet',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('No pudimos cargar esto'), findsOneWidget);
    expect(find.text('No hay conexión a internet'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    expect(retries, 1);
  });

  testWidgets('sin reintento, el error igual deja una salida', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ErrorState(message: 'Algo salió mal')),
      ),
    );

    expect(find.text('VOLVER AL INICIO'), findsOneWidget);
  });

  testWidgets('lo que falló al pintarse se ve amable aunque no haya tema', (
    tester,
  ) async {
    await tester.pumpWidget(const CrashFallback());

    expect(find.text('Algo no salió como esperábamos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en un hueco pequeño queda solo el ícono', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: 120, height: 40, child: CrashFallback()),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Algo no salió como esperábamos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un aviso de error lleva su ícono y uno informativo no', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showMessage('No se pudo guardar', tone: SnackTone.error),
                  child: const Text('error'),
                ),
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).showMessage('Listo'),
                  child: const Text('info'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('error'));
    await tester.pump();
    expect(find.text('No se pudo guardar'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.tap(find.text('info'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Listo'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}
