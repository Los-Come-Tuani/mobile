import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/qr_codes.dart';

/// Abre la cámara para escanear el código QR de una parada. Devuelve `true`
/// en cuanto detecta el código correcto; `null` si el usuario cancela.
Future<bool?> showQrScanner(BuildContext context, {required String stopId}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (context) => QrScannerView(stopId: stopId)),
  );
}

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key, required this.stopId});

  final String stopId;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final _controller = MobileScannerController();
  bool _handled = false;
  String? _hint;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;

    final value = capture.barcodes.first.rawValue;
    if (value == null) return;

    if (StopQrCode.matches(value, widget.stopId)) {
      _handled = true;
      Navigator.of(context).pop(true);
    } else {
      setState(() => _hint = 'Ese código no es de esta parada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: const Text('Escanear código QR'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Text(
              _hint ?? 'Apunta la cámara al código QR de la parada',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: _hint == null ? AppColors.white : AppColors.star,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
