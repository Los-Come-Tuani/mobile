/// Evento próximo del home.
class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.dateLabel,
    required this.image,
  });

  final String id;
  final String title;
  final String location;
  final DateTime date;
  final String dateLabel;
  final String image;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      dateLabel: json['dateLabel'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );
  }
}
