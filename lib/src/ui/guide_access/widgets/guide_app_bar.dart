import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Barra de las pantallas de guías: regresar y la miga "K’Plan / Guías".
class GuideAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GuideAppBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Regresar',
        onPressed: onBack,
      ),
      titleSpacing: 0,
      title: Text(
        'K’Plan  /  Guías',
        semanticsLabel: 'K’Plan, guías',
        style: AppTextStyles.sectionLabel,
      ),
    );
  }
}
