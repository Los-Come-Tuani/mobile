import 'guide_coverage.dart';

export 'guide_coverage.dart';

/// En qué va el acceso de guía de una cuenta. Una cuenta ejerce un solo papel: la de
/// un guía o traductor se crea al postularse y, mientras la revisan, solo ve su estado.
enum GuideAccessStatus { none, pending, approved }

/// Un archivo elegido en el teléfono: el documento de identidad, la licencia, una foto.
class GuideDocument {
  const GuideDocument({required this.name, required this.uri});

  /// Nombre con extensión, tal como lo verá el equipo de revisión.
  final String name;

  /// Dónde está en el teléfono, para subirlo.
  final Uri uri;
}

/// El perfil del guía con que trabaja la app del guía: cómo se llama, dónde guía y qué
/// habla. Sale de la postulación (o del perfil que entrega el API).
class GuideAccessRequest {
  const GuideAccessRequest({
    required this.fullName,
    required this.phone,
    required this.contactEmail,
    required this.coverage,
    this.certifiedCity,
    required this.languages,
    required this.experience,
  }) : assert(
         (coverage == GuideCoverage.local) == (certifiedCity != null),
         'Sólo un guía local tiene ciudad de certificación',
       );

  /// Tal como aparece en su documento de identidad.
  final String fullName;

  /// Con el código de país: "+505 8888 0000".
  final String phone;

  /// A donde se le escribe el resultado de la revisión.
  final String contactEmail;
  final GuideCoverage coverage;

  /// La única ciudad donde puede guiar un guía local; `null` si es nacional.
  final String? certifiedCity;
  final List<String> languages;

  /// En sus palabras: lo que verá el turista.
  final String experience;
}
