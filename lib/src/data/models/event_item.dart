import '../../core/utils/api_json.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/time_parser.dart';

/// Evento próximo del home, con los datos de su pantalla de detalle.
class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.dateLabel,
    required this.image,
    this.category = '',
    this.address = '',
    this.description = '',
    this.images = const [],
    this.price = 0,
    this.latitude = 0,
    this.longitude = 0,
    this.cancelled = false,
    this.cancellationReason = '',
    this.organizer = '',
    this.fromApi = false,
  });

  /// Un evento de `GET /event/` o `GET /event/{id}/` (`docs/agenda-y-recompensas.md`).
  /// La categoría llega con su nombre en español ("Música"), como las del
  /// catálogo de ejemplo.
  factory EventItem.fromApi(Map<String, dynamic> json) {
    final start = ApiJson.day(json['start_date']);
    final end = ApiJson.date(json['end_date']) ?? start;
    final city = ApiJson.str(ApiJson.map(json['city'])['name']);
    final venue = ApiJson.str(json['venue']);
    final images = [
      for (final image in ApiJson.rows(json['images']))
        if (ApiJson.imageUrl(image).isNotEmpty) ApiJson.imageUrl(image),
    ];
    final startMinutes = TimeParser.minutesOf24h(
      ApiJson.str(json['start_time']),
    );
    final sameDay =
        end.year == start.year &&
        end.month == start.month &&
        end.day == start.day;
    return EventItem(
      id: ApiJson.str(json['id']),
      title: ApiJson.str(json['name']),
      location: [venue, city].where((part) => part.isNotEmpty).join(', '),
      date: startMinutes == null
          ? start
          : start.add(Duration(minutes: startMinutes)),
      dateLabel: Formatters.facts([
        sameDay
            ? Formatters.dayAndMonth(start)
            : '${Formatters.dayAndMonth(start)} - ${Formatters.dayAndMonth(end)}',
        if (startMinutes != null) Formatters.minutesOfDay(startMinutes),
      ]),
      image: images.firstOrNull ?? '',
      images: images,
      category: ApiJson.str(ApiJson.map(json['category'])['label']),
      address: ApiJson.str(json['address']),
      description: ApiJson.str(json['description']),
      price: ApiJson.decimal(json['entry_price']) ?? 0,
      latitude: ApiJson.decimal(json['latitude']) ?? 0,
      longitude: ApiJson.decimal(json['longitude']) ?? 0,
      cancelled: json['status'] == 'cancelled',
      cancellationReason: ApiJson.str(json['cancellation_reason']),
      organizer: ApiJson.str(ApiJson.map(json['organizer'])['name']),
      fromApi: true,
    );
  }

  final String id;
  final String title;
  final String location;
  final DateTime date;
  final String dateLabel;
  final String image;

  /// Tipo de evento ("Tradición", "Cultura"...), para el chip del detalle.
  final String category;
  final String address;
  final String description;
  final List<String> images;

  /// `0` significa entrada libre.
  final num price;
  final double latitude;
  final double longitude;

  /// Con el API: un evento cancelado sigue en la agenda, señalado.
  final bool cancelled;
  final String cancellationReason;

  /// Con el API: la institución o alcaldía que lo organiza (vacío en uno de
  /// K'Plan).
  final String organizer;

  /// Llegó del API: [dateLabel] ya trae los días y la hora.
  final bool fromApi;

  /// La tarjeta sólo trae una imagen; el detalle usa la galería si vino más.
  List<String> get galleryImages => images.isEmpty ? [image] : images;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final coordinates =
        json['coordinates'] as Map<String, dynamic>? ?? const {};

    return EventItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      dateLabel: json['dateLabel'] as String? ?? '',
      image: json['image'] as String? ?? '',
      category: json['category'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(growable: false),
      price: json['price'] as num? ?? 0,
      latitude: (coordinates['latitude'] as num? ?? 0).toDouble(),
      longitude: (coordinates['longitude'] as num? ?? 0).toDouble(),
    );
  }
}
