import '../../../core/utils/result.dart';

/// Consultas al equipo de soporte.
///
/// Todavía no hay a dónde mandarlas: el envío se simula para poder recorrer
/// el flujo completo desde Configuraciones > Ayuda.
class SupportRepository {
  /// `true` mientras los mensajes no salgan del teléfono, para decírselo al
  /// turista en la confirmación.
  bool get isDemo => true;

  Future<Result<void>> send({
    required String email,
    required String subject,
    required String message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const Result.ok(null);
  }
}
