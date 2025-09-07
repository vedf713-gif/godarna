import 'package:flutter/material.dart';
import 'package:godarna/models/booking_model.dart';
import 'package:godarna/services/booking_service.dart';
import 'package:godarna/utils/cache_manager.dart';
import 'package:godarna/utils/optimistic_ui_manager.dart';
import 'package:godarna/utils/realtime_sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

/// مزود الحجوزات - إدارة العمليات المتعلقة بالحجوزات
class BookingProvider with ChangeNotifier, OptimisticOperationsMixin, RealtimeSyncMixin {
  final BookingService _bookingService = BookingService.instance;
  final CacheManager _cacheManager = CacheManager.instance;
  
  List<BookingModel> _bookings = [];
  List<BookingModel> _userBookings = [];
  List<BookingModel> _hostBookings = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  String? _error;
  
  RealtimeChannel? _realtimeChannel;

  /// تهيئة المزود مع المزامنة الفورية
  void initializeRealtime() {
    startRealtimeSync(RealtimeEventType.bookings, onEvent: (event) {
      debugPrint('🔄 تحديث فوري للحجوزات: ${event.action}');
      if (event.action == RealtimeAction.insert ||
          event.action == RealtimeAction.delete ||
          event.action == RealtimeAction.update) {
        // إعادة جلب الحجوزات من الخادم
        fetchBookings(forceRefresh: true);
      }
    });

    // إضافة اشتراك Realtime مباشر
    _realtimeChannel = _bookingService.subscribeToBookings(
      onInsert: (data) {
        dev.log('📅 [Booking] New booking created: ${data['id']}');
        final newBooking = BookingModel.fromJson(data);
        _bookings.add(newBooking);
        _categorizeBookings();
        notifyListeners();
      },
      onUpdate: (data) {
        dev.log('📅 [Booking] Booking updated: ${data['id']}');
        final updatedBooking = BookingModel.fromJson(data);
        final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
        if (index != -1) {
          _bookings[index] = updatedBooking;
          _categorizeBookings();
          notifyListeners();
        }
      },
      onDelete: (data) {
        dev.log('📅 [Booking] Booking deleted: ${data['id']}');
        _bookings.removeWhere((b) => b.id == data['id']);
        _categorizeBookings();
        notifyListeners();
      },
    );
  }

  void _categorizeBookings() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      _userBookings = _bookings.where((b) => b.tenantId == currentUserId).toList();
      _hostBookings = _bookings.where((b) => b.hostId == currentUserId).toList();
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
  
  // مفاتيح التخزين المؤقت
  static const String _allBookingsKey = 'cache_all_bookings';
  static const String _userBookingsKey = 'cache_user_bookings';
  static const String _hostBookingsKey = 'cache_host_bookings';

