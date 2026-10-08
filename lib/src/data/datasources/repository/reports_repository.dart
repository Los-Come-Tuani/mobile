import '../../../core/utils/result.dart';
import '../remote/api_call.dart';
import '../remote/reports_api.dart';

/// Reportar a una persona, una reseña, un lugar o un evento al equipo de
/// K'Plan. Solo con el API; los motivos se piden una vez.
class ReportsRepository {
  List<ReportReason>? _reasons;

  Future<Result<List<ReportReason>>> reasons() async {
    if (_reasons case final cached?) return Result.ok(cached);
    final result = await apiCall('reportReasons', ReportsApi.reasons);
    if (result case Ok(:final value)) _reasons = value;
    return result;
  }

  Future<Result<void>> report({
    required ReportTarget target,
    required String targetId,
    required String reason,
    String note = '',
  }) => apiCall(
    'report',
    () => ReportsApi.report(
      target: target,
      targetId: targetId,
      reason: reason,
      note: note,
    ),
  );
}
