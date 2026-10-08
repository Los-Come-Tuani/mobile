import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n/l10n.dart';
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

/// Con el API: abre la cámara y devuelve el texto del primer QR que lea (el
/// API decide si es de un lugar con insignia). `null` si se cierra.
Future<String?> scanVisitQr(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (context) => const QrScannerView(stopId: null)),
  );
}

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key, required this.stopId});

  /// El lugar cuyo QR se espera; `null` acepta cualquiera y devuelve su texto.
  final String? stopId;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final _controller = MobileScannerController();
  bool _handled = false;

  /// Se escaneó un código que no es de esta parada. El texto del aviso se
  /// arma en `build` para que siga el idioma de la app.
  bool _wrongCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;

    final value = capture.barcodes.first.rawValue;
    if (value == null) return;

    final stopId = widget.stopId;
    if (stopId == null) {
      _handled = true;
      Navigator.of(context).pop(value);
    } else if (StopQrCode.matches(value, stopId)) {
      _handled = true;
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrongCode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: Text(l10n.stopDetailScanQr),
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
              _wrongCode ? l10n.stopDetailQrWrongStop : l10n.stopDetailQrAim,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: _wrongCode ? AppColors.star : AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
