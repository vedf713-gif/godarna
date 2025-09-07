class PropertyModel {
  final String id;
  final String hostId;
  final String title;
  final String description;
  final String propertyType; // 'apartment', 'villa', 'riad', 'studio'
  final double pricePerNight;
  final double pricePerMonth;
  final String address;
  final String region;
  final String city;
  final String area;
  final double latitude;
  final double longitude;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final List<String> amenities;
  final List<String> photos;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalInfo;

  PropertyModel({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.pricePerNight,
    required this.pricePerMonth,
    required this.address,
    required this.region,
    required this.city,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.maxGuests,
    required this.amenities,
    required this.photos,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.isAvailable,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final dynamic ai = json['additional_info'];
    final String regionValue = (json['region'] as String?) ??
        (ai is Map<String, dynamic> ? (ai['region'] as String?) : null) ??
        '';
    return PropertyModel(
      id: json['id'] ?? '',
      hostId: json['host_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['property_type'] ?? 'apartment',
      pricePerNight: (json['price_per_night'] as num?)?.toDouble() ?? 0.0,
      pricePerMonth: (json['price_per_month'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      region: regionValue,
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0.0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      maxGuests: json['max_guests'] ?? 1,
      amenities: List<String>.from(json['amenities'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      rating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      additionalInfo: json['additional_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'title': title,
      'description': description,
      'property_type': propertyType,
      'price_per_night': pricePerNight,
      'price_per_month': pricePerMonth,
      'address': address,
      'region': region,
      'city': city,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'max_guests': maxGuests,
      'amenities': amenities,
      'photos': photos,
      'rating': rating,
      'review_count': reviewCount,
      'is_available': isAvailable,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'additional_info': additionalInfo,
    };
  }

  PropertyModel copyWith({
    String? id,
    String? hostId,
    String? title,
    String? description,
    String? propertyType,
    double? pricePerNight,
    double? pricePerMonth,
    String? address,
    String? region,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    List<String>? amenities,
    List<String>? photos,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      propertyType: propertyType ?? this.propertyType,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      address: address ?? this.address,
      region: region ?? this.region,
      city: city ?? this.city,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      maxGuests: maxGuests ?? this.maxGuests,
      amenities: amenities ?? this.amenities,
      photos: photos ?? this.photos,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  String get displayPrice => '${pricePerNight.toStringAsFixed(0)} درهم/ليلة';
  String get displayPriceMonthly =>
      '${pricePerMonth.toStringAsFixed(0)} درهم/شهر';

  String get propertyTypeDisplay {
    switch (propertyType) {
      case 'apartment':
        return 'شقة';
      case 'villa':
        return 'فيلا';
      case 'riad':
        return 'رياض';
      case 'studio':
        return 'استوديو';
      case 'kasbah':
        return 'قصبة/قصر';
      case 'village_house':
        return 'بيت قروي';
      case 'desert_camp':
        return 'مخيم صحراوي';
      case 'eco_lodge':
        return 'نُزل بيئي';
      case 'guesthouse':
        return 'بيت ضيافة';
      case 'hotel':
        return 'فندق';
      case 'resort':
        return 'منتجع';
      default:
        return propertyType;
    }
  }

  String get locationDisplay => '$city, $area';
  String get location => '$city, $area';
  String get displayRating => rating > 0 ? '${rating.toStringAsFixed(1)} ★' : 'جديد';

  bool get hasPhotos => photos.isNotEmpty;
  String? get mainPhoto => photos.isNotEmpty ? photos.first : null;
}
