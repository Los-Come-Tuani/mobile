import 'tour_guide.dart';

/// Puesto al que se postula alguien en una propuesta: guía o traductor.
enum ApplicationRole { guide, translator }

/// Una postulación a una propuesta de trabajo: quién se postula, a qué
/// puesto y qué ofrece (precio, transporte y un mensaje para el turista).
class GuideApplication {
  const GuideApplication({
    required this.id,
    required this.guide,
    required this.role,
    required this.proposedPrice,
    required this.message,
    required this.appliedAt,
  });

  final String id;
  final TourGuide guide;
  final ApplicationRole role;

  /// Lo que cobra por el servicio: el presupuesto del turista tal cual o una
  /// contraoferta.
  final num proposedPrice;

  /// Presentación corta para el turista.
  final String message;
  final DateTime appliedAt;

  /// Pone su propio vehículo durante el recorrido. Sólo aplica a guías: un
  /// traductor acompaña, no lleva el recorrido.
  bool get offersTransport =>
      role == ApplicationRole.guide && guide.hasTransport;
}
