import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../../models/guide_access_request.dart';
import 'auth_repository.dart';

/// El acceso de guía de cada cuenta: si todavía no se postula, si su
/// solicitud está en revisión o si ya puede entrar como guía.
///
/// El portal donde el equipo de K'Plan revisa las solicitudes todavía no
/// existe, así que la revisión se simula: cada solicitud queda en revisión
/// durante [reviewTime] y después se aprueba sola.
class GuideAccessRepository extends ChangeNotifier {
  GuideAccessRepository(
    this._authRepository, {
    this.reviewTime = const Duration(minutes: 1),
  });

  final AuthRepository _authRepository;

  /// Cuánto tarda la revisión simulada.
  final Duration reviewTime;

  /// Por correo y no por id: en la demo todas las sesiones comparten id.
  final Map<String, ({GuideAccessRequest request, GuideAccessStatus status})>
  _byAccount = {};
  final Map<String, Timer> _reviews = {};

  String? get _account =>
      _authRepository.currentUser?.email.trim().toLowerCase();

  /// En qué va la cuenta con sesión iniciada.
  GuideAccessStatus get status =>
      _byAccount[_account]?.status ?? GuideAccessStatus.none;

  /// Lo que envió la cuenta con sesión iniciada, si ya se postuló.
  GuideAccessRequest? get request => _byAccount[_account]?.request;

  /// Envía [request] a revisión a nombre de la cuenta con sesión iniciada.
  Future<Result<void>> submit(GuideAccessRequest request) async {
    final account = _account;
    if (account == null) {
      return const Result.failure('Inicia sesión para enviar tu solicitud');
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    _byAccount[account] = (request: request, status: GuideAccessStatus.pending);
    _reviews[account]?.cancel();
    _reviews[account] = Timer(reviewTime, () => _approve(account));
    notifyListeners();
    return const Result.ok(null);
  }

  void _approve(String account) {
    _reviews.remove(account);
    final entry = _byAccount[account];
    if (entry == null) return;
    _byAccount[account] = (
      request: entry.request,
      status: GuideAccessStatus.approved,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final review in _reviews.values) {
      review.cancel();
    }
    _reviews.clear();
    super.dispose();
  }
}
