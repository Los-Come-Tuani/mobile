import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/app_notification.dart';
import '../remote/api_call.dart';
import '../remote/api_client.dart';
import '../remote/notifications_api.dart';
import '../remote/push_service.dart';
import 'auth_repository.dart';

/// La bandeja de avisos de la cuenta y sus preferencias (`docs/avisos.md`).
///
/// Solo con el API: en la demo no hay avisos. Con sesión, cuenta los no
/// leídos cada [pollEvery] para el punto de la campana, y registra el
/// teléfono para el envío por push si el [PushService] da un token (hoy
/// [NoPushService]: no hay proyecto de Firebase). Al cerrar sesión, quien la
/// cierre debe llamar antes a [unregisterDevice].
class NotificationsRepository extends ChangeNotifier {
  NotificationsRepository({
    AuthRepository? auth,
    PushService push = const NoPushService(),
    this.pollEvery = const Duration(minutes: 1),
  }) : _auth = auth,
       _push = push {
    auth?.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  final AuthRepository? _auth;
  final PushService _push;
  final Duration pollEvery;

  String? _account;
  bool _isDisposed = false;
  Timer? _poll;
  StreamSubscription<String>? _tokenChanges;
  String? _deviceToken;

  List<AppNotification> _items = const [];
  int _unreadCount = 0;
  int _page = 1;
  bool _hasMore = false;
  List<NotificationPreference> _preferences = const [];

  /// Del más nuevo al más viejo.
  List<AppNotification> get items => _items;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;
  List<NotificationPreference> get preferences => _preferences;

  bool get _active => ApiClient.isConfigured && (_auth?.isLoggedIn ?? false);

  /// La primera página de la bandeja.
  Future<Result<void>> load() async {
    final result = await apiCall('notifications', NotificationsApi.page);
    if (_isDisposed) return const Result.ok(null);
    switch (result) {
      case Ok(:final value):
        _items = value.items;
        _page = 1;
        _hasMore = value.hasMore;
        notifyListeners();
        unawaited(refreshUnread());
        return const Result.ok(null);
      case Failure(:final message, :final error):
        return Result.failure(message, error);
    }
  }

  /// La página siguiente.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final next = _page + 1;
    final result = await apiCall(
      'notifications',
      () => NotificationsApi.page(page: next),
    );
    if (_isDisposed) return;
    if (result case Ok(:final value)) {
      final known = {for (final item in _items) item.id};
      _items = [..._items, ...value.items.where((n) => known.add(n.id))];
      _page = next;
      _hasMore = value.hasMore;
      notifyListeners();
    }
  }

  /// Cuántos avisos faltan por leer (el punto de la campana).
  Future<void> refreshUnread() async {
    if (!ApiClient.isConfigured) return;
    final result = await apiCall('unreadCount', NotificationsApi.unreadCount);
    if (_isDisposed) return;
    if (result case Ok(:final value) when value != _unreadCount) {
      _unreadCount = value;
      notifyListeners();
    }
  }

  Future<Result<AppNotification>> markRead(AppNotification notification) async {
    if (notification.read) return Result.ok(notification);
    _replace(notification.markedRead());
    _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
    notifyListeners();
    final result = await apiCall(
      'markRead',
      () => NotificationsApi.markRead(notification.id),
    );
    if (_isDisposed) return result;
    if (result case Ok(:final value)) _replace(value);
    unawaited(refreshUnread());
    return result;
  }

  Future<Result<void>> markAllRead() async {
    final result = await apiCall('markAllRead', NotificationsApi.markAllRead);
    if (_isDisposed) return result;
    if (result case Ok()) {
      _items = [for (final item in _items) item.markedRead()];
      _unreadCount = 0;
      notifyListeners();
    }
    return result;
  }

  Future<Result<List<NotificationPreference>>> loadPreferences() async {
    final result = await apiCall(
      'notificationPreferences',
      NotificationsApi.preferences,
    );
    if (_isDisposed) return result;
    if (result case Ok(:final value)) {
      _preferences = value;
      notifyListeners();
    }
    return result;
  }

  /// Enciende o apaga el envío al teléfono de [kind]; si el API falla, vuelve
  /// a como estaba.
  Future<Result<List<NotificationPreference>>> setPush(
    String kind,
    bool enabled,
  ) async {
    final before = _preferences;
    _preferences = [
      for (final preference in _preferences)
        preference.kind == kind
            ? preference.copyWith(pushEnabled: enabled)
            : preference,
    ];
    notifyListeners();
    final result = await apiCall(
      'savePreferences',
      () => NotificationsApi.savePreferences([
        for (final preference in _preferences)
          if (preference.kind == kind) preference,
      ]),
    );
    if (_isDisposed) return result;
    switch (result) {
      case Ok(:final value) when value.isNotEmpty:
        _preferences = value;
      case Ok():
        break;
      case Failure():
        _preferences = before;
    }
    notifyListeners();
    return result;
  }

  // ── El teléfono ───────────────────────────────────────────────────────────

  /// Registra este teléfono para el envío por push, si hay token.
  Future<void> registerDevice() async {
    if (!_active) return;
    final token = await _push.token();
    if (token == null || token.length < 10) return;
    _deviceToken = token;
    await apiCall(
      'registerDevice',
      () => NotificationsApi.registerDevice(token, _push.platform),
    );
  }

  /// Saca este teléfono de la cuenta. Va antes de cerrar la sesión.
  Future<void> unregisterDevice() async {
    final token = _deviceToken ?? await _push.token();
    _deviceToken = null;
    if (!_active || token == null || token.length < 10) return;
    await apiCall('removeDevice', () => NotificationsApi.removeDevice(token));
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  void _replace(AppNotification notification) {
    _items = [
      for (final item in _items)
        item.id == notification.id ? notification : item,
    ];
  }

  void _onSessionChanged() {
    final account = _auth?.currentUser?.id;
    if (account == _account) return;
    _account = account;
    _items = const [];
    _unreadCount = 0;
    _hasMore = false;
    _preferences = const [];
    _poll?.cancel();
    _poll = null;
    unawaited(_tokenChanges?.cancel());
    _tokenChanges = null;
    if (!_isDisposed) notifyListeners();
    if (!_active) return;

    unawaited(refreshUnread());
    unawaited(registerDevice());
    _tokenChanges = _push.tokenChanges.listen((_) => registerDevice());
    _poll = Timer.periodic(pollEvery, (_) => unawaited(refreshUnread()));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _poll?.cancel();
    unawaited(_tokenChanges?.cancel());
    _auth?.removeListener(_onSessionChanged);
    super.dispose();
  }
}
