import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/saved_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/event_item.dart';
import '../../../data/models/place.dart';
import '../../../data/models/stop.dart';
import '../../core/base_viewmodel.dart';

/// Circuitos, lugares, paradas y eventos que el usuario guardó con el
/// marcador de [SavedRepository], resueltos contra el catálogo.
class SavedViewModel extends BaseViewModel {
  SavedViewModel(this._tourRepository, this._savedRepository) {
    _savedRepository.addListener(safeNotify);
  }

  final TourRepository _tourRepository;
  final SavedRepository _savedRepository;

  List<Circuit> _circuits = const [];
  List<Place> _places = const [];
  List<Stop> _stops = const [];
  List<EventItem> _events = const [];

  List<Circuit> get savedCircuits => _circuits
      .where((c) => _savedRepository.isSaved(c.id))
      .toList(growable: false);

  List<Place> get savedPlaces => _places
      .where((p) => _savedRepository.isSaved(p.id))
      .toList(growable: false);

  List<Stop> get savedStops => _stops
      .where((s) => _savedRepository.isSaved(s.id))
      .toList(growable: false);

  List<EventItem> get savedEvents => _events
      .where((e) => _savedRepository.isSaved(e.id))
      .toList(growable: false);

  bool get isEmpty =>
      savedCircuits.isEmpty &&
      savedPlaces.isEmpty &&
      savedStops.isEmpty &&
      savedEvents.isEmpty &&
      !isBusy;

  Future<void> load() async {
    setBusy(true);
    clearError();

    final circuitsFuture = _tourRepository.getCircuits();
    final placesFuture = _tourRepository.getFeaturedPlaces();
    final stopsFuture = _tourRepository.getStops();
    final eventsFuture = _tourRepository.getUpcomingEvents();

    switch (await circuitsFuture) {
      case Ok(:final value):
        _circuits = value;
      case Failure(:final message):
        setError(message);
    }
    switch (await placesFuture) {
      case Ok(:final value):
        _places = value;
      case Failure(:final message):
        setError(message);
    }
    switch (await stopsFuture) {
      case Ok(:final value):
        _stops = value;
      case Failure(:final message):
        setError(message);
    }
    switch (await eventsFuture) {
      case Ok(:final value):
        _events = value;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }

  @override
  void dispose() {
    _savedRepository.removeListener(safeNotify);
    super.dispose();
  }
}
