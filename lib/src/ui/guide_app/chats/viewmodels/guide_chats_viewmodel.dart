import '../../../../data/datasources/repository/guide_inbox_repository.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_chat_thread.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// Las conversaciones del guía con sus turistas, una por viaje.
class GuideChatsViewModel extends BaseViewModel {
  GuideChatsViewModel(this._work, this._tourists, this._inbox) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
    _inbox.addListener(safeNotify);
  }

  final GuideWorkRepository _work;
  final TouristRepository _tourists;
  final GuideInboxRepository _inbox;

  /// Las conversaciones de ejemplo llegan con los viajes de la cuenta.
  Future<void> load() async {
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    safeNotify();
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  List<GuideChatThread> get threads => _inbox.threads;

  GuideTrip? tripOf(GuideChatThread thread) => _work.tripById(thread.tripId);

  TouristProfile? touristOf(GuideChatThread thread) =>
      _tourists.byId(thread.touristId);

  @override
  void dispose() {
    _work.removeListener(safeNotify);
    _tourists.removeListener(safeNotify);
    _inbox.removeListener(safeNotify);
    super.dispose();
  }
}
