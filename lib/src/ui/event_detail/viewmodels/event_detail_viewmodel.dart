import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/models/event_item.dart';
import '../../core/base_viewmodel.dart';

/// Detalle de un evento próximo.
class EventDetailViewModel extends BaseViewModel {
  EventDetailViewModel(this._tourRepository, this.eventId);

  final TourRepository _tourRepository;
  final String eventId;

  EventItem? _event;
  EventItem? get event => _event;

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getEventById(eventId)) {
      case Ok(:final value):
        _event = value;
      case Failure(:final message):
        setError(message);
    }

    setBusy(false);
    safeNotify();
  }
}
