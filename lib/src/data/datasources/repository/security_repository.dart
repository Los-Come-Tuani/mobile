import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../remote/api_client.dart';
import '../remote/api_routes.dart';

/// El estado de la verificación en dos pasos de quien está dentro.
class TwoFactorStatus {
  const TwoFactorStatus({
    required this.enabled,
    required this.pending,
    required this.recoveryCodes,
    this.confirmedAt,
  });

  final bool enabled;

  /// Se empezó a activar pero falta confirmar con un código de la app.
  final bool pending;

  /// Cuántos códigos de recuperación quedan sin usar.
  final int recoveryCodes;
  final DateTime? confirmedAt;

  factory TwoFactorStatus.fromApi(Map<String, dynamic> json) {
    return TwoFactorStatus(
      enabled: json['enabled'] == true,
      pending: json['pending'] == true,
      recoveryCodes: (json['recovery_codes'] as num?)?.toInt() ?? 0,
      confirmedAt: DateTime.tryParse('${json['confirmed_at'] ?? ''}'),
    );
  }
}

/// Lo que entrega empezar a activar el 2FA.
class TwoFactorSetup {
  const TwoFactorSetup({required this.secret, required this.uri});

  /// La clave para escribirla a mano en la app de autenticación.
  final String secret;

  /// `otpauth://...`: es lo que lleva el QR.
  final String uri;
}

/// El segundo factor (TOTP) de la cuenta. Todo exige sesión; los códigos de recuperación
/// solo se muestran una vez, cuando se activa o cuando se piden nuevos.
class SecurityRepository {
  Future<Result<TwoFactorStatus>> status() => _call('status', () async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiRoutes.twoFactorStatus,
    );
    return TwoFactorStatus.fromApi(response.data ?? const {});
  });

  /// Empieza a activar el 2FA. Hasta confirmar con un código, no exige nada al entrar.
  Future<Result<TwoFactorSetup>> startSetup() => _call('startSetup', () async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiRoutes.twoFactorSetup,
    );
    final body = response.data ?? const {};
    final secret = body['secret'];
    final uri = body['uri'];
    if (secret is! String || uri is! String) {
      throw const FormatException('Respuesta inesperada del servidor');
    }
    return TwoFactorSetup(secret: secret, uri: uri);
  });

  /// Activa el 2FA con el código que muestra la app y devuelve los códigos de recuperación.
  Future<Result<List<String>>> confirm(String code) =>
      _call('confirm', () async {
        final response = await ApiClient.instance.post<Map<String, dynamic>>(
          ApiRoutes.twoFactorConfirm,
          data: {'code': code.trim()},
        );
        return _codesOf(response.data);
      });

  /// Reemplaza los códigos de recuperación por diez nuevos; los anteriores dejan de servir.
  Future<Result<List<String>>> regenerateCodes(String code) =>
      _call('regenerateCodes', () async {
        final response = await ApiClient.instance.post<Map<String, dynamic>>(
          ApiRoutes.twoFactorRecovery,
          data: {'code': code.trim()},
        );
        return _codesOf(response.data);
      });

  Future<Result<void>> disable({
    required String code,
    required String password,
  }) => _call('disable', () async {
    await ApiClient.instance.post<void>(
      ApiRoutes.twoFactorDisable,
      data: {'code': code.trim(), 'password': password},
    );
  });

  List<String> _codesOf(Map<String, dynamic>? body) {
    final codes = body?['codes'];
    if (codes is! List) {
      throw const FormatException('Respuesta inesperada del servidor');
    }
    return [for (final code in codes) '$code'];
  }

  Future<Result<T>> _call<T>(String name, Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e, st) {
      log.e('$name: ${e.message}', error: e, stackTrace: st);
      final fields = ApiClient.fieldErrors(e);
      final reason = e.response?.statusCode == 400 && fields.length == 1
          ? fields.values.first
          : null;
      return Result.failure(reason ?? ApiClient.describeError(e), e);
    } catch (e, st) {
      log.e('$name: $e', error: e, stackTrace: st);
      return Result.failure('Algo salió mal, intenta de nuevo', e);
    }
  }
}
