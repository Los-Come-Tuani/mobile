import '../../../l10n/app_localizations.dart';

/// Cómo se muestran en cada idioma los valores del catálogo que además son
/// claves de lógica.
///
/// Las categorías (`'Gastronomía'`) y los idiomas (`'Inglés'`) viajan en los
/// datos siempre en español: con ellos se reparten las insignias, se filtra,
/// se eligen los íconos y se junta a turistas con guías. Por eso no se
/// traducen en los datos sino aquí, al mostrarlos. Un valor que no se conoce
/// se muestra tal cual.
extension ContentLabels on AppLocalizations {
  /// `'Historia'` -> `History`.
  String categoryName(String category) => switch (category) {
    'Historia' => categoryHistory,
    'Gastronomía' => categoryFood,
    'Cultura' => categoryCulture,
    'Naturaleza' => categoryNature,
    'Aventura' => categoryAdventure,
    'Ciudad' => categoryCity,
    'Feria' => categoryFair,
    'Tradición' => categoryTradition,
    // La categoría de las insignias de los circuitos creativos.
    'Circuitos creativos' => commonCreativeCircuits,
    _ => category,
  };

  /// `'Inglés'` -> `English`.
  String languageName(String language) => switch (language) {
    'Español' => languageNameSpanish,
    'Inglés' => languageNameEnglish,
    'Alemán' => languageNameGerman,
    'Francés' => languageNameFrench,
    'Portugués' => languageNamePortuguese,
    'Italiano' => languageNameItalian,
    _ => language,
  };
}
