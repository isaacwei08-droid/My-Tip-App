class RestaurantModel {
  final String id;
  final String name;
  final String cuisine;
  final String city;
  final String street;
  final double rating;
  final int reviewCount;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.city,
    this.street = '',
    required this.rating,
    required this.reviewCount,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "cuisine": cuisine,
      "city": city,
      "street": street,
      "rating": rating,
      "reviewCount": reviewCount,
    };
  }

  factory RestaurantModel.fromMap(String id, Map<String, dynamic> data) {
    return RestaurantModel(
      id: id,
      name: data["name"] ?? "",
      cuisine: data["cuisine"] ?? "",
      city: data["city"] ?? "",
      street: data["street"] ?? "",
      rating: (data["rating"] as num?)?.toDouble() ?? 0.0,
      reviewCount: data["reviewCount"] ?? 0,
    );
  }
}
