import '../../../core/utils/api_json.dart';
import '../../models/app_notification.dart';
import 'api_call.dart';
import 'api_routes.dart';

/// La bandeja de avisos, las preferencias y los teléfonos registrados
/// (`docs/avisos.md` del repo del API). Cualquier sesión.
abstract final class NotificationsApi {
  /// Una página de avisos, del más nuevo; con [unread], solo los no leídos.
  static Future<({List<AppNotification> items, int total, bool hasMore})> page({
    int page = 1,
    int pageSize = 30,
    bool unread = false,
  }) async {
    final body = await ApiRows.one(
      ApiRoutes.notifications,
      query: {'page': page, 'page_size': pageSize, if (unread) 'unread': true},
    );
    return (
      items: [
        for (final row in ApiJson.rows(body['results']))
          AppNotification.fromApi(row),
      ],
      total: ApiJson.integer(body['elements']),
      hasMore: body['next'] == true,
    );
  }

  /// Cuántos no se han leído (`elements` de `?unread=true`).
  static Future<int> unreadCount() async =>
      (await page(pageSize: 1, unread: true)).total;

  static Future<AppNotification> markRead(String id) async =>
      AppNotification.fromApi(
        await ApiRows.post(ApiRoutes.notificationRead(id)),
      );

  static Future<void> markAllRead() async {
    await ApiRows.post(ApiRoutes.notificationsReadAll);
  }

  static Future<List<NotificationPreference>> preferences() async {
    final rows = await ApiRows.list(ApiRoutes.notificationPreferences);
    return [for (final row in rows) NotificationPreference.fromApi(row)];
  }

  /// Solo cambia las que llegan.
  static Future<List<NotificationPreference>> savePreferences(
    List<NotificationPreference> preferences,
  ) async {
    final body = await ApiRows.put(ApiRoutes.notificationPreferences, {
      'preferences': [
        for (final preference in preferences)
          {'kind': preference.kind, 'push_enabled': preference.pushEnabled},
      ],
    });
    return [
      for (final row in ApiJson.rows(body)) NotificationPreference.fromApi(row),
    ];
  }

  /// Al iniciar sesión y cada vez que el servicio de push da otro token.
  static Future<void> registerDevice(String token, String platform) async {
    await ApiRows.post(ApiRoutes.deviceToken, {
      'token': token,
      'platform': platform,
    });
  }

  /// Al cerrar sesión, antes de borrar los tokens de la sesión.
  static Future<void> removeDevice(String token) async {
    await ApiRows.post(ApiRoutes.deviceTokenRemove, {'token': token});
  }
}
