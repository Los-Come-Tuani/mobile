/// Lugar destacado del home.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.location,
    required this.image,
  });

  final String id;
  final String name;
  final String location;
  final String image;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );
  }
}
