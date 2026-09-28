import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// El título con que abre cada pantalla de guías y, si hace falta, qué se
/// espera en ella.
class GuideHeading extends StatelessWidget {
  const GuideHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.formTitle),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: AppTextStyles.bodySmall.copyWith(height: 22 / 14),
          ),
        ],
      ],
    );
  }
}
