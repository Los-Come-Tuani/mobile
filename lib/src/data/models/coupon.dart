/// Cupón de descuento canjeable por insignias.
class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.discountLabel,
    required this.cost,
    required this.image,
  });

  final String id;
  final String title;
  final String description;

  /// Texto corto del beneficio, ej. `"10% de descuento"`.
  final String discountLabel;

  /// Insignias que cuesta canjearlo.
  final int cost;
  final String image;

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      discountLabel: json['discountLabel'] as String? ?? '',
      cost: json['cost'] as int? ?? 0,
      image: json['image'] as String? ?? '',
    );
  }
}
