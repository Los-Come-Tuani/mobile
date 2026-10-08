import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_parser.dart';
import '../../models/circuit_group_session.dart';
import '../../models/guide_desk.dart';
import 'api_call.dart';
import 'api_routes.dart';

/// Lo que hace un guía aprobado con el API: sus salidas, las convocatorias
/// abiertas y sus postulaciones (`docs/servicios.md`), su saldo, su cuenta y
/// sus retiros (`docs/finanzas.md`). Una cuenta que no es de guía aprobado
/// recibe `403`.
abstract final class GuideDeskApi {
  // ── Salidas ───────────────────────────────────────────────────────────────

  static Future<List<CircuitGroupSession>> departures() async {
    final rows = await ApiRows.list(ApiRoutes.departures);
    return [for (final row in rows) CircuitGroupSession.fromApi(row)];
  }

  /// Publica una salida en un circuito oficial de su ciudad (`409` si ya sale
  /// a esa hora).
  static Future<CircuitGroupSession> publishDeparture({
    required String circuitId,
    required DateTime date,
    required String startTime,
    required int capacity,
    required bool transportIncluded,
    String note = '',
  }) async => CircuitGroupSession.fromApi(
    await ApiRows.post(ApiRoutes.departures, {
      'circuit_id': circuitId,
      'date': _date(date),
      'start_time': _time(startTime),
      'capacity': capacity,
      'transport_included': transportIncluded,
      if (note.trim().isNotEmpty) 'note': _clip(note.trim(), 500),
    }),
  );

  /// Cupo (no menos de lo reservado), transporte y nota.
  static Future<CircuitGroupSession> updateDeparture(
    String id, {
    required int capacity,
    required bool transportIncluded,
    required String note,
  }) async => CircuitGroupSession.fromApi(
    await ApiRows.patch(ApiRoutes.departure(id), {
      'capacity': capacity,
      'transport_included': transportIncluded,
      'note': _clip(note.trim(), 500),
    }),
  );

  /// La cancela y cancela sus reservas.
  static Future<CircuitGroupSession> cancelDeparture(
    String id,
    String reason,
  ) async => CircuitGroupSession.fromApi(
    await ApiRows.post(ApiRoutes.departureCancel(id), {
      'reason': _clip(reason.trim(), 500),
    }),
  );

  // ── Convocatorias y postulaciones ─────────────────────────────────────────

  static Future<List<OpenRequest>> openRequests() async {
    final rows = await ApiRows.list(ApiRoutes.openRequests);
    return [for (final row in rows) OpenRequest.fromApi(row)];
  }

  /// `409` si ya se postuló; `400` si pide más que el tope.
  static Future<GuideBid> apply(
    String requestId, {
    required int fee,
    String message = '',
  }) async => GuideBid.fromApi(
    await ApiRows.post(ApiRoutes.openRequestApply(requestId), {
      'fee': fee,
      if (message.trim().isNotEmpty) 'message': _clip(message.trim(), 1000),
    }),
  );

  static Future<List<GuideBid>> myBids() async {
    final rows = await ApiRows.list(ApiRoutes.applicationsMine);
    return [for (final row in rows) GuideBid.fromApi(row)];
  }

  static Future<GuideBid> withdrawBid(String id) async =>
      GuideBid.fromApi(await ApiRows.post(ApiRoutes.applicationWithdraw(id)));

  // ── Saldo, cuenta y retiros ───────────────────────────────────────────────

  static Future<GuideBalance> balance() async =>
      GuideBalance.fromApi(await ApiRows.one(ApiRoutes.balanceMine));

  static Future<BankAccounts> bankAccounts() async =>
      BankAccounts.fromApi(await ApiRows.one(ApiRoutes.bankAccountMine));

  /// La primera vale de una vez; un cambio, en 24 horas.
  static Future<BankAccounts> saveBankAccount({
    required String bank,
    required String holder,
    required String accountType,
    required String number,
  }) async => BankAccounts.fromApi(
    await ApiRows.post(ApiRoutes.bankAccountMine, {
      'bank': bank.trim(),
      'holder': holder.trim(),
      'account_type': accountType,
      'number': number.trim(),
    }),
  );

  static Future<List<Payout>> payouts() async {
    final rows = await ApiRows.list(ApiRoutes.withdrawalsMine);
    return [for (final row in rows) Payout.fromApi(row)];
  }

  /// Aparta [amount] del saldo (`400` sin cuenta activa o por más del saldo).
  static Future<Payout> requestPayout(int amount) async => Payout.fromApi(
    await ApiRows.post(ApiRoutes.withdrawals, {'amount': amount}),
  );

  // ── Piezas ────────────────────────────────────────────────────────────────

  static String _date(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String _time(String time) {
    final minutes = TimeParser.minutesOfDay(time);
    return minutes == null ? time : Formatters.time24h(minutes);
  }

  static String _clip(String text, int max) =>
      text.length > max ? text.substring(0, max) : text;
}
