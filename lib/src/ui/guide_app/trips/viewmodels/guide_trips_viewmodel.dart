import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// Los viajes del guía: los que vienen y los que ya hizo.
class GuideTripsViewModel extends BaseViewModel {
  GuideTripsViewModel(this._work, this._tourists) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
  }

  final GuideWorkRepository _work;
  final TouristRepository _tourists;

  Future<void> load() async {
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    safeNotify();
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  List<GuideTrip> get upcoming => _work.upcomingTrips;

  List<GuideTrip> get completed => _work.completedTrips;

  /// Viajes terminados cuyo turista falta calificar.
  int get pendingRatings => completed.where((t) => t.canRateTourist).length;

  TouristProfile? touristOf(String id) => _tourists.byId(id);

  @override
  void dispose() {
    _work.removeListener(safeNotify);
    _tourists.removeListener(safeNotify);
    super.dispose();
  }
}
