import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../models/guide_access_request.dart';
import '../../models/guide_chat_message.dart';
import '../../models/guide_chat_thread.dart';
import '../../models/guide_job.dart';
import '../../models/guide_request.dart';
import '../../models/guide_trip.dart';
import '../../models/guide_withdrawal.dart';
import '../local/mock_datasource.dart';
import 'auth_repository.dart';
import 'guide_access_repository.dart';
import 'guide_inbox_repository.dart';

/// El trabajo del guía con sesión iniciada: las propuestas que puede tomar,
/// sus viajes y su dinero.
///
/// No hay backend ni turistas reales del otro lado. Las propuestas salen de
/// `guide_jobs.json` y los viajes de las cuentas de ejemplo de
/// `guide_trips.json`. Al postularse, el turista lo contrata a los
/// [decisionTime] (o contrata a otro, en la propuesta marcada para eso) y un
/// retiro llega a la cuenta a los [depositTime]. Todo vive en memoria,
/// separado por cuenta.
class GuideWorkRepository extends ChangeNotifier {
  GuideWorkRepository(
    this._authRepository,
    this._guideAccessRepository,
    this._inbox, {
    MockDatasource? datasource,
    DateTime Function()? now,
    this.decisionTime = const Duration(seconds: 20),
    this.depositTime = const Duration(seconds: 30),
  }) : _datasource = datasource ?? MockDatasource(),
       _now = now ?? DateTime.now {
    _authRepository.addListener(_prepareAccount);
  }

  final AuthRepository _authRepository;
  final GuideAccessRepository _guideAccessRepository;
  final GuideInboxRepository _inbox;
  final MockDatasource _datasource;
  final DateTime Function() _now;

  /// Cuánto tarda el turista en decidir después de una postulación.
  final Duration decisionTime;

  /// Cuánto tarda un retiro en llegar a la cuenta.
  final Duration depositTime;

  List<Map<String, dynamic>>? _jobRows;
  List<Map<String, dynamic>>? _accountRows;
  Future<void>? _loading;
  final Map<String, _Work> _byAccount = {};
  final List<Timer> _timers = [];
  int _nextWithdrawalId = 1;

