import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

/// خدمة مركزية لإدارة جميع اشتراكات Realtime في التطبيق
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();
  
  static RealtimeService get instance => _instance;
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, RealtimeChannel> _activeChannels = {};

  /// تفعيل Realtime لجميع الجداول الأساسية
  void initializeGlobalRealtime() {
    dev.log('🚀 [Realtime] Initializing global realtime subscriptions', name: 'RealtimeService');
    
    // تفعيل Realtime للرسائل
    _subscribeToMessages();
    
    // تفعيل Realtime للحجوزات
    _subscribeToBookings();
    
    // تفعيل Realtime للعقارات
    _subscribeToProperties();
    
    // تفعيل Realtime للإشعارات
    _subscribeToNotifications();
    
    // تفعيل Realtime للملفات الشخصية
    _subscribeToProfiles();
  }

  /// اشتراك في تحديثات الرسائل
  void _subscribeToMessages() {
    final channel = _supabase
        .channel('global_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            dev.log('🔍 [Global] New message: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('message_inserted', payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            dev.log('🔍 [Global] Updated message: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('message_updated', payload.newRecord);
          },
        )
        .subscribe((status, [ref]) {
          dev.log('🔍 [Global] Messages realtime status: $status', name: 'RealtimeService');
        });
    
    _activeChannels['messages'] = channel;
  }

  /// اشتراك في تحديثات الحجوزات
  void _subscribeToBookings() {
    final channel = _supabase
        .channel('global_bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            dev.log('🔍 [Global] New booking: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('booking_inserted', payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            dev.log('🔍 [Global] Updated booking: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('booking_updated', payload.newRecord);
          },
        )
        .subscribe((status, [ref]) {
          dev.log('🔍 [Global] Bookings realtime status: $status', name: 'RealtimeService');
        });
    
    _activeChannels['bookings'] = channel;
  }

  /// اشتراك في تحديثات العقارات
  void _subscribeToProperties() {
    final channel = _supabase
        .channel('global_properties')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'properties',
          callback: (payload) {
            dev.log('🔍 [Global] New property: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('property_inserted', payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'properties',
          callback: (payload) {
            dev.log('🔍 [Global] Updated property: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('property_updated', payload.newRecord);
          },
        )
        .subscribe((status, [ref]) {
          dev.log('🔍 [Global] Properties realtime status: $status', name: 'RealtimeService');
        });
    
    _activeChannels['properties'] = channel;
  }

  /// اشتراك في تحديثات الإشعارات
  void _subscribeToNotifications() {
    final channel = _supabase
        .channel('global_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            dev.log('🔍 [Global] New notification: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('notification_inserted', payload.newRecord);
          },
        )
        .subscribe((status, [ref]) {
          dev.log('🔍 [Global] Notifications realtime status: $status', name: 'RealtimeService');
        });
    
    _activeChannels['notifications'] = channel;
  }

  /// اشتراك في تحديثات الملفات الشخصية
  void _subscribeToProfiles() {
    final channel = _supabase
        .channel('global_profiles')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            dev.log('🔍 [Global] Updated profile: ${payload.newRecord['id']}', name: 'RealtimeService');
            _broadcastEvent('profile_updated', payload.newRecord);
          },
        )
        .subscribe((status, [ref]) {
          dev.log('🔍 [Global] Profiles realtime status: $status', name: 'RealtimeService');
        });
    
    _activeChannels['profiles'] = channel;
  }

  /// بث الأحداث للمستمعين
  void _broadcastEvent(String eventType, Map<String, dynamic> data) {
    // يمكن إضافة نظام Event Bus هنا لاحقاً
    dev.log('📡 [Global] Broadcasting event: $eventType', name: 'RealtimeService');
  }

  /// إلغاء اشتراك معين
  void unsubscribeChannel(String channelName) {
    final channel = _activeChannels[channelName];
    if (channel != null) {
      _supabase.removeChannel(channel);
      _activeChannels.remove(channelName);
      dev.log('🔌 [Global] Unsubscribed from $channelName', name: 'RealtimeService');
    }
  }

  /// إلغاء جميع الاشتراكات
  void unsubscribeAll() {
    for (final entry in _activeChannels.entries) {
      _supabase.removeChannel(entry.value);
      dev.log('🔌 [Global] Unsubscribed from ${entry.key}', name: 'RealtimeService');
    }
    _activeChannels.clear();
  }

  /// الحصول على حالة الاتصال
  Map<String, String> getConnectionStatus() {
    final status = <String, String>{};
    for (final entry in _activeChannels.entries) {
      // يمكن إضافة منطق للحصول على حالة الاتصال الفعلية
      status[entry.key] = 'connected';
    }
    return status;
  }
}
