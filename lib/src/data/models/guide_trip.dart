import 'guide_job.dart';
import 'guide_request.dart';

enum GuideTripStatus { upcoming, completed }

/// Lo que K'Plan le descuenta al guía de cada viaje. El 20% de servicio que
/// paga el turista al reservar es aparte.
abstract final class GuidePay {
  static const double commissionRate = 0.20;

  static num commissionOf(num price) => (price * commissionRate).round();

  static num earningsOf(num price) => price - commissionOf(price);
}

/// Un recorrido para el que contrataron al guía.
class GuideTrip {
  const GuideTrip({
    required this.id,
    required this.touristId,
    required this.circuitId,
    required this.circuitTitle,
    required this.city,
    required this.date,
    required this.startTime,
    required this.groupSize,
    required this.terms,
    required this.agreedPrice,
    required this.status,
    this.meetingPoint,
    this.touristRated = false,
  });

  factory GuideTrip.fromJson(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    return GuideTrip(
      id: json['id'] as String,
      touristId: json['touristId'] as String,
      circuitId: json['circuitId'] as String? ?? '',
      circuitTitle: json['circuitTitle'] as String? ?? '',
      city: json['city'] as String? ?? '',
      date: today.add(Duration(days: json['daysFromNow'] as int? ?? 0)),
      startTime: json['startTime'] as String? ?? '',
      groupSize: json['groupSize'] as int? ?? 1,
      terms: GuideJob.termsFromJson(json),
      agreedPrice: json['agreedPrice'] as num? ?? 0,
      status: json['status'] == 'completed'
          ? GuideTripStatus.completed
          : GuideTripStatus.upcoming,
      meetingPoint: json['meetingPoint'] as String?,
      touristRated: json['touristRated'] as bool? ?? false,
    );
  }

  /// El viaje que nace cuando el turista contrata al guía en [job].
  factory GuideTrip.fromJob(GuideJob job, {required num agreedPrice}) {
    return GuideTrip(
      id: idForJob(job.id),
      touristId: job.touristId,
      circuitId: job.circuitId,
      circuitTitle: job.circuitTitle,
      city: job.city,
      date: job.date,
      startTime: job.startTime,
      groupSize: job.groupSize,
      terms: job.terms,
      agreedPrice: agreedPrice,
      status: GuideTripStatus.upcoming,
    );
  }

  /// El id del viaje que nace de la propuesta [jobId].
  static String idForJob(String jobId) => 'trip-$jobId';

  final String id;
  final String touristId;
  final String circuitId;
  final String circuitTitle;
  final String city;
  final DateTime date;
  final String startTime;
  final int groupSize;
  final GuideRequestTerms terms;

  /// Lo que acordó con el turista, antes de la comisión.
  final num agreedPrice;
  final GuideTripStatus status;

  /// `null` hasta que lo acuerden en el chat.
  final String? meetingPoint;

  /// Ya calificó al turista de este viaje.
  final bool touristRated;

  bool get isCompleted => status == GuideTripStatus.completed;

  /// Sólo se califica al turista después del viaje, una vez.
  bool get canRateTourist => isCompleted && !touristRated;

  num get commission => GuidePay.commissionOf(agreedPrice);

  num get earnings => GuidePay.earningsOf(agreedPrice);

  GuideTrip copyWith({
    bool? touristRated,
    String? circuitTitle,
    String? meetingPoint,
  }) {
    return GuideTrip(
      id: id,
      touristId: touristId,
      circuitId: circuitId,
      circuitTitle: circuitTitle ?? this.circuitTitle,
      city: city,
      date: date,
      startTime: startTime,
      groupSize: groupSize,
      terms: terms,
      agreedPrice: agreedPrice,
      status: status,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      touristRated: touristRated ?? this.touristRated,
    );
  }
}
