import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_app_bar.dart';

/// Esqueleto de las pantallas de Configuraciones: barra terracota, una
/// pregunta opcional arriba y la barra inferior en Perfil, de donde cuelgan.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.children,
    this.heading,
  });

  final String title;

  /// Encabezado de la página ("Mantente al tanto").
  final String? heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(title: title),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: AppBottomNav.profile,
      ),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 24, bottom: 24),
        children: [
          if (heading != null) ...[
            Text(heading!, style: AppTextStyles.pageTitle),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }
}
