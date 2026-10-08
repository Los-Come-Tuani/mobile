import '../../../core/utils/api_json.dart';
import 'api_call.dart';
import 'api_routes.dart';

/// Un motivo para reportar; con [requiresText] la nota es obligatoria.
class ReportReason {
  const ReportReason({
    required this.code,
    required this.label,
    required this.requiresText,
  });

  final String code;

  /// Viene del API, en español.
  final String label;
  final bool requiresText;

  factory ReportReason.fromApi(Map<String, dynamic> json) => ReportReason(
    code: ApiJson.str(json['code']),
    label: ApiJson.str(json['label']),
    requiresText: json['requires_text'] == true,
  );
}

/// Qué se reporta: una persona (por el id de su cuenta), una reseña, un lugar
/// o un evento.
enum ReportTarget {
  user,
  review,
  place,
  event;

  String get apiName => name;
}

/// Los reportes de cualquier sesión (`docs/avisos.md` del repo del API).
abstract final class ReportsApi {
  static Future<List<ReportReason>> reasons() async {
    final rows = await ApiRows.list(ApiRoutes.reportReasons);
    return [for (final row in rows) ReportReason.fromApi(row)];
  }

  /// `204`; nadie se reporta a sí mismo (`400`) y con `otro` la nota es
  /// obligatoria (`400`).
  static Future<void> report({
    required ReportTarget target,
    required String targetId,
    required String reason,
    String note = '',
  }) async {
    final text = note.trim();
    await ApiRows.post(ApiRoutes.reports, {
      'target_kind': target.apiName,
      'target_id': targetId,
      'reason': reason,
      if (text.isNotEmpty)
        'note': text.length > 1000 ? text.substring(0, 1000) : text,
    });
  }
}
