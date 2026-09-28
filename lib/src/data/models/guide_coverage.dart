/// Hasta dónde puede guiar alguien, según su certificación: un guía nacional
/// cubre todo el territorio nicaragüense; uno local, sólo la ciudad donde se
/// certificó.
enum GuideCoverage {
  national,
  local;

  /// Sin dato se toma como nacional: así nadie queda fuera por error.
  static GuideCoverage fromJson(String? value) =>
      value == 'local' ? GuideCoverage.local : GuideCoverage.national;

  /// "Guía nacional" o "Guía local · Granada".
  String labelFor(String? city) => switch (this) {
    GuideCoverage.national => 'Guía nacional',
    GuideCoverage.local => city == null ? 'Guía local' : 'Guía local · $city',
  };
}
