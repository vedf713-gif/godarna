import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

/// خدمة إدارية لتحكم المشرف (Admin) في المستخدمين، العقارات، والحجوزات
/// باستخدام وظائف RPC في Supabase.
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// -------------------------------
  /// 🔹 إدارة المستخدمين
  /// -------------------------------

  /// جلب قائمة المستخدمين مع دعم البحث والتقسيم
  ///
  /// - [search]: بحث نصي في الاسم أو البريد
  /// - [limit]: عدد النتائج (افتراضي: 20)
  /// - [offset]: التخطي (للبجنة)
  ///
  /// يُرجع: {
  ///   "users": [...],
  ///   "total": عدد_الكلي,
  ///   "has_more": هل هناك المزيد
  /// }
  Future<Map<String, dynamic>> listUsers({
    String search = '',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'admin_list_users',
        params: {
          'p_search': search,
          'p_limit': limit,
          'p_offset': offset,
        },
      ) as Map<String, dynamic>;
      return response;
    } catch (e) {
      dev.log('admin_list_users error: $e', name: 'AdminService');
      rethrow;
    }
  }

  /// تغيير دور المستخدم (مثلاً: 'user', 'host', 'admin')
  ///
  /// - [userId]: معرف المستخدم
  /// - [role]: الدور الجديد
  ///
  /// يُرجع `true` إذا نجح
  Future<bool> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      final result = await _supabase.rpc(
        'admin_set_user_role',
        params: {
          'p_user_id': userId,
          'p_role': role,
        },
      );
      return _isSuccess(result);
    } catch (e) {
      dev.log('admin_set_user_role error: $e', name: 'AdminService');
      rethrow;
    }
  }

  /// تفعيل أو تعطيل حساب المستخدم
  ///
  /// - [userId]: معرف المستخدم
  /// - [isActive]: هل الحساب نشط؟
  ///
  /// يُرجع `true` إذا نجح
  Future<bool> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    try {
      final result = await _supabase.rpc(
        'admin_set_user_active',
        params: {
          'p_user_id': userId,
          'p_is_active': isActive,
        },
      );
      return _isSuccess(result);
    } catch (e) {
      dev.log('admin_set_user_active error: $e', name: 'AdminService');
      rethrow;
    }
  }

  /// -------------------------------
  /// 🔹 إدارة العقارات
  /// -------------------------------

  /// جلب قائمة العقارات مع التصفية
  ///
  /// - [search]: بحث بالعنوان أو المدينة
  /// - [city]: تصفية حسب المدينة
  /// - [isActive]: هل العقار نشط؟
  /// - [isVerified]: هل تم التحقق منه؟
  Future<Map<String, dynamic>> listProperties({
    String search = '',
    String? city,
    bool? isActive,
    bool? isVerified,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final result = await _supabase.rpc(
        'admin_list_properties',
        params: {
          'p_search': search,
          'p_city': city,
          'p_is_active': isActive,
          'p_is_verified': isVerified,
          'p_limit': limit,
          'p_offset': offset,
        },
      ) as Map<String, dynamic>;
      return result;
    } catch (e) {
      dev.log('admin_list_properties error: $e', name: 'AdminService');
      rethrow;
    }
  }

  /// تفعيل أو تعطيل عقار
  Future<bool> setPropertyActive({
    required String propertyId,
    required bool isActive,
  }) async {
    try {
      final res = await _supabase.rpc(
        'admin_set_property_active',
        params: {
          'p_property_id': propertyId,
          'p_is_active': isActive,
        },
      );
      return _isSuccess(res);
    } catch (e) {
      dev.log('admin_set_property_active error: $e', name: 'AdminService');
      rethrow;
    }
  }

  /// التحقق من عقار (تم التحقق من الوثائق، الموقع، إلخ)
  Future<bool> setPropertyVerified({
    required String propertyId,
    required bool isVerified,
  }) async {
    try {
      final res = await _supabase.rpc(
        'admin_set_property_verified',
        params: {
          'p_property_id': propertyId,
          'p_is_verified': isVerified,
        },
      );
      return _isSuccess(res);
    } catch (e) {
      dev.log('admin_set_property_verified error: $e', name: 'AdminService');
      rethrow;
    }
  }

  /// -------------------------------
  /// 🔹 إدارة الحجوزات
  /// -------------------------------

  /// جلب قائمة الحجوزات مع التصفية
  ///
  /// - [search]: بحث بالمستخدم أو العقار
  /// - [status]: 'pending', 'confirmed', 'completed', 'cancelled'
  /// - [from], [to]: نطاق زمني
  Future<Map<String, dynamic>> listBookings({
    String search = '',
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await _supabase.rpc(
        'admin_list_bookings',
        params: {
          'p_search': search,
          'p_status': status,
          'p_from': from?.toUtc().toIso8601String(),
          'p_to': to?.toUtc().toIso8601String(),
          'p_limit': limit,
          'p_offset': offset,
        },
      ) as Map<String, dynamic>;
      return res;
    } catch (e) {
      dev.log('admin_list_bookings error: $e', name: 'AdminService');
      rethrow;
    }
  }

  /// تغيير حالة الحجز (مثلاً من "معلق" إلى "مؤكد")
  ///
  /// - [bookingId]: معرف الحجز
  /// - [status]: الحالة الجديدة (نص يطابق enum في قاعدة البيانات)
  Future<bool> setBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      final res = await _supabase.rpc(
        'admin_set_booking_status',
        params: {
          'p_booking_id': bookingId,
          'p_status': status,
        },
      );
      return _isSuccess(res);
    } catch (e) {
      dev.log('admin_set_booking_status error: $e', name: 'AdminService');
      rethrow;
    }
  }

  // --- وظائف مساعدة ---

  /// تحقق مما إذا كانت النتيجة تحتوي على {"ok": true}
  bool _isSuccess(dynamic result) {
    return (result as Map<String, dynamic>)['ok'] == true;
  }
}
