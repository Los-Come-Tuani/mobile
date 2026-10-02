import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Barra de las pantallas de guías: regresar y la miga "K’Plan / Guías".
/// Sin [onBack] sólo queda la miga, alineada con el contenido.
class GuideAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GuideAppBar({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onBack = this.onBack;
    return AppBar(
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.commonBack,
              onPressed: onBack,
            ),
      titleSpacing: onBack == null ? AppTheme.screenPadding.left : 0,
      title: Text(
        l10n.guideAccessAppBarTitle,
        semanticsLabel: l10n.guideAccessAppBarSemantics,
        style: AppTextStyles.sectionLabel,
      ),
    );
  }
}
