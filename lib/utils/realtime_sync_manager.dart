import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/utils/cache_manager.dart';

/// مدير المزامنة الفورية للبيانات مع Supabase Realtime
class RealtimeSyncManager {
  static RealtimeSyncManager? _instance;
  static RealtimeSyncManager get instance => _instance ??= RealtimeSyncManager._internal();
  
  RealtimeSyncManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheManager _cacheManager = CacheManager.instance;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<RealtimeEvent>> _eventStreams = {};
  final Map<String, List<RealtimeCallback>> _callbacks = {};
  
  bool _isInitialized = false;

  /// تهيئة مدير المزامنة الفورية
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // الاستماع للمفضلة
      await _setupFavoritesSync();
      
      // الاستماع للحجوزات
      await _setupBookingsSync();
      
      // الاستماع للعقارات
      await _setupPropertiesSync();
      
      _isInitialized = true;
      debugPrint('🔄 تم تهيئة مدير المزامنة الفورية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة المزامنة الفورية: $e');
    }
  }

  /// إعداد مزامنة المفضلة
  Future<void> _setupFavoritesSync() async {
    const channelName = 'favorites_realtime';
    
    final channel = _supabase.channel(channelName);
    _channels[channelName] = channel;
    
    final eventStream = StreamController<RealtimeEvent>.broadcast();
    _eventStreams[channelName] = eventStream;
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorites',
          callback: (payload) {
            _handleFavoritesChange(payload);
            eventStream.add(RealtimeEvent(
              type: RealtimeEventType.favorites,
              action: _mapPostgresAction(payload.eventType),
              data: payload.newRecord,
            ));
          },
        )
        .subscribe();
  }

  /// إعداد مزامنة الحجوزات
  Future<void> _setupBookingsSync() async {
    const channelName = 'bookings_realtime';
    
    final channel = _supabase.channel(channelName);
    _channels[channelName] = channel;
    
    final eventStream = StreamController<RealtimeEvent>.broadcast();
    _eventStreams[channelName] = eventStream;
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            _handleBookingsChange(payload);
            eventStream.add(RealtimeEvent(
              type: RealtimeEventType.bookings,
              action: _mapPostgresAction(payload.eventType),
              data: payload.newRecord,
            ));
          },
        )
        .subscribe();
  }

  /// إعداد مزامنة العقارات
  Future<void> _setupPropertiesSync() async {
    const channelName = 'properties_realtime';
    
    final channel = _supabase.channel(channelName);
    _channels[channelName] = channel;
    
    final eventStream = StreamController<RealtimeEvent>.broadcast();
    _eventStreams[channelName] = eventStream;
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'listings',
          callback: (payload) {
            _handlePropertiesChange(payload);
            eventStream.add(RealtimeEvent(
              type: RealtimeEventType.properties,
              action: _mapPostgresAction(payload.eventType),
              data: payload.newRecord,
            ));
          },
        )
        .subscribe();
  }

  /// معالجة تغييرات المفضلة
  void _handleFavoritesChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        debugPrint('🔄 إضافة مفضلة جديدة: ${payload.newRecord['id']}');
        _invalidateFavoritesCache();
        break;
      case PostgresChangeEvent.delete:
        debugPrint('🔄 حذف مفضلة: ${payload.oldRecord['id']}');
        _invalidateFavoritesCache();
        break;
      case PostgresChangeEvent.update:
        debugPrint('🔄 تحديث مفضلة: ${payload.newRecord['id']}');
        _invalidateFavoritesCache();
        break;
      default:
        break;
    }
  }

  /// معالجة تغييرات الحجوزات
  void _handleBookingsChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        debugPrint('🔄 حجز جديد: ${payload.newRecord['id']}');
        _invalidateBookingsCache();
        break;
      case PostgresChangeEvent.delete:
        debugPrint('🔄 حذف حجز: ${payload.oldRecord['id']}');
        _invalidateBookingsCache();
        break;
      case PostgresChangeEvent.update:
        debugPrint('🔄 تحديث حجز: ${payload.newRecord['id']} - الحالة: ${payload.newRecord['status']}');
        _invalidateBookingsCache();
        break;
      default:
        break;
    }
  }

  /// معالجة تغييرات العقارات
  void _handlePropertiesChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        debugPrint('🔄 عقار جديد: ${payload.newRecord['id']}');
        _invalidatePropertiesCache();
        break;
      case PostgresChangeEvent.delete:
        debugPrint('🔄 حذف عقار: ${payload.oldRecord['id']}');
        _invalidatePropertiesCache();
        break;
      case PostgresChangeEvent.update:
        debugPrint('🔄 تحديث عقار: ${payload.newRecord['id']}');
        _invalidatePropertiesCache();
        break;
      default:
        break;
    }
  }

  /// إلغاء صحة التخزين المؤقت للمفضلة
  void _invalidateFavoritesCache() {
    _cacheManager.remove('cache_favorites');
    // إلغاء جميع cache keys للمستخدمين المختلفين
    _invalidateCacheByPattern('cache_favorites_');
  }

  /// إلغاء صحة التخزين المؤقت للحجوزات
  void _invalidateBookingsCache() {
    _cacheManager.remove('cache_all_bookings');
    _invalidateCacheByPattern('cache_user_bookings_');
    _invalidateCacheByPattern('cache_host_bookings_');
  }

  /// إلغاء صحة التخزين المؤقت للعقارات
  void _invalidatePropertiesCache() {
    _cacheManager.remove('cache_properties');
    _invalidateCacheByPattern('cache_my_properties_');
  }

  /// إلغاء صحة التخزين المؤقت بنمط معين
  Future<void> _invalidateCacheByPattern(String pattern) async {
    // هذه دالة مساعدة لإلغاء cache keys بنمط معين
    // يمكن تحسينها لاحقاً بناءً على تطبيق CacheManager
    debugPrint('إلغاء صحة التخزين المؤقت للنمط: $pattern');
  }

  /// تحويل إجراء PostgreSQL إلى إجراء داخلي
  RealtimeAction _mapPostgresAction(PostgresChangeEvent event) {
    switch (event) {
      case PostgresChangeEvent.insert:
        return RealtimeAction.insert;
      case PostgresChangeEvent.update:
        return RealtimeAction.update;
      case PostgresChangeEvent.delete:
        return RealtimeAction.delete;
      default:
        return RealtimeAction.unknown;
    }
  }

  /// الحصول على دفق الأحداث لنوع معين
  Stream<RealtimeEvent>? getEventStream(RealtimeEventType type) {
    final channelName = _getChannelName(type);
    return _eventStreams[channelName]?.stream;
  }

  /// الحصول على اسم القناة حسب النوع
  String _getChannelName(RealtimeEventType type) {
    switch (type) {
      case RealtimeEventType.favorites:
        return 'favorites_realtime';
      case RealtimeEventType.bookings:
        return 'bookings_realtime';
      case RealtimeEventType.properties:
        return 'properties_realtime';
    }
  }

  /// تشغيل مزامنة يدوية لجدول معين
  Future<void> manualSync(RealtimeEventType type) async {
    switch (type) {
      case RealtimeEventType.favorites:
        _invalidateFavoritesCache();
        break;
      case RealtimeEventType.bookings:
        _invalidateBookingsCache();
        break;
      case RealtimeEventType.properties:
        _invalidatePropertiesCache();
        break;
    }
    debugPrint('🔄 تم تشغيل المزامنة اليدوية لـ ${type.name}');
  }

  /// إيقاف المزامنة الفورية
  Future<void> dispose() async {
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();
    
    for (final stream in _eventStreams.values) {
      await stream.close();
    }
    _eventStreams.clear();
    
    _isInitialized = false;
    debugPrint('🔄 تم إيقاف مدير المزامنة الفورية');
  }

  /// الحصول على حالة الاتصال
  bool get isConnected => _supabase.realtime.isConnected;

  /// إعادة الاتصال يدوياً
  Future<void> reconnect() async {
    await dispose();
    await initialize();
  }

  /// إعداد مزامنة جدول معين
  Future<void> setupTableSync(String tableName) async {
    _callbacks[tableName] = _callbacks[tableName] ?? <RealtimeCallback>[];
    _channels[tableName] = _channels[tableName] ?? _supabase
        .channel('$tableName-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            _handleRealtimeUpdate(tableName, payload);
          },
        )
        .subscribe();
  }

  /// معالجة تحديثات المزامنة الفورية
  void _handleRealtimeUpdate(String tableName, PostgresChangePayload payload) {
    _callbacks[tableName]?.forEach((callback) {
      callback(payload);
    });
  }

  /// إضافة دالة استدعاء للمزامنة الفورية
  void addRealtimeCallback(String tableName, RealtimeCallback callback) {
    _callbacks[tableName] ??= <RealtimeCallback>[];
    _callbacks[tableName]!.add(callback);
  }

  /// إزالة دالة استدعاء للمزامنة الفورية
  void removeRealtimeCallback(String tableName, RealtimeCallback callback) {
    _callbacks[tableName]?.remove(callback);
  }
}

