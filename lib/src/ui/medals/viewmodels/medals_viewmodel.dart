import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/badges_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../core/base_viewmodel.dart';

/// Medallas del usuario: se calculan sobre el histórico de insignias
/// ganadas, que no baja aunque se gasten insignias en cupones. También
/// lista las medallas de ciudad creativa, ganadas al completar un circuito
/// creativo de esa ciudad.
class MedalsViewModel extends BaseViewModel {
  MedalsViewModel(this._badgesRepository, this._tourRepository) {
    _badgesRepository.addListener(safeNotify);
  }

  final BadgesRepository _badgesRepository;
  final TourRepository _tourRepository;

  List<String> _creativeCircuitCities = const [];

  int get earnedTotal => _badgesRepository.earnedTotal;
  int get availableTotal => _badgesRepository.availableTotal;
  int get spentTotal => _badgesRepository.spentTotal;

  int earnedIn(String category) => _badgesRepository.earnedIn(category);

  /// Ciudades creativas del catálogo, en el orden en que aparecen los
  /// circuitos.
  List<String> get creativeCircuitCities => _creativeCircuitCities;

  bool hasCityMedal(String city) => _badgesRepository.hasCityMedal(city);

  Future<void> load() async {
    switch (await _tourRepository.getCircuits()) {
      case Ok(:final value):
        final cities = <String>[];
        for (final circuit in value) {
          if (circuit.isCreativeCircuit && !cities.contains(circuit.city)) {
            cities.add(circuit.city);
          }
        }
        _creativeCircuitCities = cities;
        safeNotify();
      case Failure():
        // Sin catálogo simplemente no se muestra la sección de ciudades.
        break;
    }
  }

  @override
  void dispose() {
    _badgesRepository.removeListener(safeNotify);
    super.dispose();
  }
}
