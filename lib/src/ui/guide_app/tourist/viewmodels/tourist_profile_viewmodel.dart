import '../../../../core/utils/result.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// Un turista visto por el guía, con las calificaciones que le dieron otros
/// guías y, si ya viajaron juntos, la opción de calificarlo.
class TouristProfileViewModel extends BaseViewModel {
  TouristProfileViewModel(this._work, this._tourists, this.touristId) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
  }

  final GuideWorkRepository _work;
  final TouristRepository _tourists;
  final String touristId;

  Future<void> load() async {
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    safeNotify();
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  TouristProfile? get tourist => _tourists.byId(touristId);

  /// El viaje terminado que falta calificar; `null` si no hay ninguno.
  GuideTrip? get tripToRate => _tourists.tripToRate(touristId);

  /// Si ya terminaron al menos un viaje juntos.
  bool get hasTravelledTogether =>
      _work.completedTrips.any((trip) => trip.touristId == touristId);

  /// `true` si la calificación quedó guardada.
  Future<bool> rate({required int stars, required String comment}) async {
    final trip = tripToRate;
    if (trip == null || isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _tourists.rate(
      tripId: trip.id,
      stars: stars,
      comment: comment,
    );
    setBusy(false);

    switch (result) {
      case Ok():
        return true;
      case Failure(:final message):
        setError(message);
        return false;
    }
  }

  @override
  void dispose() {
    _work.removeListener(safeNotify);
    _tourists.removeListener(safeNotify);
    super.dispose();
  }
}
