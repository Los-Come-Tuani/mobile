import '../../core/l10n/l10n.dart';
import '../../core/utils/api_json.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/time_parser.dart';

/// `"08:30"` del API como la guarda la app (`8:30 a.m.`).
String _appTime(Object? value) {
  final raw = ApiJson.str(value);
  final minutes = TimeParser.minutesOf24h(raw);
  return minutes == null ? raw : Formatters.dataTime(minutes);
}

/// Una convocatoria abierta de la ciudad del guía (`GET /open-request/`).
class OpenRequest {
  const OpenRequest({
    required this.id,
    required this.itineraryTitle,
    required this.stops,
    required this.city,
    required this.date,
    required this.startTime,
    required this.adults,
    required this.children,
    required this.maxFee,
    required this.note,
    required this.applied,
  });

  final String id;
  final String itineraryTitle;
  final int stops;
  final String city;
  final DateTime date;
  final String startTime;
  final int adults;
  final int children;

  /// Nadie se postula por más; `null` sin tope.
  final int? maxFee;
  final String note;

  /// El guía ya se postuló.
  final bool applied;

  int get groupSize => adults + children;

  factory OpenRequest.fromApi(Map<String, dynamic> json) {
    final itinerary = ApiJson.map(json['itinerary']);
    return OpenRequest(
      id: ApiJson.str(json['id']),
      itineraryTitle: ApiJson.str(itinerary['title']),
      stops: ApiJson.integer(itinerary['stops']),
      city: ApiJson.str(ApiJson.map(json['city'])['name']),
      date: ApiJson.day(json['date']),
      startTime: _appTime(json['start_time']),
      adults: ApiJson.integer(json['adults']),
      children: ApiJson.integer(json['children']),
      maxFee: ApiJson.integerOrNull(json['max_fee']),
      note: ApiJson.str(json['note']),
      applied: json['applied'] == true,
    );
  }
}

/// En qué va una postulación del guía.
enum BidStatus {
  sent,
  accepted,
  rejected,
  withdrawn;

  static BidStatus fromApi(Object? value) => switch (value) {
    'accepted' => accepted,
    'rejected' => rejected,
    'withdrawn' => withdrawn,
    _ => sent,
  };

  String get label {
    final l10n = AppStrings.current;
    return switch (this) {
      sent => l10n.guideDeskBidSent,
      accepted => l10n.guideDeskBidAccepted,
      rejected => l10n.guideDeskBidRejected,
      withdrawn => l10n.guideDeskBidWithdrawn,
    };
  }
}

/// La convocatoria de una postulación, en corto (`request` de la postulación).
class BidRequest {
  const BidRequest({
    required this.itineraryTitle,
    required this.stops,
    required this.city,
    required this.date,
    required this.startTime,
    required this.adults,
    required this.children,
  });

  final String itineraryTitle;
  final int stops;
  final String city;
  final DateTime date;
  final String startTime;
  final int adults;
  final int children;

  int get groupSize => adults + children;

  static BidRequest? fromApi(Object? value) {
    final json = ApiJson.map(value);
    if (json.isEmpty) return null;
    final itinerary = ApiJson.map(json['itinerary']);
    return BidRequest(
      itineraryTitle: ApiJson.str(itinerary['title']),
      stops: ApiJson.integer(itinerary['stops']),
      city: ApiJson.str(ApiJson.map(json['city'])['name']),
      date: ApiJson.day(json['date']),
      startTime: _appTime(json['start_time']),
      adults: ApiJson.integer(json['adults']),
      children: ApiJson.integer(json['children']),
    );
  }
}

/// Una postulación del guía (`GET /application/mine/`).
class GuideBid {
  const GuideBid({
    required this.id,
    required this.requestId,
    required this.fee,
    required this.message,
    required this.status,
    required this.createdAt,
    this.request,
  });

  final String id;
  final String requestId;
  final int fee;
  final String message;
  final BidStatus status;
  final DateTime createdAt;

  /// La convocatoria a la que se postuló.
  final BidRequest? request;

  factory GuideBid.fromApi(Map<String, dynamic> json) => GuideBid(
    id: ApiJson.str(json['id']),
    requestId: ApiJson.str(json['request_id']),
    fee: ApiJson.integer(json['fee']),
    message: ApiJson.str(json['message']),
    status: BidStatus.fromApi(json['status']),
    createdAt: ApiJson.date(json['created_at']) ?? DateTime.now(),
    request: BidRequest.fromApi(json['request']),
  );
}

/// Un movimiento del saldo del guía.
class BalanceMovement {
  const BalanceMovement({
    required this.amount,
    required this.kind,
    required this.recordedAt,
    this.bookingId,
    this.withdrawalId,
  });