  // Getters
  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get userBookings => _userBookings;
  List<BookingModel> get hostBookings => _hostBookings;
  List<BookingModel> get upcomingBookings {
    final now = DateTime.now();
    return _userBookings.where((b) {
      return (b.status == 'pending' || b.status == 'confirmed') && b.checkIn.isAfter(now);
    }).toList();
  }
  List<BookingModel> get activeBookings {
    final now = DateTime.now();
    return _userBookings.where((b) {
      return b.status == 'confirmed' && (now.isAfter(b.checkIn) && now.isBefore(b.checkOut));
    }).toList();
  }
  List<BookingModel> get completedBookings {
    final now = DateTime.now();
    return _userBookings.where((b) {
      return b.status == 'completed' || (b.status == 'confirmed' && b.checkOut.isBefore(now));
    }).toList();
  }
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize bookings
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await fetchBookings();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all bookings (for admin) with caching
  Future<void> fetchBookings({bool forceRefresh = false}) async {
    try {
      // جلب من التخزين المؤقت أولاً
      if (!forceRefresh) {
        final cachedBookings = await _cacheManager.get<List<dynamic>>(_allBookingsKey);
        if (cachedBookings != null) {
          _bookings = cachedBookings.map((data) => BookingModel.fromJson(data)).toList();
          notifyListeners();
          // تحديث في الخلفية
          _fetchAndCacheAllBookings(updateUI: false);
          return;
        }
      }
      
      _setLoading(true);
      _clearError();
      await _fetchAndCacheAllBookings();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// جلب وحفظ جميع الحجوزات في التخزين المؤقت
  Future<void> _fetchAndCacheAllBookings({bool updateUI = true}) async {
    final bookings = await _bookingService.getBookings();
    
    // حفظ في التخزين المؤقت
    await _cacheManager.set(
      _allBookingsKey,
      bookings.map((b) => b.toJson()).toList(),
      duration: CacheManager.shortCacheDuration,
    );
    
    if (updateUI) {
      _bookings = bookings;
      notifyListeners();
    }
  }

  // Fetch user bookings (as tenant) with caching
  Future<void> fetchUserBookings(String userId, {bool forceRefresh = false}) async {
    try {
      final cacheKey = '${_userBookingsKey}_$userId';
      
      // جلب من التخزين المؤقت أولاً
      if (!forceRefresh) {
        final cachedBookings = await _cacheManager.get<List<dynamic>>(cacheKey);
        if (cachedBookings != null) {
          _userBookings = cachedBookings.map((data) => BookingModel.fromJson(data)).toList();
          notifyListeners();
          // تحديث في الخلفية
          _fetchAndCacheUserBookings(userId, updateUI: false);
          return;
        }
      }
      
      _setLoading(true);
      _clearError();
      await _fetchAndCacheUserBookings(userId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// جلب وحفظ حجوزات المستخدم في التخزين المؤقت
  Future<void> _fetchAndCacheUserBookings(String userId, {bool updateUI = true}) async {
    final bookings = await _bookingService.getBookingsByTenant(userId);
    final cacheKey = '${_userBookingsKey}_$userId';
    
    // حفظ في التخزين المؤقت
    await _cacheManager.set(
      cacheKey,
      bookings.map((b) => b.toJson()).toList(),
      duration: CacheManager.defaultCacheDuration,
    );
    
    if (updateUI) {
      _userBookings = bookings;
      notifyListeners();
    }
  }

  // Fetch host bookings with caching
  Future<void> fetchHostBookings(String hostId, {bool forceRefresh = false}) async {
    try {
      final cacheKey = '${_hostBookingsKey}_$hostId';
      
      // جلب من التخزين المؤقت أولاً
      if (!forceRefresh) {
        final cachedBookings = await _cacheManager.get<List<dynamic>>(cacheKey);
        if (cachedBookings != null) {
          _hostBookings = cachedBookings.map((data) => BookingModel.fromJson(data)).toList();
          notifyListeners();
          // تحديث في الخلفية
          _fetchAndCacheHostBookings(hostId, updateUI: false);
          return;
        }
      }
      
      _setLoading(true);
      _clearError();
      await _fetchAndCacheHostBookings(hostId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// جلب وحفظ حجوزات المضيف في التخزين المؤقت
  Future<void> _fetchAndCacheHostBookings(String hostId, {bool updateUI = true}) async {
    final bookings = await _bookingService.getBookingsByHost(hostId);
    final cacheKey = '${_hostBookingsKey}_$hostId';
    
    // حفظ في التخزين المؤقت
    await _cacheManager.set(
      cacheKey,
      bookings.map((b) => b.toJson()).toList(),
      duration: CacheManager.defaultCacheDuration,
    );
    
    if (updateUI) {
      _hostBookings = bookings;
      notifyListeners();
    }
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final booking = await _bookingService.getBookingById(bookingId);
      _selectedBooking = booking;
      return booking;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Create new booking with optimistic updates
  Future<bool> createBooking({
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
    final tempBooking = BookingModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      tenantId: tenantId,
      hostId: hostId,
      startDate: checkIn,
      endDate: checkOut,
      nights: nights,
      totalPrice: totalPrice,
      paymentMethod: paymentMethod,
      notes: notes ?? '',
      status: 'pending',
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await performOptimisticOperation<bool>(
      operationId: 'create_booking_${tempBooking.id}',
      optimisticUpdate: () {
        _userBookings.insert(0, tempBooking);
        _bookings.insert(0, tempBooking);
      },
      serverOperation: () async {
        final booking = await _bookingService.createBooking(
          propertyId: propertyId,
          tenantId: tenantId,
          hostId: hostId,
          checkIn: checkIn,
          checkOut: checkOut,
          nights: nights,
          totalPrice: totalPrice,
          paymentMethod: paymentMethod,
          notes: notes,
        );
        
        if (booking != null) {
          // استبدال الحجز المؤقت بالحقيقي
          final tempIndex = _userBookings.indexWhere((b) => b.id == tempBooking.id);
          if (tempIndex != -1) {
            _userBookings[tempIndex] = booking;
          }
          
          final allIndex = _bookings.indexWhere((b) => b.id == tempBooking.id);
          if (allIndex != -1) {
            _bookings[allIndex] = booking;
          }
          
          // تحديث التخزين المؤقت
          _invalidateBookingCaches(tenantId, hostId);
          
          return true;
        }
        return false;
      },
      rollbackUpdate: () {
        _userBookings.removeWhere((b) => b.id == tempBooking.id);
        _bookings.removeWhere((b) => b.id == tempBooking.id);
      },
      successMessage: 'تم إنشاء الحجز بنجاح',
      errorMessage: 'فشل في إنشاء الحجز',
    );
  }

  // Update booking status with optimistic updates
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    // حفظ الحالة الحالية للتراجع
    final booking = _findBookingById(bookingId);
    final originalStatus = booking?.status;
    
    return await performOptimisticOperation<bool>(
      operationId: 'update_status_${bookingId}_$status',
      optimisticUpdate: () {
        _updateLocalBookingStatus(bookingId, status);
      },
      serverOperation: () async {
        final success = await _bookingService.updateBookingStatus(bookingId, status);
        if (success) {
          // تحديث التخزين المؤقت
          final booking = _findBookingById(bookingId);
          if (booking != null) {
            _invalidateBookingCaches(booking.tenantId, booking.hostId);
          }
        }
        return success;
      },
      rollbackUpdate: () {
        if (originalStatus != null) {
          _updateLocalBookingStatus(bookingId, originalStatus);
        }
      },
      successMessage: 'تم تحديث حالة الحجز',
      errorMessage: 'فشل في تحديث حالة الحجز',
    );
  }

  // Confirm booking (host action)
  Future<bool> confirmBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, 'confirmed');
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, 'cancelled');
  }

  // Complete booking
  Future<bool> completeBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, 'completed');
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String bookingId, String paymentStatus) async {
    try {
      _setLoading(true);
      _clearError();
      
      final success = await _bookingService.updatePaymentStatus(bookingId, paymentStatus);
      if (success) {
        // Update local booking
        _updateLocalPaymentStatus(bookingId, paymentStatus);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add review and rating
  Future<bool> addReview({
    required String bookingId,
    required double rating,
    required String review,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final success = await _bookingService.addReview(
        bookingId: bookingId,
        rating: rating,
        review: review,
      );
      
      if (success) {
        // Update local booking
        _updateLocalReview(bookingId, rating, review);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get booking statistics
  Map<String, dynamic> getBookingStats() {
    final totalBookings = _bookings.length;
    final pendingBookings = _bookings.where((b) => b.isPending).length;
    final confirmedBookings = _bookings.where((b) => b.isConfirmed).length;
    final completedBookings = _bookings.where((b) => b.isCompleted).length;
    final cancelledBookings = _bookings.where((b) => b.isCancelled).length;
    
    final totalRevenue = _bookings
        .where((b) => b.isPaid)
        .fold(0.0, (sum, b) => sum + b.totalPrice);
    
    return {
      'total': totalBookings,
      'pending': pendingBookings,
      'confirmed': confirmedBookings,
      'completed': completedBookings,
      'cancelled': cancelledBookings,
      'revenue': totalRevenue,
    };
  }

  // Get user booking statistics
  Map<String, dynamic> getUserBookingStats(String userId) {
    final userBookings = _bookings.where((b) => b.tenantId == userId).toList();
    final totalBookings = userBookings.length;
    final activeBookings = userBookings.where((b) => b.isConfirmed || b.isPending).length;
    final completedBookings = userBookings.where((b) => b.isCompleted).length;
    
    return {
      'total': totalBookings,
      'active': activeBookings,
      'completed': completedBookings,
    };
  }

  // Get host booking statistics
  Map<String, dynamic> getHostBookingStats(String hostId) {
    final hostBookings = _bookings.where((b) => b.hostId == hostId).toList();
    final totalBookings = hostBookings.length;
    final pendingBookings = hostBookings.where((b) => b.isPending).length;
    final confirmedBookings = hostBookings.where((b) => b.isConfirmed).length;
    final completedBookings = hostBookings.where((b) => b.isCompleted).length;
    
    final totalRevenue = hostBookings
        .where((b) => b.isPaid)
        .fold(0.0, (sum, b) => sum + b.totalPrice);
    
    return {
      'total': totalBookings,
      'pending': pendingBookings,
      'confirmed': confirmedBookings,
      'completed': completedBookings,
      'revenue': totalRevenue,
    };
  }

  // Private methods for updating local state
  void _updateLocalBookingStatus(String bookingId, String status) {
    final allBookings = [..._bookings, ..._userBookings, ..._hostBookings];
    for (final booking in allBookings) {
      if (booking.id == bookingId) {
        final updatedBooking = booking.copyWith(status: status);
        _updateBookingInLists(updatedBooking);
        break;
      }
    }
  }

  void _updateLocalPaymentStatus(String bookingId, String paymentStatus) {
    final allBookings = [..._bookings, ..._userBookings, ..._hostBookings];
    for (final booking in allBookings) {
      if (booking.id == bookingId) {
        final updatedBooking = booking.copyWith(paymentStatus: paymentStatus);
        _updateBookingInLists(updatedBooking);
        break;
      }
    }
  }

  void _updateLocalReview(String bookingId, double rating, String review) {
    final allBookings = [..._bookings, ..._userBookings, ..._hostBookings];
    for (final booking in allBookings) {
      if (booking.id == bookingId) {
        final updatedBooking = booking.copyWith(
          rating: rating,
          review: review,
          reviewDate: DateTime.now(),
        );
        _updateBookingInLists(updatedBooking);
        break;
      }
    }
  }

  void _updateBookingInLists(BookingModel updatedBooking) {
    // Update in main bookings list
    final mainIndex = _bookings.indexWhere((b) => b.id == updatedBooking.id);
    if (mainIndex != -1) {
      _bookings[mainIndex] = updatedBooking;
    }
    
    // Update in user bookings list
    final userIndex = _userBookings.indexWhere((b) => b.id == updatedBooking.id);
    if (userIndex != -1) {
      _userBookings[userIndex] = updatedBooking;
    }
    
    // Update in host bookings list
    final hostIndex = _hostBookings.indexWhere((b) => b.id == updatedBooking.id);
    if (hostIndex != -1) {
      _hostBookings[hostIndex] = updatedBooking;
    }
    
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  /// البحث عن حجز بالمعرف
  BookingModel? _findBookingById(String bookingId) {
    // البحث في جميع القوائم
    for (final booking in [..._bookings, ..._userBookings, ..._hostBookings]) {
      if (booking.id == bookingId) {
        return booking;
      }
    }
    return null;
  }
  
  /// إلغاء صحة التخزين المؤقت للحجوزات
  void _invalidateBookingCaches(String tenantId, String hostId) {
    _cacheManager.remove(_allBookingsKey);
    _cacheManager.remove('${_userBookingsKey}_$tenantId');
    _cacheManager.remove('${_hostBookingsKey}_$hostId');
  }
  
  /// تحديث الحجوزات في الخلفية
  Future<void> refreshInBackground({
    String? userId,
    String? hostId,
    bool refreshAll = false,
  }) async {
    if (refreshAll) {
      await _cacheManager.refreshInBackground(
        _allBookingsKey,
        () => _fetchAndCacheAllBookings(updateUI: false),
      );
    }
    
    if (userId != null) {
      await _cacheManager.refreshInBackground(
        '${_userBookingsKey}_$userId',
        () => _fetchAndCacheUserBookings(userId, updateUI: false),
      );
    }
    
    if (hostId != null) {
      await _cacheManager.refreshInBackground(
        '${_hostBookingsKey}_$hostId',
        () => _fetchAndCacheHostBookings(hostId, updateUI: false),
      );
    }
  }
}