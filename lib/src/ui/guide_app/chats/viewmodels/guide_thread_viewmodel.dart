import '../../../../data/datasources/repository/guide_inbox_repository.dart';
import '../../../../data/datasources/repository/guide_work_repository.dart';
import '../../../../data/datasources/repository/tourist_repository.dart';
import '../../../../data/models/guide_chat_message.dart';
import '../../../../data/models/guide_trip.dart';
import '../../../../data/models/tourist_profile.dart';
import '../../../core/base_viewmodel.dart';

/// La conversación del guía con el turista de un viaje.
class GuideThreadViewModel extends BaseViewModel {
  GuideThreadViewModel(this._work, this._tourists, this._inbox, this.tripId) {
    _work.addListener(safeNotify);
    _tourists.addListener(safeNotify);
    _inbox.addListener(safeNotify);
  }

  final GuideWorkRepository _work;
  final TouristRepository _tourists;
  final GuideInboxRepository _inbox;
  final String tripId;

  /// Al abrirla, lo que llega deja de contar como no leído.
  Future<void> load() async {
    await Future.wait([_work.ensureLoaded(), _tourists.ensureLoaded()]);
    _inbox.setActive(tripId);
    safeNotify();
  }

  bool get isLoaded => _work.isLoaded && _tourists.isLoaded;

  GuideTrip? get trip => _work.tripById(tripId);

  TouristProfile? get tourist {
    final trip = this.trip;
    return trip == null ? null : _tourists.byId(trip.touristId);
  }

  List<GuideChatMessage> get messages =>
      _inbox.threadFor(tripId)?.messages ?? const [];

  void send(String text) => _inbox.send(tripId, text);

  @override
  void dispose() {
    _inbox.setActive(null);
    _work.removeListener(safeNotify);
    _tourists.removeListener(safeNotify);
    _inbox.removeListener(safeNotify);
    super.dispose();
  }
}
