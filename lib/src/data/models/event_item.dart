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
  });

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
