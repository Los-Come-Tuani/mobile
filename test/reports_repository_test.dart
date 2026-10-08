import 'package:flutter_test/flutter_test.dart';
import 'package:k_plan_mobile/src/core/utils/result.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/api_client.dart';
import 'package:k_plan_mobile/src/data/datasources/remote/reports_api.dart';
import 'package:k_plan_mobile/src/data/datasources/repository/reports_repository.dart';

import 'support/fake_api.dart';

void main() {
  tearDown(ApiClient.configureForTest);

  test('los motivos se piden una vez y el reporte manda lo elegido', () async {
    final api = FakeApi((request) {
      if (request.path == '/report/reason/') {
        return const FakeResponse(200, [
          {'code': 'acoso', 'label': 'Acoso', 'requires_text': false},
          {'code': 'otro', 'label': 'Otro', 'requires_text': true},
        ]);
      }
      return const FakeResponse(204);
    })..connect();
    final reports = ReportsRepository();

    final reasons = (await reports.reasons() as Ok<List<ReportReason>>).value;
    await reports.reasons();
    expect(reasons.map((r) => r.code), ['acoso', 'otro']);
    expect(reasons.last.requiresText, isTrue);
    expect(api.calls('/report/reason/'), 1);

    final result = await reports.report(
      target: ReportTarget.place,
      targetId: 'stop-1',
      reason: 'otro',
      note: '  El lugar está cerrado hace meses ',
    );

    expect(result.isOk, isTrue);
    expect(api.requests.last.path, '/report/');
    expect(api.requests.last.body, {
      'target_kind': 'place',
      'target_id': 'stop-1',
      'reason': 'otro',
      'note': 'El lugar está cerrado hace meses',
    });
  });

  test('un reporte rechazado devuelve el mensaje del API', () async {
    FakeApi((_) => apiError(400, 'No puedes reportarte a ti mismo.')).connect();

    final result = await ReportsRepository().report(
      target: ReportTarget.user,
      targetId: 'user-1',
      reason: 'acoso',
    );

    expect((result as Failure).message, 'No puedes reportarte a ti mismo.');
  });
}
