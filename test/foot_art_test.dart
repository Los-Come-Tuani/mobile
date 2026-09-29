import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/theme/app_theme.dart';
import 'package:k_plan_mobile/src/ui/widgets/foot_art.dart';

/// Una pantalla de 540 × 1200 con [contentHeight] de contenido y un dibujo
/// al pie. Devuelve hasta dónde se puede desplazar.
Future<ScrollPosition> _pump(WidgetTester tester, double contentHeight) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: FootArtScrollView(
          art: FootArt.username,
          padding: const EdgeInsets.all(24),
          child: SizedBox(height: contentHeight),
        ),
      ),
    ),
  );
  return tester.state<ScrollableState>(find.byType(Scrollable)).position;
}

void main() {
  testWidgets('si el contenido cabe, el dibujo no hace desplazar la pantalla', (
    tester,
  ) async {
    final position = await _pump(tester, 600);

    expect(position.maxScrollExtent, 0);
    expect(find.byType(FootArtLayer), findsOneWidget);
  });

  testWidgets(
    'con contenido largo, sólo se desplaza lo que mide el contenido',
    (tester) async {
      final position = await _pump(tester, 2000);

      // 2000 de contenido y 48 de márgenes, en una pantalla de 1200.
      expect(position.maxScrollExtent, 2000 + 48 - 1200);
    },
  );
}
