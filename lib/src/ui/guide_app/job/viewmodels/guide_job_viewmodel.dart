import '../../../../core/utils/result.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_job.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// Una propuesta vista por el guía: qué pide, quién la publicó y su
/// postulación.
class GuideJobViewModel extends BaseViewModel {
  GuideJobViewModel(this._work, this._tourists, this.jobId) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
  }

  final GuideWorkRepository _work;
  final TouristRepository _tourists;
  final String jobId;

  Future<void> load() async {
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    safeNotify();
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  GuideJob? get job => _work.jobById(jobId);

  TouristProfile? get tourist {
    final job = this.job;
    return job == null ? null : _tourists.byId(job.touristId);
  }

  /// El viaje que nació de esta propuesta, si el turista lo contrató.
  GuideTrip? get trip => _work.tripForJob(jobId);

  /// `true` si la postulación quedó enviada.
  Future<bool> apply({required num price, required String message}) async {
    if (isBusy) return false;
    clearError();
    setBusy(true);
    final result = await _work.apply(jobId, price: price, message: message);
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
