import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/routes.dart';
import '../../widgets/illustration_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

/// Pantalla de bienvenida.
///
/// No tiene estado propio (sólo navega), por eso no necesita ViewModel.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            IllustrationHeader(
              asset: AppAssets.welcomeIllustration,
              height: size.height * 0.48,
            ),
            Expanded(
              child: Padding(
                padding: AppTheme.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),
                    Text(AppStrings.welcomeTitle, style: AppTextStyles.display),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.welcomeSubtitle,
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: AppStrings.login,
                      onPressed: () => context.push(Routes.login),
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      label: AppStrings.register,
                      onPressed: () => context.push(Routes.register),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
