import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Barra superior de la app del guía. Va en tinta, no en terracota como la
/// del turista, para que siempre se note en qué modo se está.
///
/// Sin [title] muestra el logo con la etiqueta "Guías" (las pestañas); con
/// [title], el nombre de la pantalla y la flecha de regreso.
class GuideBar extends StatelessWidget implements PreferredSizeWidget {
  const GuideBar({super.key, this.title, this.actions});

  final String? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      backgroundColor: AppColors.primary60,
      foregroundColor: AppColors.primary10,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      titleSpacing: title == null ? 20 : (canPop ? 0 : null),
      title: title == null
          ? Row(
              children: [
                SvgPicture.asset(
                  AppAssets.logoTipoClaro,
                  height: 28,
                  semanticsLabel: 'K’Plan',
                ),
                const SizedBox(width: 10),
                const _ModeTag(),
              ],
            )
          : Text(
              title!,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(
                fontSize: 16,
                color: AppColors.primary10,
              ),
            ),
      actions: actions,
    );
  }
}

/// "Guías", junto al logo.
class _ModeTag extends StatelessWidget {
  const _ModeTag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          context.l10n.guideAppBarModeTag,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
