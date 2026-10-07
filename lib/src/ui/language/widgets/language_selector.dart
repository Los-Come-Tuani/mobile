import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/repository/language_repository.dart';
import 'language_option.dart';

/// Las opciones de idioma de la app y, debajo, la nota de los nombres de
/// lugares. La usan las pantallas de idioma del turista y del guía.
///
/// Al elegir, toda la app cambia al instante y se va a [destination].
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, required this.destination});

  /// La ruta a la que se vuelve después de cambiar el idioma.
  ///
  /// Se llega con `go` y no con `pop`: lo que sigue abierto por debajo
  /// (Inicio, Perfil) conserva el contenido del idioma anterior. Con `go` la
  /// pila se limpia y cada pantalla se arma de nuevo, ya traducida, cuando se
  /// visita.
  final String destination;

  Future<void> _choose(
    BuildContext context,
    LanguageRepository repository,
    AppLanguage language,
  ) async {
    if (language == repository.language) return;
    await repository.choose(language);
    if (context.mounted) context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<LanguageRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final language in AppLanguage.values) ...[
          LanguageOption(
            language: language,
            selected: language == repository.language,
            onTap: () => _choose(context, repository, language),
          ),
          const SizedBox(height: 12),
        ],
        Text(context.l10n.languagePlaceNamesNote, style: AppTextStyles.caption),
      ],
    );
  }
}
