import 'package:flutter/foundation.dart';

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

  bool get isLoaded => _tourists != null;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final rows = await _datasource.readList('tourists.json');
    _tourists = {
      for (final row in rows) row['id'] as String: TouristProfile.fromJson(row),
    };
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
    final trip = _work.tripById(tripId);
    if (trip == null || !trip.canRateTourist) {
      return const Result.failure(
        'Solo puedes calificar una vez, después de terminar el viaje',
      );
    }
    if (stars < 1 || stars > 5) {
      return const Result.failure('Elige de 1 a 5 estrellas');
    }
    final tourist = _tourists?[trip.touristId];
    if (tourist == null) {
      return const Result.failure('No encontramos a este turista');
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _tourists![tourist.id] = tourist.copyWith(
      ratings: [
        TouristRating(
          guideName: _work.guideShortName,
          rating: stars,
          text: comment.trim(),
          timeAgo: 'hoy',
        ),
        ...tourist.ratings,
      ],
    );
    _work.markTouristRated(tripId);
    notifyListeners();
    return const Result.ok(null);
  }
}
