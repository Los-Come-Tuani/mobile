import '../../../data/datasources/repository/badges_repository.dart';
import '../../core/base_viewmodel.dart';

/// Medallas del usuario: se calculan sobre el histórico de insignias
/// ganadas, que no baja aunque se gasten insignias en cupones.
class MedalsViewModel extends BaseViewModel {
  MedalsViewModel(this._badgesRepository) {
    _badgesRepository.addListener(safeNotify);
  }

  final BadgesRepository _badgesRepository;

  int get earnedTotal => _badgesRepository.earnedTotal;
  int get availableTotal => _badgesRepository.availableTotal;
  int get spentTotal => _badgesRepository.spentTotal;

  int earnedIn(String category) => _badgesRepository.earnedIn(category);

  @override
  void dispose() {
    _badgesRepository.removeListener(safeNotify);
    super.dispose();
  }
}
