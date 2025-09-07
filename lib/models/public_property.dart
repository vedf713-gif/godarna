class PublicProperty {
  final String id;
  final String title;
  final String city;
  final double pricePerNight;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final String? photo;
  final double? distanceKm;

  const PublicProperty({
    required this.id,
    required this.title,
    required this.city,
    required this.pricePerNight,
    this.latitude,
    this.longitude,
    this.rating,
    this.photo,
    this.distanceKm,
  });

  factory PublicProperty.fromJson(Map<String, dynamic> json) {
    return PublicProperty(
      id: json['id'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      photo: json['photo'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  String get displayPrice => '${pricePerNight.toStringAsFixed(0)} درهم/ليلة';
}
