import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/models/notification_model.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // متغيرات لمنع إعادة المحاولة اللانهائية
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isRetrying = false;
  RealtimeChannel? _currentChannel;

  Future<void> initialize() async {
    try {
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      // تأخير إعداد Realtime للتأكد من اكتمال تهيئة Supabase
      Future.delayed(const Duration(seconds: 3), () {
        if (_supabase.auth.currentUser != null) {
          resetRetryCount(); // إعادة تعيين عداد المحاولات
          _setupRealtimeSubscription();
        }
      });
      
      debugPrint('✅ [Notifications] Service initialized successfully');
    } catch (e) {
      debugPrint('❌ [Notifications] Error initializing service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Android: لا حاجة لطلب الإذن عبر الإضافة في هذا الإصدار
    await _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ [Notifications] No user logged in for realtime subscription');
      return;
    }
    
    // منع إعادة المحاولة إذا كانت جارية أو تجاوزنا الحد الأقصى
    if (_isRetrying || _retryCount >= _maxRetries) {
      if (_retryCount >= _maxRetries) {
        debugPrint('❌ [Notifications] Max retries reached. Disabling realtime notifications.');
      }
      return;
    }
    
    _isRetrying = true;
    debugPrint('🔄 [Notifications] Setting up realtime subscription for user: $userId (attempt ${_retryCount + 1}/$_maxRetries)');
    
    try {
      // إزالة القناة السابقة إذا كانت موجودة
      if (_currentChannel != null) {
        _currentChannel!.unsubscribe();
        _currentChannel = null;
      }
      
      // إعداد قناة جديدة
      _currentChannel = _supabase.channel('notifications_${userId}_${DateTime.now().millisecondsSinceEpoch}');
      
      _currentChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          try {
            debugPrint('🔍 [Notifications] New notification received: ${payload.newRecord}');
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              _handleNewNotification(newRecord);
            }
          } catch (e) {
            debugPrint('❌ [Notifications] Error processing realtime event: $e');
          }
        },
      );
      
      _currentChannel!.subscribe((status, [error]) {
        debugPrint('🔍 [Notifications] Realtime status: $status');
        
        switch (status) {
          case RealtimeSubscribeStatus.subscribed:
            debugPrint('✅ [Notifications] Successfully subscribed to realtime notifications');
            _retryCount = 0; // إعادة تعيين عداد المحاولات
            _isRetrying = false;
            break;
          case RealtimeSubscribeStatus.channelError:
            debugPrint('❌ [Notifications] Channel error: $error');
            _handleSubscriptionFailure();
            break;
          case RealtimeSubscribeStatus.closed:
            debugPrint('⚠️ [Notifications] Channel closed');
            _handleSubscriptionFailure();
            break;
          case RealtimeSubscribeStatus.timedOut:
            debugPrint('⏰ [Notifications] Subscription timed out');
            _handleSubscriptionFailure();
            break;
        }
      });
      
    } catch (e) {
      debugPrint('❌ [Notifications] Error setting up realtime subscription: $e');
      _handleSubscriptionFailure();
    }
  }
  
  void _handleSubscriptionFailure() {
    _isRetrying = false;
    _retryCount++;
    
    if (_retryCount < _maxRetries) {
      final delaySeconds = _retryCount * 5; // تأخير متزايد: 5, 10, 15 ثانية
      debugPrint('🔄 [Notifications] Retrying in $delaySeconds seconds... ($_retryCount/$_maxRetries)');
      
      Future.delayed(Duration(seconds: delaySeconds), () {
        if (_supabase.auth.currentUser != null && _retryCount < _maxRetries) {
          _setupRealtimeSubscription();
        }
      });
    } else {
      debugPrint('❌ [Notifications] Max retries reached. Realtime notifications disabled.');
    }
  }
  
  void resetRetryCount() {
    _retryCount = 0;
    _isRetrying = false;
    debugPrint('🔄 [Notifications] Retry count reset. Realtime can be re-enabled.');
  }

  void _handleNewNotification(Map<String, dynamic> payload) {
    try {
      debugPrint('📱 [Notifications] Processing notification: ${payload['title']}');
      
      // التحقق من صحة البيانات
      if (payload['title'] == null || payload['message'] == null) {
        debugPrint('⚠️ [Notifications] Invalid notification data - missing title or message');
        return;
      }
      
      final notification = NotificationModel.fromJson(payload);
      debugPrint('📱 [Notifications] Parsed notification: ${notification.title}');
      
      // عرض الإشعار المحلي فقط إذا كان التطبيق في الخلفية
      _showLocalNotification(notification);
      debugPrint('✅ [Notifications] Local notification shown successfully');
    } catch (e) {
      debugPrint('❌ [Notifications] Error handling notification: $e');
      debugPrint('❌ [Notifications] Payload: $payload');
    }
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'godarna_notifications',
      'GoDarna Notifications',
      channelDescription: 'Notifications from GoDarna app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: notification.data?.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    if (response.payload != null) {
      // Navigate to appropriate screen based on notification data
      dev.log('Notification tapped: ${response.payload}', name: 'NotificationsService');
    }
  }

  // Send notification to specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 [Notifications] Sending notification to user: $userId');
      debugPrint('📤 [Notifications] Title: $title');
      debugPrint('📤 [Notifications] Message: $message');
      
      final result = await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      debugPrint('✅ [Notifications] Notification inserted successfully: ${result['id']}');
    } catch (e) {
      debugPrint('❌ [Notifications] Error sending notification: $e');
      dev.log('Error sending notification: $e', name: 'NotificationsService');
    }
  }

  // Send notification to multiple users
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
      }).toList();

      await _supabase.from('notifications').insert(notifications);
    } catch (e) {
      dev.log('Error sending notifications: $e', name: 'NotificationsService');
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      dev.log('Error getting notifications: $e', name: 'NotificationsService');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      dev.log('Error marking notification as read: $e', name: 'NotificationsService');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      dev.log('Error marking all notifications as read: $e', name: 'NotificationsService');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      dev.log('Error deleting notification: $e', name: 'NotificationsService');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return 0;
      }
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      dev.log('Error getting unread count: $e', name: 'NotificationsService');
      return 0;
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      dev.log('Error clearing notifications: $e', name: 'NotificationsService');
    }
  }
}