import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Barra superior terracota de las pantallas principales (Mis viajes,
/// Guardados, Perfil...). La flecha de regreso aparece sola cuando hay a
/// dónde volver.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary30,
      foregroundColor: AppColors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      titleSpacing: ModalRoute.of(context)?.canPop ?? false ? 0 : null,
      title: Text(
        title,
        style: AppTextStyles.title.copyWith(
          fontSize: 14,
          color: AppColors.white,
        ),
      ),
      actions: actions,
    );
  }
}
