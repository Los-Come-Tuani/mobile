import '../../../../core/utils/result.dart';
import '../../../../data/datasources/repository/guide_inbox_repository.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// Un viaje del guía: los datos del recorrido, el pago y, si ya terminó, la
/// calificación del turista.
class GuideTripViewModel extends BaseViewModel {
  GuideTripViewModel(this._work, this._tourists, this._inbox, this.tripId) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
    _inbox.addListener(safeNotify);
  }

  final GuideWorkRepository _work;
  final TouristRepository _tourists;
  final GuideInboxRepository _inbox;
  final String tripId;

  Future<void> load() async {
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    safeNotify();
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  GuideTrip? get trip => _work.tripById(tripId);

  TouristProfile? get tourist {
    final trip = this.trip;
    return trip == null ? null : _tourists.byId(trip.touristId);
  }

  bool get hasChat => _inbox.threadFor(tripId) != null;

  /// `true` si la calificación quedó guardada.
  Future<bool> rateTourist({
    required int stars,
    required String comment,
  }) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _tourists.rate(
      tripId: tripId,
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
    _inbox.removeListener(safeNotify);
    super.dispose();
  }
}
