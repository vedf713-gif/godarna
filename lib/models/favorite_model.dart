import 'package:godarna/models/property_model.dart';

/// مودل المفضلة - يربط المستخدم بالعقار المفضل
class FavoriteModel {
  final String id;
  final String tenantId;
  final String listingId;
  final DateTime createdAt;
  final PropertyModel? property; // العقار المرتبط (اختياري)

  const FavoriteModel({
    required this.id,
    required this.tenantId,
    required this.listingId,
    required this.createdAt,
    this.property,
  });

  /// إنشاء من JSON
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      listingId: json['listing_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      property: json['property'] != null 
          ? PropertyModel.fromJson(json['property'] as Map<String, dynamic>)
          : null,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'listing_id': listingId,
      'created_at': createdAt.toIso8601String(),
      if (property != null) 'property': property!.toJson(),
    };
  }

  /// نسخة محدثة من المودل
  FavoriteModel copyWith({
    String? id,
    String? tenantId,
    String? listingId,
    DateTime? createdAt,
    PropertyModel? property,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      listingId: listingId ?? this.listingId,
      createdAt: createdAt ?? this.createdAt,
      property: property ?? this.property,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteModel &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.listingId == listingId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ tenantId.hashCode ^ listingId.hashCode;
  }

  @override
  String toString() {
    return 'FavoriteModel(id: $id, tenantId: $tenantId, listingId: $listingId, createdAt: $createdAt)';
  }
}
