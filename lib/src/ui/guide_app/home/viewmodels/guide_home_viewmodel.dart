import '../../../../data/datasources/repository/guide_access_repository.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_access_request.dart';
import '../../../../data/models/guide_job.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// El Inicio del guía: su saldo, su próximo viaje y las propuestas que puede
/// tomar.
class GuideHomeViewModel extends BaseViewModel {
  GuideHomeViewModel(this._access, this._work, this._tourists) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
  }

  final GuideAccessRepository _access;
  final GuideWorkRepository _work;
  final TouristRepository _tourists;

  Future<void> load() async {
    setBusy(true);
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    setBusy(false);
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  GuideAccessRequest? get _profile => _access.request;

  String get firstName {
    final name = _profile?.fullName.trim() ?? '';
    return name.isEmpty ? 'guía' : name.split(RegExp(r'\s+')).first;
  }

  bool get isLocal => _profile?.coverage == GuideCoverage.local;

  String? get city => _profile?.certifiedCity;

  String get coverageLabel =>
      (_profile?.coverage ?? GuideCoverage.national).labelFor(city);

  num get available => _work.available;

  num get pending => _work.pending;

  GuideTrip? get nextTrip => _work.nextTrip;

  List<GuideJob> get jobs => _work.availableJobs;

  TouristProfile? touristOf(String id) => _tourists.byId(id);

  GuideTrip? get newHire => _work.newHire;

  void dismissNewHire() => _work.dismissNewHire();

  @override
  void dispose() {
    _work.removeListener(safeNotify);
    _tourists.removeListener(safeNotify);
    super.dispose();
  }
}
