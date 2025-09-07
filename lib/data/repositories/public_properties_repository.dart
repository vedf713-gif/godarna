import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/models/public_property.dart';
import 'dart:math' as math;

/// Repository للتعامل مع العقارات العامة (الضيوف)
/// يستخدم دالة RPC مركّزة بدلاً من استعلامات متعددة
class PublicPropertiesRepository {
  final SupabaseClient _client;

  PublicPropertiesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// جلب قائمة العقارات العامة مع دعم التصفية والفرز
  ///
  /// [search] نص البحث (عنوان، عنوان، منطقة)
  /// [city] تصفية حسب المدينة
  /// [centerLat], [centerLng], [radiusKm] تصفية جغرافية (بالكيلومترات)
  /// [minPrice], [maxPrice] النطاق السعري
  /// [propertyType] نوع العقار
  /// [maxGuests] الحد الأقصى للضيوف
  /// [limit] عدد النتائج (افتراضي: 20)
  /// [offset] للصفحات التالية
  /// [orderBy] طريقة الفرز: 'recent', 'price_asc', 'price_desc', 'rating_desc', 'distance_asc'
  ///
  /// ⚠️ ملاحظة: التصفية الجغرافية يتم تطبيقها على مستوى قاعدة البيانات
  /// لكن نحتفظ بـ fallback على الجانب العميل لضمان الدقة
  Future<List<PublicProperty>> browse({
    String? search,
    String? city,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    num? minPrice,
    num? maxPrice,
    String? propertyType,
    int? maxGuests,
    int limit = 20,
    int offset = 0,
    String orderBy = 'recent',
  }) async {
    try {
      final params = <String, dynamic>{};

      // إضافة المعلمات فقط إذا كانت غير فارغة
      if (search?.isNotEmpty == true) params['p_search'] = search;
      if (city?.isNotEmpty == true) params['p_city'] = city;
      if (centerLat != null) params['p_center_lat'] = centerLat;
      if (centerLng != null) params['p_center_lng'] = centerLng;
      if (radiusKm != null) params['p_radius_km'] = radiusKm;
      if (minPrice != null) params['p_min_price'] = minPrice;
      if (maxPrice != null) params['p_max_price'] = maxPrice;
      if (propertyType?.isNotEmpty == true) {
        params['p_property_type'] = propertyType;
      }
      if (maxGuests != null && maxGuests > 0) {
        params['p_max_guests'] = maxGuests;
      }

      params['p_limit'] = limit;
      params['p_offset'] = offset;
      params['p_order_by'] = orderBy;

      final res = await _client.rpc('rpc_public_properties', params: params);

      if (res is! List) {
        throw Exception('استجابة غير متوقعة من الخادم: $res');
      }

      final List<Map<String, dynamic>> data = res.cast<Map<String, dynamic>>();
      List<PublicProperty> items =
          data.map((e) => PublicProperty.fromJson(e)).toList();

      // ✅ Fallback: تصفية جغرافية على العميل فقط إذا تم تحديد الموقع
      if (centerLat != null && centerLng != null && radiusKm != null) {
        items = items.where((property) {
          final lat = property.latitude;
          final lng = property.longitude;
          if (lat == null || lng == null) return false;
          final distance = _distanceKm(centerLat, centerLng, lat, lng);
          return distance <= radiusKm;
        }).toList();
      }

      return items;
    } on PostgrestException catch (e) {
      // تمييز أخطاء Supabase
      throw Exception('فشل جلب العقارات: ${e.message}');
    } on Exception catch (e) {
      // أخطاء عامة
      throw Exception('حدث خطأ أثناء جلب العقارات: $e');
    }
  }

  /// حساب المسافة بين نقطتين باستخدام صيغة Haversine (بالكيلومترات)
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0; // نصف قطر الأرض بالكيلومترات

    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// تحويل الدرجات إلى راديان
  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
