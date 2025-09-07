import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/models/booking_model.dart';
import 'dart:developer' as dev;

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();
  
  static BookingService get instance => _instance;
  
  final SupabaseClient _supabase = Supabase.instance.client;

  // Realtime subscription for bookings
  RealtimeChannel? subscribeToBookings({
    String? userId,
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    try {
      var channel = _supabase.channel('bookings_realtime');
      
      // Subscribe to all booking changes
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'bookings',
        callback: (payload) {
          dev.log('🔍 [Booking] New booking: ${payload.newRecord}', name: 'BookingService');
          onInsert(payload.newRecord);
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'bookings',
        callback: (payload) {
          dev.log('🔍 [Booking] Updated booking: ${payload.newRecord}', name: 'BookingService');
          onUpdate(payload.newRecord);
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'bookings',
        callback: (payload) {
          dev.log('🔍 [Booking] Deleted booking: ${payload.oldRecord}', name: 'BookingService');
          onDelete(payload.oldRecord);
        },
      );

      return channel.subscribe((status, [ref]) {
        dev.log('🔍 [Booking] Realtime status: $status', name: 'BookingService');
      });
    } catch (e) {
      dev.log('subscribeToBookings error: $e', name: 'BookingService');
      return null;
    }
  }

  // Get all bookings (for admin)
  Future<List<BookingModel>> getBookings() async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings: $e');
    }
  }

  // يحاول حجز عقار بعد التحقق من عدم وجود أي تداخل مع حجوزات سابقة لنفس العقار
  // السماح بالحجز المتتابع مباشرة بعد نهاية حجز آخر (no-overlap but touching endpoints is OK)
  // شرط التداخل: existing.check_in < newEnd AND existing.check_out > newStart
  Future<void> bookProperty({
    required String propertyId,
    required DateTime startDate,
    required DateTime endDate,
    String? tenantId,
    String? hostId,
  }) async {
    if (!endDate.isAfter(startDate)) {
      throw Exception('تاريخ النهاية يجب أن يكون بعد تاريخ البداية.');
    }

    // 1) تحقق من وجود أي حجز متداخل لنفس العقار
    final overlaps = await _supabase
        .from('bookings')
        .select('id, start_date, end_date')
        .eq('listing_id', propertyId)
        .neq('status', 'cancelled')
        .lt('start_date', endDate.toIso8601String())
        .gt('end_date', startDate.toIso8601String());

    if (overlaps.isNotEmpty) {
      // خذ أول تعارض لعرضه للمستخدم
      final first = Map<String, dynamic>.from(overlaps.first);
      final ci = DateTime.parse(first['start_date'] as String);
      final co = DateTime.parse(first['end_date'] as String);
      throw Exception(
          'المكان محجوز بالفعل في الفترة من ${_fmt(ci)} إلى ${_fmt(co)}. اختر تواريخ أخرى.');
    }

    // 2) أضف الحجز (سجل بسيط حسب الموجود في الجدول bookings)
    final now = DateTime.now();
    final data = {
      'listing_id': propertyId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (hostId != null) 'host_id': hostId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': 'pending',
      'payment_status': 'pending',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    await _supabase.from('bookings').insert(data);
  }

  String _fmt(DateTime d) {
    // عرض مبسط YYYY-MM-DD
    return d.toIso8601String().split('T').first;
  }

  // Get unavailable property IDs for a given date range
  // If propertyIds is provided, the query is scoped to those IDs to reduce load
  Future<Set<String>> getUnavailablePropertyIds({
    required DateTime checkIn,
    required DateTime checkOut,
    List<String>? propertyIds,
  }) async {
    try {
      var query = _supabase
          .from('bookings')
          .select('listing_id, start_date, end_date, status')
          .neq('status', 'cancelled')
          // overlap condition: existing.start_date < checkOut AND existing.end_date > checkIn
          .lt('start_date', checkOut.toIso8601String())
          .gt('end_date', checkIn.toIso8601String());

      if (propertyIds != null && propertyIds.isNotEmpty) {
        query = query.inFilter('listing_id', propertyIds);
      }

      final response = await query;
      final set = <String>{};
      for (final row in (response as List)) {
        final pid = row['listing_id'] as String?;
        if (pid != null) set.add(pid);
      }
      return set;
    } catch (e) {
      throw Exception('Failed to get unavailable properties: $e');
    }
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  // Get bookings by tenant
  Future<List<BookingModel>> getBookingsByTenant(String tenantId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tenant bookings: $e');
    }
  }

  // Get bookings by host
  Future<List<BookingModel>> getBookingsByHost(String hostId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('host_id', hostId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get host bookings: $e');
    }
  }

  // Create new booking
  Future<BookingModel?> createBooking({
    required String propertyId,
    required String tenantId,
    required String hostId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int nights,
    required double totalPrice,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final bookingData = {
        'listing_id': propertyId,
        'tenant_id': tenantId,
        'host_id': hostId,
        'start_date': checkIn.toIso8601String(),
        'end_date': checkOut.toIso8601String(),
        'nights': nights,
        'total_price': totalPrice,
        'status': 'pending',
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      // Map DB exclusion constraint violation to user-friendly message
      if (e is PostgrestException) {
        final code = e.code ?? '';
        final msg = e.message;
        if (code == '23P01' ||
            msg.contains('bookings_no_overlap') ||
            msg.toLowerCase().contains('exclusion')) {
          throw Exception(
              'التواريخ المختارة غير متاحة. يرجى اختيار تواريخ أخرى لأن هناك حجزاً لنفس العقار في نفس المدة.');
        }
        throw Exception('فشل إنشاء الحجز: ${e.message}');
      }
      throw Exception('فشل إنشاء الحجز: $e');
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _supabase.from('bookings').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(
      String bookingId, String paymentStatus) async {
    try {
      await _supabase.from('bookings').update({
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Add review and rating
  Future<bool> addReview({
    required String bookingId,
    required double rating,
    required String review,
  }) async {
    try {
      await _supabase.from('bookings').update({
        'rating': rating,
        'review': review,
        'review_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      // Update property rating
      await _updatePropertyRating(bookingId, rating);

      return true;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Update property rating when review is added
  Future<void> _updatePropertyRating(String bookingId, double rating) async {
    try {
      // Get the booking to find the property
      final booking = await getBookingById(bookingId);
      if (booking != null) {
        // Get current property rating
        final propertyResponse = await _supabase
            .from('properties')
            .select('rating, review_count')
            .eq('id', booking.propertyId)
            .single();

        final currentRating = propertyResponse['rating'] as num? ?? 0.0;
        final currentReviewCount =
            propertyResponse['review_count'] as int? ?? 0;

        // Calculate new average rating
        final newRating = ((currentRating * currentReviewCount) + rating) /
            (currentReviewCount + 1);
        final newReviewCount = currentReviewCount + 1;

        // Update property rating
        await _supabase.from('properties').update({
          'rating': newRating,
          'review_count': newReviewCount,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', booking.propertyId);
      }
    } catch (e) {
      // Handle error silently for rating update
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Get booking statistics
  Future<Map<String, dynamic>> getBookingStats() async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('status, payment_status, total_price, created_at');

      final bookings = response as List;

      final totalBookings = bookings.length;
      final pendingBookings =
          bookings.where((b) => b['status'] == 'pending').length;
      final confirmedBookings =
          bookings.where((b) => b['status'] == 'confirmed').length;
      final completedBookings =
          bookings.where((b) => b['status'] == 'completed').length;
      final cancelledBookings =
          bookings.where((b) => b['status'] == 'cancelled').length;

      final totalRevenue = bookings
          .where((b) => b['payment_status'] == 'paid')
          .fold<double>(0.0, (sum, b) => sum + (b['total_price'] as num));

      // Monthly revenue
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      final monthlyRevenue = bookings.where((b) {
        final bookingDate = DateTime.parse(b['created_at']);
        return b['payment_status'] == 'paid' &&
            bookingDate.month == currentMonth &&
            bookingDate.year == currentYear;
      }).fold<double>(0.0, (sum, b) => sum + (b['total_price'] as num));

      return {
        'total': totalBookings,
        'pending': pendingBookings,
        'confirmed': confirmedBookings,
        'completed': completedBookings,
        'cancelled': cancelledBookings,
        'totalRevenue': totalRevenue,
        'monthlyRevenue': monthlyRevenue,
      };
    } catch (e) {
      throw Exception('Failed to get booking stats: $e');
    }
  }

  // Check property availability for dates
  Future<bool> checkPropertyAvailability({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('start_date, end_date, status')
          .eq('listing_id', propertyId)
          .neq('status', 'cancelled');

      final bookings = response as List;

      for (final booking in bookings) {
        final existingCheckIn = DateTime.parse(booking['start_date']);
        final existingCheckOut = DateTime.parse(booking['end_date']);

        // Check for date overlap
        if ((checkIn.isBefore(existingCheckOut) &&
            checkOut.isAfter(existingCheckIn))) {
          return false; // Property is not available for these dates
        }
      }

      return true; // Property is available
    } catch (e) {
      throw Exception('Failed to check property availability: $e');
    }
  }

  // Get upcoming bookings
  Future<List<BookingModel>> getUpcomingBookings(String userId,
      {bool isHost = false}) async {
    try {
      final now = DateTime.now();
      final userIdField = isHost ? 'host_id' : 'tenant_id';

      final response = await _supabase
          .from('bookings')
          .select()
          .eq(userIdField, userId)
          .gte('start_date', now.toIso8601String())
          .inFilter('status', ['pending', 'confirmed']).order('start_date',
              ascending: true);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming bookings: $e');
    }
  }

  // Get past bookings
  Future<List<BookingModel>> getPastBookings(String userId,
      {bool isHost = false}) async {
    try {
      final now = DateTime.now();
      final userIdField = isHost ? 'host_id' : 'tenant_id';

      final response = await _supabase
          .from('bookings')
          .select()
          .eq(userIdField, userId)
          .lt('end_date', now.toIso8601String())
          .order('end_date', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get past bookings: $e');
    }
  }

  // --- RPC helpers using DB functions ---
  // Calls public.is_period_available(property_id, start, end) -> boolean
  Future<bool> isPeriodAvailableRPC({
    required String propertyId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      if (!end.isAfter(start)) {
        throw Exception('تاريخ النهاية يجب أن يكون بعد تاريخ البداية.');
      }
      final res = await _supabase.rpc('is_period_available', params: {
        'p_property_id': propertyId,
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
      });
      if (res is bool) return res;
      // Supabase may return 0/1 in some cases
      if (res is int) return res == 1;
      throw Exception('Unexpected RPC return type for is_period_available');
    } catch (e) {
      throw Exception('فشل فحص التوفر عبر RPC: $e');
    }
  }

  // Calls public.get_booked_ranges(property_id, from, to)
  // Returns list of {check_in, check_out}
  Future<List<Map<String, DateTime>>> getBookedRangesRPC({
    required String propertyId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final res = await _supabase.rpc('get_booked_ranges', params: {
        'p_property_id': propertyId,
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      });
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        return {
          'start_date': DateTime.parse(row['start_date'] as String),
          'end_date': DateTime.parse(row['end_date'] as String),
        };
      }).toList();
    } catch (e) {
      throw Exception('فشل جلب الفترات المحجوزة عبر RPC: $e');
    }
  }
}
