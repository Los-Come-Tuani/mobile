import '../../../data/datasources/repository/auth_repository.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/saved_repository.dart';
import '../../../data/models/user.dart';
import '../../core/base_viewmodel.dart';

/// Datos de la pantalla de perfil: usuario y sus contadores rápidos.
class ProfileViewModel extends BaseViewModel {
  ProfileViewModel(
    this._authRepository,
    this._collectionsRepository,
    this._savedRepository,
    this._badgesRepository,
  ) {
    _collectionsRepository.addListener(safeNotify);
    _savedRepository.addListener(safeNotify);
    _badgesRepository.addListener(safeNotify);
  }

  final AuthRepository _authRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final SavedRepository _savedRepository;
  final BadgesRepository _badgesRepository;

  User? get user => _authRepository.currentUser;

  /// Circuitos que el usuario armó desde una parada.
  int get myCircuitsCount => _collectionsRepository.userCollections.length;

  /// Circuitos y lugares que el usuario marcó como guardados.
  int get savedCount => _savedRepository.savedIds.length;

  /// Insignias ganadas en total (histórico, lo que definen las medallas).
  int get badgesCount => _badgesRepository.earnedTotal;

  Future<void> logout() => _authRepository.logout();

  @override
  void dispose() {
    _collectionsRepository.removeListener(safeNotify);
    _savedRepository.removeListener(safeNotify);
    _badgesRepository.removeListener(safeNotify);
    super.dispose();
  }
}
