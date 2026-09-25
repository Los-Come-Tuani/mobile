import '../../../core/utils/formatters.dart';
import '../../../core/utils/itinerary_advisor.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/repository/circuit_collections_repository.dart';
import '../../../data/datasources/repository/tour_repository.dart';
import '../../../data/datasources/repository/visit_log_repository.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/visit_event.dart';
import '../../core/base_viewmodel.dart';

/// En qué pregunta va la conversación.
enum AssistantStep {
  city,
  pace,
  mode,
  startTime,
  interests,
  thinking,
  proposal,
}

/// Un mensaje del chat: del asistente o lo que respondió el turista.
class AssistantMessage {
  const AssistantMessage(this.text, {this.fromAssistant = true});

  final String text;
  final bool fromAssistant;
}

/// El asistente que arma o reorganiza un día: pregunta cómo lo quiere el
/// turista, calcula el itinerario y propone cambios que puede aplicar uno a
/// uno antes de guardarlo en su circuito.
///
/// No hay un modelo de IA real: la conversación es guionada y las
/// sugerencias salen de [ItineraryAdvisor].
class ItineraryAssistantViewModel extends BaseViewModel {
  ItineraryAssistantViewModel(
    this._tourRepository,
    this._collectionsRepository,
    this._visitLogRepository, {
    this.collectionId,
    this.thinkingDelay = const Duration(milliseconds: 1500),
    DateTime Function()? today,
  }) : _today = today ?? DateTime.now;

  final TourRepository _tourRepository;
  final CircuitCollectionsRepository _collectionsRepository;
  final VisitLogRepository _visitLogRepository;

  /// El circuito propio que se va a reorganizar; `null` si se arma desde
  /// cero.
  final String? collectionId;

  /// Cuánto "piensa" antes de proponer, para que se sienta un asistente.
  final Duration thinkingDelay;
  final DateTime Function() _today;

  static const List<String> startTimeOptions = [
    '7:00 a.m.',
    '8:00 a.m.',
    '9:00 a.m.',
    '10:00 a.m.',
    '1:00 p.m.',
  ];

  static const List<String> interestOptions = [
    'Historia',
    'Cultura',
    'Gastronomía',
    'Naturaleza',
    'Aventura',
  ];

  AssistantStep _step = AssistantStep.pace;
  final List<AssistantMessage> _messages = [];
  List<Stop> _allStops = const [];
  String _title = '';
  String _city = '';
  List<Stop> _stops = [];
  List<String> _originalStopIds = const [];
  ItineraryPreferences _preferences = const ItineraryPreferences();
  final Set<String> _interests = {};
  final Set<String> _dismissed = {};
  final List<String> _applied = [];
  final Map<String, DropReason> _removed = {};
  List<ItinerarySuggestion> _suggestions = const [];

  bool get startsFromScratch => collectionId == null;
  AssistantStep get step => _step;
  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  String get city => _city;
  ItineraryPreferences get preferences => _preferences;
  Set<String> get selectedInterests => Set.unmodifiable(_interests);

  /// Lo que el turista ya aplicó, para mostrarlo bajo la propuesta.
  List<String> get appliedChanges => List.unmodifiable(_applied);
  List<ItinerarySuggestion> get suggestions => _suggestions;

  /// Ciudades con paradas en el catálogo, en orden alfabético.
  List<String> get cities {
    final cities = {
      for (final stop in _allStops)
        if (stop.city.isNotEmpty) stop.city,
    }.toList()..sort();
    return cities;
  }

  /// El día como va quedando; `null` mientras no haya paradas.
  Itinerary? get itinerary =>
      _stops.isEmpty ? null : ItineraryAdvisor.plan(_stops, _preferences, _day);

  bool get canSave => _step == AssistantStep.proposal && _stops.isNotEmpty;

  DateTime get _day {
    final today = _today();
    return DateTime(today.year, today.month, today.day);
  }

  Future<void> load() async {
    setBusy(true);
    clearError();

    switch (await _tourRepository.getStops()) {
      case Ok(:final value):
        _allStops = value;
      case Failure(:final message):
        setError(message);
    }

    final id = collectionId;
    if (id == null) {
      _say(
        '¡Hola! Soy el asistente de K\'Plan. Te armo un día con horarios '
        'reales, contando los traslados entre cada lugar.',
      );
      _ask(AssistantStep.city);
    } else {
      await _collectionsRepository.ensureLoaded();
      final collection = _collectionsRepository.findById(id);
      final ids = collection?.stopIds ?? const <String>[];
      _title = collection?.title ?? '';
      _originalStopIds = ids;
      _stops = [
        for (final stopId in ids)
          ?_allStops.where((s) => s.id == stopId).firstOrNull,
      ];
      _city = _mainCity(_stops);
      if (collection != null) {
        _preferences = _preferences.copyWith(
          pace: collection.pace,
          mode: collection.travelMode,
          startTime: collection.startTime,
        );
      }
      _say(
        '¡Hola! Soy el asistente de K\'Plan. Voy a organizar "$_title" '
        '(${_stops.length} ${_stops.length == 1 ? 'parada' : 'paradas'}) '
        'contando los traslados y los horarios de cada lugar.',
      );
      _ask(AssistantStep.pace);
    }

    setBusy(false);
    safeNotify();
  }

  void chooseCity(String city) {
    if (_step != AssistantStep.city) return;
    _city = city;
    _reply(city);
    _ask(AssistantStep.pace);
  }

  void choosePace(ItineraryPace pace) {
    if (_step != AssistantStep.pace) return;
    _preferences = _preferences.copyWith(pace: pace);
    _reply(pace.label);
    _ask(AssistantStep.mode);
  }