/// حدث المزامنة الفورية
class RealtimeEvent {
  final RealtimeEventType type;
  final RealtimeAction action;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.action,
    this.data,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'RealtimeEvent(type: $type, action: $action, data: $data, timestamp: $timestamp)';
  }
}

/// أنواع أحداث المزامنة الفورية
enum RealtimeEventType {
  favorites,
  bookings,
  properties,
}

/// إجراءات المزامنة الفورية
enum RealtimeAction {
  insert,
  update,
  delete,
  unknown,
}

/// دالة استدعاء للمزامنة الفورية
typedef RealtimeCallback = void Function(PostgresChangePayload payload);

/// مزين للمزودات التي تحتاج مزامنة فورية
mixin RealtimeSyncMixin on ChangeNotifier {
  final RealtimeSyncManager _realtimeManager = RealtimeSyncManager.instance;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  
  /// بدء الاستماع للمزامنة الفورية
  void startRealtimeSync(RealtimeEventType type, {
    Function(RealtimeEvent)? onEvent,
  }) {
    _realtimeSubscription?.cancel();
    
    final eventStream = _realtimeManager.getEventStream(type);
    if (eventStream != null) {
      _realtimeSubscription = eventStream.listen((event) {
        debugPrint('📡 حدث مزامنة فورية: $event');
        onEvent?.call(event);
        notifyListeners();
      });
    }
  }
  
  /// إيقاف الاستماع للمزامنة الفورية
  void stopRealtimeSync() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }
  
  /// تشغيل مزامنة يدوية
  Future<void> triggerManualSync(RealtimeEventType type) async {
    await _realtimeManager.manualSync(type);
  }
  
  @override
  void dispose() {
    stopRealtimeSync();
    super.dispose();
  }
}
