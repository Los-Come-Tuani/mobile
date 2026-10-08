import '../../core/utils/api_json.dart';
import 'stop.dart';

/// El saldo de insignias del turista en el API (`GET /badge/mine/`).
class BadgeSummary {
  const BadgeSummary({
    required this.balance,
    required this.earned,
    required this.spent,
    required this.byCategory,
    required this.visitedPointIds,
  });

  /// Lo que puede gastar en cupones ahora.
  final int balance;

  /// Lo ganado de por vida (no baja al canjear).
  final int earned;
  final int spent;

  /// Lo ganado por pilar, con la clave de categoría de la app ("Historia").
  final Map<String, int> byCategory;

  /// Los lugares donde ya ganó la insignia.
  final Set<String> visitedPointIds;

  factory BadgeSummary.fromApi(Map<String, dynamic> json) => BadgeSummary(
    balance: ApiJson.integer(json['balance']),
    earned: ApiJson.integer(json['earned']),
    spent: ApiJson.integer(json['spent']),
    byCategory: {
      for (final row in ApiJson.rows(json['by_pillar']))
        Stop.categoryOfPillar(
          ApiJson.strOrNull(row['code']),
          ApiJson.str(row['label']),
        ): ApiJson.integer(
          row['count'],
        ),
    },
    visitedPointIds: {
      for (final id in json['visited_point_ids'] as List? ?? const []) '$id',
    },
  );
}

/// Lo que responde `POST /visit/`: la insignia que se acreditó.
class VisitResult {
  const VisitResult({
    required this.pointId,
    required this.pointName,
    required this.category,
    required this.amount,
    required this.balance,
    required this.distanceMeters,
  });

  final String pointId;
  final String pointName;

  /// La clave de categoría de la app para el pilar del lugar.
  final String category;
  final int amount;
  final int balance;
  final int distanceMeters;

  factory VisitResult.fromApi(Map<String, dynamic> json) {
    final point = ApiJson.map(json['point']);
    final pillar = ApiJson.map(point['pillar']);
    return VisitResult(
      pointId: ApiJson.str(point['id']),
      pointName: ApiJson.str(point['name']),
      category: Stop.categoryOfPillar(
        ApiJson.strOrNull(pillar['code']),
        ApiJson.str(pillar['label']),
      ),
      amount: ApiJson.integer(json['amount']),
      balance: ApiJson.integer(json['balance']),
      distanceMeters: ApiJson.integer(json['distance_meters']),
    );
  }
}
