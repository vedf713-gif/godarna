import 'package:flutter/foundation.dart';
import 'package:godarna/models/notification_model.dart';
import 'package:godarna/services/notifications_service.dart';

/// مزود الإشعارات لإدارة حالة الإشعارات في التطبيق
class NotificationProvider with ChangeNotifier {
  final NotificationsService _notificationService = NotificationsService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// عدد الإشعارات غير المقروءة
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  /// هل يوجد إشعارات غير مقروءة
  bool get hasUnreadNotifications => unreadCount > 0;

  /// تحميل الإشعارات
  Future<void> loadNotifications() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _error = null;
    
    try {
      _notifications = await _notificationService.getUserNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('خطأ في تحميل الإشعارات: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('خطأ في تحديث الإشعار كمقروء: $e');
      notifyListeners();
    }
  }

  /// تحديث جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('خطأ في تحديث جميع الإشعارات كمقروءة: $e');
      notifyListeners();
    }
  }

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('خطأ في حذف الإشعار: $e');
      notifyListeners();
    }
  }

  /// مسح جميع الإشعارات
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('خطأ في مسح جميع الإشعارات: $e');
      notifyListeners();
    }
  }

  /// تحديث حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// إضافة إشعار جديد (للاستخدام مع realtime updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// تحديث إشعار موجود
  void updateNotification(NotificationModel updatedNotification) {
    final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
    if (index != -1) {
      _notifications[index] = updatedNotification;
      notifyListeners();
    }
  }
}
