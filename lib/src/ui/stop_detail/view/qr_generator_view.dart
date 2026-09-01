import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/qr_codes.dart';

/// Pantalla de demo: muestra el código QR de una parada para poder probar
/// el flujo de escaneo sin un cartel físico en el sitio (por ejemplo,
/// escaneándolo desde otro teléfono).
class QrGeneratorView extends StatelessWidget {
  const QrGeneratorView({
    super.key,
    required this.stopId,
    required this.stopName,
  });

  final String stopId;
  final String stopName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Código QR (demo)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppColors.divider),
                ),
                child: QrImageView(
                  data: StopQrCode.payloadFor(stopId),
                  size: 220,
                  backgroundColor: AppColors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                stopName,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Escanéalo desde el detalle de esta parada para reclamar '
                'su insignia.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
