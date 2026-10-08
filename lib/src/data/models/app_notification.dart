import '../../core/utils/api_json.dart';

/// Un aviso de la bandeja de la cuenta (`docs/avisos.md`). [data] dice a qué
/// pantalla lleva: `booking_id`, `request_id`, `withdrawal_id`, `review_id`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;

  /// `mensaje`, `reserva`, `convocatoria`, `resena`, `pago` o `cuenta`.
  final String kind;
  final String title;
  final String body;
  final Map<String, String> data;
  final bool read;
  final DateTime createdAt;

  String? get bookingId => data['booking_id'];
  String? get requestId => data['request_id'];
  String? get withdrawalId => data['withdrawal_id'];
  String? get reviewId => data['review_id'];

  AppNotification markedRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    data: data,
    read: true,
    createdAt: createdAt,
  );

  factory AppNotification.fromApi(Map<String, dynamic> json) => AppNotification(
    id: ApiJson.str(json['id']),
    kind: ApiJson.str(json['kind']),
    title: ApiJson.str(json['title']),
    body: ApiJson.str(json['body']),
    data: {
      for (final entry in ApiJson.map(json['data']).entries)
        if (entry.value != null) entry.key: '${entry.value}',
    },
    read: json['read'] == true,
    createdAt: ApiJson.date(json['created_at']) ?? DateTime.now(),
  );
}

/// Si una clase de aviso sale al teléfono. Apagarla no la saca de la bandeja.
class NotificationPreference {
  const NotificationPreference({
    required this.kind,
    required this.label,
    required this.pushEnabled,
  });

  final String kind;

  /// Viene del API, en español.
  final String label;
  final bool pushEnabled;

  NotificationPreference copyWith({bool? pushEnabled}) =>
      NotificationPreference(
        kind: kind,
        label: label,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );

  factory NotificationPreference.fromApi(Map<String, dynamic> json) =>
      NotificationPreference(
        kind: ApiJson.str(json['kind']),
        label: ApiJson.str(json['label']),
        pushEnabled: json['push_enabled'] != false,
      );
}
