import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/guide_request.dart';

/// Un dato de una propuesta o de un viaje: ícono y texto.
class DetailLine extends StatelessWidget {
  const DetailLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quién pone el transporte, dicho al guía.
String transportForGuide(TransportOption option) => switch (option) {
  TransportOption.onFoot => AppStrings.current.guideAppTransportOnFoot,
  TransportOption.touristProvides =>
    AppStrings.current.guideAppTransportTourist,
  TransportOption.guideProvides => AppStrings.current.guideAppTransportGuide,
};
