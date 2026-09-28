enum WithdrawalStatus { processing, deposited }

/// Un retiro del balance del guía a su cuenta bancaria.
class GuideWithdrawal {
  const GuideWithdrawal({
    required this.id,
    required this.amount,
    required this.requestedAt,
    required this.status,
  });

  factory GuideWithdrawal.fromJson(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    return GuideWithdrawal(
      id: json['id'] as String,
      amount: json['amount'] as num? ?? 0,
      requestedAt: now.subtract(Duration(days: json['daysAgo'] as int? ?? 0)),
      status: WithdrawalStatus.deposited,
    );
  }

  final String id;
  final num amount;
  final DateTime requestedAt;
  final WithdrawalStatus status;

  GuideWithdrawal copyWith({WithdrawalStatus? status}) {
    return GuideWithdrawal(
      id: id,
      amount: amount,
      requestedAt: requestedAt,
      status: status ?? this.status,
    );
  }
}
