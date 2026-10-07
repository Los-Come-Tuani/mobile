import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/map_icon_renderer.dart';
import 'package:k_plan_mobile/src/ui/widgets/map/map_pins.dart';

/// Ancho y alto de un PNG, que van en su encabezado.
(int, int) _sizeOf(Uint8List png) {
  final header = ByteData.sublistView(png, 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  testWidgets('un pin sale en PNG a la densidad pedida, con su margen', (
    tester,
  ) async {
    final png = await tester.runAsync(
      () => MapIconRenderer.render(
        const StopPin(number: 3),
        view: tester.view,
        pixelRatio: 2,
      ),
    );

    expect(png!.sublist(1, 4), 'PNG'.codeUnits);
    const margin = MapIconRenderer.margin;
    final pin = StopPin.sizeFor(emphasized: false);
    expect(_sizeOf(png), (
      ((pin.width + 2 * margin) * 2).round(),
      ((pin.height + 2 * margin) * 2).round(),
    ));
  });

  testWidgets('el nombre sale como la píldora bajo el pin', (tester) async {
    final png = await tester.runAsync(
      () => MapIconRenderer.render(
        const PinLabel('Convento y Museo San Francisco de Granada'),
        view: tester.view,
        pixelRatio: 1,
      ),
    );

    const margin = MapIconRenderer.margin;
    expect(_sizeOf(png!), (
      (PinLabel.maxWidth + 2 * margin).round(),
      (PinLabel.height + 2 * margin).round(),
    ));
  });
}