  bool get isLoaded => _jobRows != null && _accountRows != null;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final rows = await Future.wait([
      _datasource.readList('guide_jobs.json'),
      _datasource.readList('guide_trips.json'),
    ]);
    _jobRows = rows[0];
    _accountRows = rows[1];
    _prepareAccount();
    notifyListeners();
  }

  String? get _account => GuideAccessRepository.accountKeyOf(_authRepository);

  /// Arma lo de la cuenta con sesión iniciada al cargar y cada vez que cambia
  /// la sesión, así sus conversaciones existen antes de pintar la UI.
  void _prepareAccount() {
    final account = _account;
    if (account == null || !isLoaded || _byAccount.containsKey(account)) {
      return;
    }
    _byAccount[account] = _seed(account);
    notifyListeners();
  }

  /// Lo de la cuenta con sesión iniciada.
  _Work? get _current {
    final account = _account;
    if (account == null || !isLoaded) return null;
    return _byAccount.putIfAbsent(
      account,
      () => _seed(account, notifyInbox: false),
    );
  }

  _Work _seed(String account, {bool notifyInbox = true}) {
    final now = _now();
    final jobs = {
      for (final row in _jobRows!)
        row['id'] as String: GuideJob.fromJson(row, now: now),
    };
    final seed = _accountRows!
        .where((row) => (row['guideEmail'] as String).toLowerCase() == account)
        .firstOrNull;
    if (seed == null) return _Work(jobs: jobs);

    final trips = <GuideTrip>[];
    final threads = <GuideChatThread>[];
    for (final row in seed['trips'] as List<dynamic>? ?? const []) {
      final json = row as Map<String, dynamic>;
      final trip = GuideTrip.fromJson(json, now: now);
      trips.add(trip);
      final messages = json['messages'] as List<dynamic>?;
      if (messages != null) threads.add(_threadFor(trip, messages, now));
    }
    _inbox.seedAll(account, threads, notify: notifyInbox);

    return _Work(
      jobs: jobs,
      trips: trips,
      withdrawals: [
        for (final row in seed['withdrawals'] as List<dynamic>? ?? const [])
          GuideWithdrawal.fromJson(row as Map<String, dynamic>, now: now),
      ],
      rating: (seed['rating'] as num?)?.toDouble(),
      reviewsCount: seed['reviewsCount'] as int? ?? 0,
      bankAccount: seed['bankAccount'] as String?,
    );
  }

  GuideChatThread _threadFor(GuideTrip trip, List<dynamic> rows, DateTime now) {
    var unread = 0;
    final messages = <GuideChatMessage>[];
    for (final (index, row) in rows.indexed) {
      final json = row as Map<String, dynamic>;
      final fromTourist = json['fromTourist'] as bool? ?? true;
      if (json['unread'] == true) unread++;
      messages.add(
        GuideChatMessage(
          id: '${trip.id}-$index',
          text: json['text'] as String? ?? '',
          senderId: fromTourist ? null : GuideInboxRepository.guideSenderId,
          sentAt: now.subtract(Duration(minutes: json['minutesAgo'] as int)),
        ),
      );
    }
    return GuideChatThread(
      tripId: trip.id,
      touristId: trip.touristId,
      messages: messages,
      unread: unread,
    );
  }

  // ── Propuestas ────────────────────────────────────────────────────────────

  /// Si [guide] puede tomar [job]: que pida guía, en su ciudad si es local y
  /// en un idioma que hable cuando se pide un guía bilingüe.
  static bool canTake(GuideJob job, GuideAccessRequest guide) {
    final need = job.terms.need;
    if (!need.needsGuide) return false;
    if (guide.coverage == GuideCoverage.local &&
        guide.certifiedCity != job.city) {
      return false;
    }
    if (need == GuideNeed.bilingualGuide &&
        !guide.languages.contains(job.terms.touristLanguage)) {
      return false;
    }
    return true;
  }

  /// Lo que el guía puede tomar ahora, de la fecha más próxima a la más
  /// lejana. Aparecen también las que ya se postuló, mientras el turista
  /// decide.
  List<GuideJob> get availableJobs {
    final work = _current;
    final guide = _guideAccessRepository.request;
    if (work == null || guide == null) return const [];
    return work.jobs.values
        .where(
          (job) =>
              (job.status == GuideJobStatus.open ||
                  job.status == GuideJobStatus.applied) &&
              canTake(job, guide),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// La propuesta [id], sólo si el guía puede tomarla: a un guía local no le
  /// existen las de otras ciudades aunque llegue por un enlace.
  GuideJob? jobById(String id) {
    final job = _current?.jobs[id];
    final guide = _guideAccessRepository.request;
    if (job == null || guide == null || !canTake(job, guide)) return null;
    return job;
  }

  /// Se postula a [jobId] pidiendo [price]. El turista responde después de
  /// [decisionTime].
  Future<Result<void>> apply(
    String jobId, {
    required num price,
    required String message,
  }) async {
    final account = _account;
    final work = _current;
    final job = jobById(jobId);
    if (account == null || work == null || job == null) {
      return const Result.failure('No encontramos esta propuesta');
    }
    if (job.status != GuideJobStatus.open) {
      return const Result.failure('Ya no puedes postularte a esta propuesta');
    }
    if (price <= 0) {
      return const Result.failure('Escribe un precio mayor a cero');
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    work.jobs[jobId] = job.copyWith(
      status: GuideJobStatus.applied,
      offeredPrice: price,
      message: message.trim(),
    );
    notifyListeners();
    _schedule(decisionTime, () => _decide(account, jobId));
    return const Result.ok(null);
  }

  void _decide(String account, String jobId) {
    final work = _byAccount[account];
    final job = work?.jobs[jobId];
    if (work == null || job == null || job.status != GuideJobStatus.applied) {
      return;
    }

    if (job.goesToAnotherGuide) {
      work.jobs[jobId] = job.copyWith(status: GuideJobStatus.taken);
    } else {
      work.jobs[jobId] = job.copyWith(status: GuideJobStatus.hired);
      final trip = GuideTrip.fromJob(
        job,
        agreedPrice: job.offeredPrice ?? job.budget,
      );
      work.trips.add(trip);
      work.newHire = trip;
      _inbox.open(
        account: account,
        tripId: trip.id,
        touristId: job.touristId,
        greeting:
            '¡Hola! Te contraté para ${job.circuitTitle}. ¿Dónde nos vemos?',
      );
    }
    notifyListeners();
  }

  // ── Viajes ────────────────────────────────────────────────────────────────

  /// Del más próximo al más lejano.
  List<GuideTrip> get upcomingTrips =>
      (_current?.trips ?? const <GuideTrip>[])
          .where((trip) => !trip.isCompleted)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Del más reciente al más antiguo.
  List<GuideTrip> get completedTrips =>
      (_current?.trips ?? const <GuideTrip>[])
          .where((trip) => trip.isCompleted)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  GuideTrip? get nextTrip => upcomingTrips.firstOrNull;

  GuideTrip? tripById(String id) =>
      _current?.trips.where((trip) => trip.id == id).firstOrNull;

  /// El viaje que nació de la propuesta [jobId], si lo contrataron.
  GuideTrip? tripForJob(String jobId) => tripById(GuideTrip.idForJob(jobId));

  /// El último viaje en que lo contrataron, hasta que lo vea.
  GuideTrip? get newHire => _current?.newHire;

  void dismissNewHire() {
    final work = _current;
    if (work == null || work.newHire == null) return;
    work.newHire = null;
    notifyListeners();
  }

  void markTouristRated(String tripId) {
    final trips = _current?.trips;
    final index = trips?.indexWhere((trip) => trip.id == tripId) ?? -1;
    if (trips == null || index == -1) return;
    trips[index] = trips[index].copyWith(touristRated: true);
    notifyListeners();
  }

  // ── Perfil y dinero ───────────────────────────────────────────────────────

  /// "Marlene R.", como firma sus calificaciones.
  String get guideShortName {
    final parts = (_guideAccessRepository.request?.fullName ?? '').trim().split(
      RegExp(r'\s+'),
    );
    if (parts.first.isEmpty) return 'Guía de K’Plan';
    if (parts.length < 2) return parts.first;
    return '${parts.first} ${parts.last.substring(0, 1)}.';
  }

  /// Su calificación como guía; `null` si todavía no tiene reseñas.
  double? get rating => _current?.rating;

  int get reviewsCount => _current?.reviewsCount ?? 0;

  /// A dónde van los retiros.
  String get bankAccount =>
      _current?.bankAccount ?? 'Cuenta de ejemplo •••• 0000';

  /// Lo ganado en viajes terminados, menos lo ya retirado (o en camino).
  num get available {
    final work = _current;
    if (work == null) return 0;
    final earned = completedTrips.fold<num>(0, (sum, t) => sum + t.earnings);
    final withdrawn = work.withdrawals.fold<num>(0, (sum, w) => sum + w.amount);
    return earned - withdrawn;
  }

  /// Lo que recibirá por los viajes que todavía no hace.
  num get pending => upcomingTrips.fold<num>(0, (sum, t) => sum + t.earnings);

  /// El más reciente primero.
  List<GuideWithdrawal> get withdrawals =>
      List.of(_current?.withdrawals ?? const <GuideWithdrawal>[])
        ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

  Future<Result<void>> withdraw(num amount) async {
    final account = _account;
    final work = _current;
    if (account == null || work == null) {
      return const Result.failure('Inicia sesión como guía para retirar');
    }
    if (amount <= 0) {
      return const Result.failure('Escribe un monto mayor a cero');
    }
    if (amount > available) {
      return Result.failure(
        'Solo tienes ${Formatters.currency(available)} disponibles',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    final withdrawal = GuideWithdrawal(
      id: 'withdrawal-${_nextWithdrawalId++}',
      amount: amount,
      requestedAt: _now(),
      status: WithdrawalStatus.processing,
    );
    work.withdrawals.add(withdrawal);
    notifyListeners();
    _schedule(depositTime, () => _deposit(account, withdrawal.id));
    return const Result.ok(null);
  }

  void _deposit(String account, String withdrawalId) {
    final withdrawals = _byAccount[account]?.withdrawals;
    final index = withdrawals?.indexWhere((w) => w.id == withdrawalId) ?? -1;
    if (withdrawals == null || index == -1) return;
    withdrawals[index] = withdrawals[index].copyWith(
      status: WithdrawalStatus.deposited,
    );
    notifyListeners();
  }

  void _schedule(Duration delay, VoidCallback action) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      action();
    });
    _timers.add(timer);
  }

  @override
  void dispose() {
    _authRepository.removeListener(_prepareAccount);
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

/// Lo de una cuenta de guía: sus propuestas (con en qué va cada
/// postulación), viajes, retiros y reputación.
class _Work {
  _Work({
    required this.jobs,
    List<GuideTrip>? trips,
    List<GuideWithdrawal>? withdrawals,
    this.rating,
    this.reviewsCount = 0,
    this.bankAccount,
  }) : trips = trips ?? [],
       withdrawals = withdrawals ?? [];

  final Map<String, GuideJob> jobs;
  final List<GuideTrip> trips;
  final List<GuideWithdrawal> withdrawals;
  final double? rating;
  final int reviewsCount;
  final String? bankAccount;
  GuideTrip? newHire;
}