  void chooseMode(TravelMode mode) {
    if (_step != AssistantStep.mode) return;
    _preferences = _preferences.copyWith(mode: mode);
    _reply(mode.label);
    _ask(AssistantStep.startTime);
  }

  void chooseStartTime(String time) {
    if (_step != AssistantStep.startTime) return;
    _preferences = _preferences.copyWith(startTime: time);
    _reply(time);
    _ask(AssistantStep.interests);
  }

  void toggleInterest(String category) {
    if (_step != AssistantStep.interests) return;
    if (!_interests.remove(category)) _interests.add(category);
    safeNotify();
  }

  /// Cierra las preguntas, "piensa" y propone el día.
  Future<void> confirmInterests() async {
    if (_step != AssistantStep.interests) return;
    _preferences = _preferences.copyWith(interests: {..._interests});
    _reply(_interests.isEmpty ? 'Me da igual' : _interests.join(', '));
    _step = AssistantStep.thinking;
    safeNotify();

    await Future<void>.delayed(thinkingDelay);

    if (startsFromScratch) {
      _stops = ItineraryAdvisor.seed(
        cityStops: _candidates,
        preferences: _preferences,
        day: _day,
      );
    }
    _refreshSuggestions();
    _say(_proposalIntro());
    _step = AssistantStep.proposal;
    safeNotify();
  }

  void apply(ItinerarySuggestion suggestion) {
    if (_step != AssistantStep.proposal) return;

    switch (suggestion) {
      case SwitchToVehicleSuggestion():
        _preferences = _preferences.copyWith(mode: TravelMode.vehicle);
        _applied.add('Te mueves en vehículo');
      case ReorderSuggestion(:final stopIds, :final saved):
        _stops = [
          for (final id in stopIds) _stops.firstWhere((s) => s.id == id),
        ];
        _applied.add(
          'Cambiaste el orden: ahorras ${Formatters.duration(saved)}',
        );
      case StartLaterSuggestion(:final startTime):
        _preferences = _preferences.copyWith(startTime: startTime);
        _applied.add('Sales a las $startTime');
      case RemoveStopSuggestion(:final stop, :final reason):
        _stops = [
          for (final s in _stops)
            if (s.id != stop.id) s,
        ];
        if (_originalStopIds.contains(stop.id)) _removed[stop.id] = reason;
        _applied.add('Quitaste ${stop.name}');
      case AddStopSuggestion(:final stop, :final index, :final isLunch):
        _stops = [..._stops]..insert(index.clamp(0, _stops.length), stop);
        _removed.remove(stop.id);
        _applied.add(
          isLunch ? 'Almuerzas en ${stop.name}' : 'Agregaste ${stop.name}',
        );
    }
    _refreshSuggestions();
    safeNotify();
  }

  void dismiss(ItinerarySuggestion suggestion) {
    _dismissed.add(suggestion.key);
    _refreshSuggestions();
    safeNotify();
  }

  /// Guarda el día en el circuito (o lo crea, si se armó desde cero) y
  /// registra por qué se quitaron paradas que el turista había elegido.
  /// Devuelve el id del circuito, o `null` si no hay nada que guardar.
  String? save() {
    if (!canSave) return null;

    final stopIds = [for (final stop in _stops) stop.id];
    final id =
        collectionId ??
        _collectionsRepository
            .createCollection('Mi día en $_city', stopIds: stopIds)
            .id;
    _collectionsRepository.updatePlan(
      id,
      stopIds: stopIds,
      startTime: _preferences.startTime,
      travelMode: _preferences.mode,
      pace: _preferences.pace,
    );
    for (final entry in _removed.entries) {
      _visitLogRepository.recordDrop(
        stopId: entry.key,
        circuitId: id,
        reason: entry.value,
        stage: DropStage.planning,
      );
    }
    return id;
  }

  /// Paradas de la ciudad del recorrido: las únicas que se combinan.
  List<Stop> get _candidates =>
      _allStops.where((s) => s.city == _city).toList(growable: false);

  void _refreshSuggestions() {
    _suggestions = ItineraryAdvisor.suggest(
      stops: _stops,
      candidates: _candidates,
      preferences: _preferences,
      day: _day,
      dismissed: _dismissed,
    );
  }

  String _proposalIntro() {
    if (_stops.isEmpty) {
      return 'No encontré paradas en $_city que quepan en tu día. Prueba con '
          'otro ritmo o una hora más temprano.';
    }
    final count =
        '${_stops.length} ${_stops.length == 1 ? 'parada' : 'paradas'}';
    return startsFromScratch
        ? 'Listo. Te armé un día en $_city con $count, en el orden que menos '
              'traslado pide.'
        : 'Listo. Calculé cada traslado y la hora a la que llegas a tus '
              '$count.';
  }

  void _ask(AssistantStep step) {
    _step = step;
    _say(switch (step) {
      AssistantStep.city => '¿A qué ciudad vas?',
      AssistantStep.pace => '¿Cómo quieres tu día?',
      AssistantStep.mode => '¿Cómo te vas a mover?',
      AssistantStep.startTime => '¿A qué hora quieres empezar?',
      AssistantStep.interests =>
        '¿Qué te interesa más? Puedes elegir varias cosas.',
      AssistantStep.thinking || AssistantStep.proposal => '',
    });
    safeNotify();
  }

  void _say(String text) {
    if (text.isNotEmpty) _messages.add(AssistantMessage(text));
  }

  void _reply(String text) =>
      _messages.add(AssistantMessage(text, fromAssistant: false));

  /// La ciudad con más paradas en el recorrido.
  static String _mainCity(List<Stop> stops) {
    final counts = <String, int>{};
    for (final stop in stops) {
      counts[stop.city] = (counts[stop.city] ?? 0) + 1;
    }
    if (counts.isEmpty) return '';
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
