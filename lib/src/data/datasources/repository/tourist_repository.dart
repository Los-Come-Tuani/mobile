import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/result.dart';
import '../../models/guide_trip.dart';
import '../../models/tourist_profile.dart';
import '../local/mock_datasource.dart';
import 'guide_work_repository.dart';

/// Los turistas vistos desde la app del guía, con lo que opinan de ellos
/// otros guías. Esas calificaciones no las ve el turista.
///
/// Se siembra desde `tourists.json`; calificar suma en memoria.
class TouristRepository extends ChangeNotifier {
  TouristRepository(this._work, {MockDatasource? datasource})
    : _datasource = datasource ?? MockDatasource();

  final GuideWorkRepository _work;
  final MockDatasource _datasource;
  Map<String, TouristProfile>? _tourists;
  Future<void>? _loading;
  bool _isDisposed = false;

  bool get isLoaded => _tourists != null;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final rows = await _datasource.readList('tourists.json');
    _tourists = {
      for (final row in rows) row['id'] as String: TouristProfile.fromJson(row),
    };
    notifyListeners();
  }

  /// Vuelve a leer lo que viene del catálogo (el país y las calificaciones de
  /// ejemplo) en el idioma de ahora. Las calificaciones que dio el guía en
  /// esta sesión se conservan tal como las escribió.
  Future<void> relocalize() async {
    if (_tourists == null) return;
    final rows = await _datasource.readList('tourists.json');
    final tourists = _tourists;
    if (_isDisposed || tourists == null) return;

    for (final row in rows) {
      final seed = TouristProfile.fromJson(row);
      final current = tourists[seed.id];
      if (current == null) continue;
      // Las calificaciones nuevas entran al frente: las de ejemplo van al
      // final, así que sólo ellas se reemplazan.
      final added = (current.ratings.length - seed.ratings.length).clamp(
        0,
        current.ratings.length,
      );
      tourists[seed.id] = current.copyWith(
        country: seed.country,
        ratings: [...current.ratings.take(added), ...seed.ratings],
      );
    }
    notifyListeners();
  }

  TouristProfile? byId(String id) => _tourists?[id];

  /// El viaje terminado con [touristId] que el guía todavía no califica:
  /// sólo se califica a alguien después de un viaje juntos.
  GuideTrip? tripToRate(String touristId) => _work.completedTrips
      .where((trip) => trip.touristId == touristId && trip.canRateTourist)
      .firstOrNull;

  Future<Result<void>> rate({
    required String tripId,
    required int stars,
    required String comment,
  }) async {
    final l10n = AppStrings.current;
    final trip = _work.tripById(tripId);
    if (trip == null || !trip.canRateTourist) {
      return Result.failure(l10n.repoTouristRateOnce);
    }
    if (stars < 1 || stars > 5) {
      return Result.failure(l10n.repoTouristRateStars);
    }
    final tourist = _tourists?[trip.touristId];
    if (tourist == null) {
      return Result.failure(l10n.repoTouristNotFound);
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _tourists![tourist.id] = tourist.copyWith(
      ratings: [
        TouristRating(
          guideName: _work.guideShortName,
          rating: stars,
          text: comment.trim(),
          timeAgo: AppStrings.current.repoTouristRatingToday,
        ),
        ...tourist.ratings,
      ],
    );
    _work.markTouristRated(tripId);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