  /// Negativo en un retiro.
  final int amount;

  /// `servicio`, `retiro` o `devolucion_retiro`.
  final String kind;
  final DateTime recordedAt;
  final String? bookingId;
  final String? withdrawalId;

  String get label {
    final l10n = AppStrings.current;
    return switch (kind) {
      'servicio' => l10n.guideFinanceMovementService,
      'retiro' => l10n.guideFinanceMovementWithdrawal,
      'devolucion_retiro' => l10n.guideFinanceMovementReturned,
      _ => kind,
    };
  }

  factory BalanceMovement.fromApi(Map<String, dynamic> json) => BalanceMovement(
    amount: ApiJson.integer(json['amount']),
    kind: ApiJson.str(json['kind']),
    recordedAt: ApiJson.date(json['recorded_at']) ?? DateTime.now(),
    bookingId: ApiJson.strOrNull(json['booking_id']),
    withdrawalId: ApiJson.strOrNull(json['withdrawal_id']),
  );
}

/// El saldo del guía: lo que puede retirar, lo que pidió y no se le ha pagado
/// y sus últimos movimientos.
class GuideBalance {
  const GuideBalance({
    required this.balance,
    required this.pendingWithdrawals,
    required this.movements,
  });

  final int balance;
  final int pendingWithdrawals;
  final List<BalanceMovement> movements;

  factory GuideBalance.fromApi(Map<String, dynamic> json) => GuideBalance(
    balance: ApiJson.integer(json['balance']),
    pendingWithdrawals: ApiJson.integer(json['pending_withdrawals']),
    movements: [
      for (final row in ApiJson.rows(json['movements']))
        BalanceMovement.fromApi(row),
    ],
  );
}

/// Una cuenta bancaria del guía. El número completo nunca vuelve del API.
class BankAccount {
  const BankAccount({
    required this.id,
    required this.bank,
    required this.holder,
    required this.accountType,
    required this.last4,
    required this.effectiveAt,
  });

  final String id;
  final String bank;
  final String holder;

  /// `ahorro` o `corriente`.
  final String accountType;
  final String last4;

  /// Desde cuándo vale (un cambio espera 24 horas).
  final DateTime effectiveAt;

  String get typeLabel => accountType == 'corriente'
      ? AppStrings.current.guideFinanceAccountChecking
      : AppStrings.current.guideFinanceAccountSavings;

  /// "BAC · Ahorro · •••• 1234".
  String get summary => Formatters.facts([bank, typeLabel, '•••• $last4']);

  static BankAccount? fromApi(Object? value) {
    final json = ApiJson.map(value);
    if (json.isEmpty) return null;
    return BankAccount(
      id: ApiJson.str(json['id']),
      bank: ApiJson.str(json['bank']),
      holder: ApiJson.str(json['holder']),
      accountType: ApiJson.str(json['account_type']),
      last4: ApiJson.str(json['last4']),
      effectiveAt: ApiJson.date(json['effective_at']) ?? DateTime.now(),
    );
  }
}

/// La cuenta que vale hoy y un cambio que espera sus 24 horas.
class BankAccounts {
  const BankAccounts({this.active, this.pending});

  final BankAccount? active;
  final BankAccount? pending;

  factory BankAccounts.fromApi(Map<String, dynamic> json) => BankAccounts(
    active: BankAccount.fromApi(json['active']),
    pending: BankAccount.fromApi(json['pending']),
  );
}

/// En qué va un retiro.
enum PayoutStatus {
  pending,
  paid,
  rejected;

  static PayoutStatus fromApi(Object? value) => switch (value) {
    'paid' => paid,
    'rejected' => rejected,
    _ => pending,
  };

  String get label {
    final l10n = AppStrings.current;
    return switch (this) {
      pending => l10n.guideFinancePayoutPending,
      paid => l10n.guideFinancePayoutPaid,
      rejected => l10n.guideFinancePayoutRejected,
    };
  }
}

/// Un retiro del saldo a la cuenta del guía (`GET /withdrawal/mine/`).
class Payout {
  const Payout({
    required this.id,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.account,
    this.note = '',
  });

  final String id;
  final int amount;
  final PayoutStatus status;
  final DateTime requestedAt;
  final BankAccount? account;

  /// Por qué el equipo lo rechazó.
  final String note;

  factory Payout.fromApi(Map<String, dynamic> json) => Payout(
    id: ApiJson.str(json['id']),
    amount: ApiJson.integer(json['amount']),
    status: PayoutStatus.fromApi(json['status']),
    requestedAt: ApiJson.date(json['requested_at']) ?? DateTime.now(),
    account: BankAccount.fromApi(json['bank_account']),
    note: ApiJson.str(json['note']),
  );
}
