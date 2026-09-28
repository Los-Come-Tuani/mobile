import 'guide_coverage.dart';

export 'guide_coverage.dart';

/// En qué va el acceso de guía de una cuenta. La misma cuenta sirve para
/// entrar como turista o como guía; el rol de guía se habilita cuando el
/// equipo de K'Plan aprueba su solicitud.
enum GuideAccessStatus { none, pending, approved }

/// Un archivo adjunto a la solicitud: el documento de identidad, la
/// credencial INTUR o una certificación.
class GuideDocument {
  const GuideDocument({required this.name, required this.uri});

  /// Nombre con extensión, tal como lo verá el equipo de revisión.
  final String name;

  /// Dónde está en el teléfono, para subirlo cuando exista el endpoint.
  final Uri uri;
}

/// Lo que alguien envía para que el equipo de K'Plan habilite su rol de
/// guía.
class GuideAccessRequest {
  const GuideAccessRequest({
    required this.fullName,
    required this.phone,
    required this.contactEmail,
    required this.coverage,
    this.certifiedCity,
    required this.languages,
    required this.experience,
    required this.identityDocument,
    required this.inturCredential,
    this.certificates = const [],
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

  /// En sus palabras: cuántos años y qué tipo de recorridos.
  final String experience;
  final GuideDocument identityDocument;
  final GuideDocument inturCredential;

  /// Formación adicional; es opcional.
  final List<GuideDocument> certificates;
}
