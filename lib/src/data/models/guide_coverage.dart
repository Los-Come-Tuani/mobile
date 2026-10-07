import '../../core/l10n/l10n.dart';

/// Hasta dónde puede guiar alguien, según su certificación: un guía nacional
/// cubre todo el territorio nicaragüense; uno local, sólo la ciudad donde se
/// certificó.
enum GuideCoverage {
  national,
  local;

  /// Sin dato se toma como nacional: así nadie queda fuera por error.
  static GuideCoverage fromJson(String? value) =>
      value == 'local' ? GuideCoverage.local : GuideCoverage.national;

  /// "Guía nacional" o "Guía local · Granada", en el idioma de ahora.
  String labelFor(String? city) {
    final l10n = AppStrings.current;
    return switch (this) {
      GuideCoverage.national => l10n.modelGuideCoverageNational,
      GuideCoverage.local =>
        city == null
            ? l10n.commonLocalGuide
            : l10n.modelGuideCoverageLocalCity(city),
    };
  }
}
