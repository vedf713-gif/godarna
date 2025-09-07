// =====================================================
// سكريبت تفعيل Realtime لجميع الشاشات
// =====================================================

import 'package:flutter/foundation.dart';

/*
هذا الملف يحتوي على التعديلات المطلوبة لتفعيل Realtime في جميع الشاشات.
نظراً لوجود أخطاء في imports في home_screen.dart، سأقوم بإنشاء ملفات منفصلة للتعديلات.
*/

// 1. تعديل explore_screen.dart
const exploreScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _ExploreScreenState extends State<ExploreScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    subscribeToTable(
      table: 'properties',
      onInsert: (payload) {
        final provider = Provider.of<PropertyProvider>(context, listen: false);
        provider.fetchProperties(forceRefresh: true);
      },
      onUpdate: (payload) {
        final provider = Provider.of<PropertyProvider>(context, listen: false);
        provider.fetchProperties(forceRefresh: true);
      },
    );
  }
}
''';

// 2. تعديل search_screen.dart
const searchScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _SearchScreenState extends State<SearchScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    subscribeToTable(
      table: 'properties',
      onInsert: (payload) {
        _performSearch();
      },
      onUpdate: (payload) {
        _performSearch();
      },
    );
  }
}
''';

// 3. تعديل favorites_screen.dart
const favoritesScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _FavoritesScreenState extends State<FavoritesScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      subscribeToTable(
        table: 'favorites',
        filter: 'user_id',
        filterValue: currentUserId,
        onInsert: (payload) {
          _loadFavorites();
        },
        onDelete: (payload) {
          _loadFavorites();
        },
      );
    }
  }
}
''';

// 4. تعديل bookings_screen.dart
const bookingsScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _BookingsScreenState extends State<BookingsScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      subscribeToTable(
        table: 'bookings',
        filter: 'tenant_id',
        filterValue: currentUserId,
        onInsert: (payload) {
          final provider = Provider.of<BookingProvider>(context, listen: false);
          provider.fetchBookings();
        },
        onUpdate: (payload) {
          final provider = Provider.of<BookingProvider>(context, listen: false);
          provider.fetchBookings();
        },
      );
    }
  }
}
''';

// 5. تعديل notifications_screen.dart
const notificationsScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _NotificationsScreenState extends State<NotificationsScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      subscribeToTable(
        table: 'notifications',
        filter: 'user_id',
        filterValue: currentUserId,
        onInsert: (payload) {
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          provider.loadNotifications();
        },
        onUpdate: (payload) {
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          provider.loadNotifications();
        },
      );
    }
  }
}
''';

// 6. تعديل property_details_screen.dart
const propertyDetailsScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    subscribeToTable(
      table: 'properties',
      filter: 'id',
      filterValue: widget.propertyId,
      onUpdate: (payload) {
        _loadPropertyDetails();
      },
    );
    
    subscribeToTable(
      table: 'reviews',
      filter: 'property_id',
      filterValue: widget.propertyId,
      onInsert: (payload) {
        _loadReviews();
      },
    );
  }
}
''';

// 7. تعديل booking_details_screen.dart
const bookingDetailsScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _BookingDetailsScreenState extends State<BookingDetailsScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    subscribeToTable(
      table: 'bookings',
      filter: 'id',
      filterValue: widget.bookingId,
      onUpdate: (payload) {
        _loadBookingDetails();
      },
    );
    
    subscribeToTable(
      table: 'messages',
      filter: 'booking_id',
      filterValue: widget.bookingId,
      onInsert: (payload) {
        _loadMessages();
      },
    );
  }
}
''';

// 8. تعديل profile_screen.dart
const profileScreenRealtime = '''
import '../../mixins/realtime_mixin.dart';

class _ProfileScreenState extends State<ProfileScreen> with RealtimeMixin {
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      subscribeToTable(
        table: 'profiles',
        filter: 'id',
        filterValue: currentUserId,
        onUpdate: (payload) {
          _loadProfile();
        },
      );
      
      subscribeToTable(
        table: 'bookings',
        filter: 'tenant_id',
        filterValue: currentUserId,
        onInsert: (payload) {
          _updateStats();
        },
        onUpdate: (payload) {
          _updateStats();
        },
      );
    }
  }
}
''';

void main() {
  debugPrint('تم إنشاء سكريبت تفعيل Realtime لجميع الشاشات');
  debugPrint('يجب تطبيق هذه التعديلات يدوياً على كل ملف');
}
