import 'package:flutter/foundation.dart';

/// El envío de avisos al teléfono. El API manda por Firebase Cloud Messaging,
/// pero el proyecto de Firebase todavía no existe: la app usa [NoPushService]
/// y los avisos solo llegan a la bandeja. Para encenderlo hace falta una
/// implementación con `firebase_messaging` y el `google-services.json` del
/// mismo proyecto que use el API.
abstract class PushService {
  /// `android`, `ios` o `web`, como lo espera `POST /device-token/`.
  String get platform;

  /// El token de este teléfono; `null` si no hay push o no dio permiso.
  Future<String?> token();

  /// Cuando el servicio cambia el token.
  Stream<String> get tokenChanges;
}

/// Sin push: no hay token y nunca cambia.
class NoPushService implements PushService {
  const NoPushService();

  @override
  String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    _ => 'android',
  };

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenChanges => const Stream.empty();
}
