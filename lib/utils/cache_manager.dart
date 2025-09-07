import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مدير التخزين المؤقت المتقدم لتطبيق GoDarna
/// يوفر تخزين مؤقت ذكي مع انتهاء صلاحية وتحديث في الخلفية
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._internal();

  CacheManager._internal();

  SharedPreferences? _prefs;
  final Map<String, Timer> _expirationTimers = {};
  final Map<String, dynamic> _memoryCache = {};

  // مدة انتهاء الصلاحية الافتراضية
  static const Duration defaultCacheDuration = Duration(minutes: 15);
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration longCacheDuration = Duration(hours: 1);

  /// تهيئة مدير التخزين المؤقت
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _cleanExpiredCache();
  }

  /// حفظ البيانات في التخزين المؤقت
  Future<void> set<T>(
    String key,
    T data, {
    Duration? duration,
    bool useMemoryCache = true,
  }) async {
    await initialize();

    final cacheDuration = duration ?? defaultCacheDuration;
    final expirationTime = DateTime.now().add(cacheDuration);

    final cacheData = {
      'data': data,
      'expiration': expirationTime.millisecondsSinceEpoch,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // حفظ في الذاكرة للوصول السريع
    if (useMemoryCache) {
      _memoryCache[key] = cacheData;
    }

    // حفظ في التخزين المحلي
    try {
      await _prefs!.setString(key, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('خطأ في حفظ البيانات في التخزين المؤقت: $e');
    }

    // تعيين مؤقت لانتهاء الصلاحية
    _setExpirationTimer(key, cacheDuration);
  }

  /// استرجاع البيانات من التخزين المؤقت
  Future<T?> get<T>(String key) async {
    await initialize();

    // البحث في الذاكرة أولاً
    if (_memoryCache.containsKey(key)) {
      final cacheData = _memoryCache[key] as Map<String, dynamic>;
      if (_isValidCache(cacheData)) {
        return cacheData['data'] as T?;
      } else {
        _memoryCache.remove(key);
      }
    }

    // البحث في التخزين المحلي
    try {
      final cachedString = _prefs!.getString(key);
      if (cachedString != null) {
        final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
        if (_isValidCache(cacheData)) {
          // إعادة تحميل البيانات في الذاكرة
          _memoryCache[key] = cacheData;
          return cacheData['data'] as T?;
        } else {
          await _prefs!.remove(key);
        }
      }
    } catch (e) {
      debugPrint('خطأ في استرجاع البيانات من التخزين المؤقت: $e');
    }

    return null;
  }

  /// التحقق من وجود البيانات في التخزين المؤقت
  Future<bool> has(String key) async {
    final data = await get<dynamic>(key);
    return data != null;
  }

  /// إزالة بيانات معينة من التخزين المؤقت
  Future<void> remove(String key) async {
    await initialize();

    _memoryCache.remove(key);
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);

    try {
      await _prefs!.remove(key);
    } catch (e) {
      debugPrint('خطأ في إزالة البيانات من التخزين المؤقت: $e');
    }
  }

  /// مسح جميع البيانات المؤقتة
  Future<void> clear() async {
    await initialize();

    _memoryCache.clear();
    for (var timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();

    try {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _prefs!.remove(key);
        }
      }
    } catch (e) {
      debugPrint('خطأ في مسح التخزين المؤقت: $e');
    }
  }

  /// تحديث البيانات في الخلفية
  Future<void> refreshInBackground<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? cacheDuration,
  }) async {
    try {
      final newData = await fetcher();
      await set(key, newData, duration: cacheDuration);
      debugPrint('تم تحديث البيانات في الخلفية للمفتاح: $key');
    } catch (e) {
      debugPrint('خطأ في تحديث البيانات في الخلفية: $e');
    }
  }

  /// استرجاع البيانات مع تحديث في الخلفية
  Future<T?> getWithBackgroundRefresh<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    T? cachedData;

    if (!forceRefresh) {
      cachedData = await get<T>(key);
    }

    // تحديث في الخلفية دون انتظار
    unawaited(refreshInBackground(key, fetcher, cacheDuration: cacheDuration));

    return cachedData ?? await fetcher();
  }

  /// التحقق من صلاحية البيانات المؤقتة
  bool _isValidCache(Map<String, dynamic> cacheData) {
    final expiration = cacheData['expiration'] as int?;
    if (expiration == null) return false;

    return DateTime.now().millisecondsSinceEpoch < expiration;
  }

  /// تعيين مؤقت لانتهاء الصلاحية
  void _setExpirationTimer(String key, Duration duration) {
    _expirationTimers[key]?.cancel();
    _expirationTimers[key] = Timer(duration, () {
      _memoryCache.remove(key);
      _prefs?.remove(key);
      _expirationTimers.remove(key);
    });
  }

  /// تنظيف البيانات المنتهية الصلاحية
  Future<void> _cleanExpiredCache() async {
    if (_prefs == null) return;

    try {
      final keys = _prefs!.getKeys();
      final expiredKeys = <String>[];

      for (final key in keys) {
        if (key.startsWith('cache_')) {
          final cachedString = _prefs!.getString(key);
          if (cachedString != null) {
            try {
              final cacheData =
                  jsonDecode(cachedString) as Map<String, dynamic>;
              if (!_isValidCache(cacheData)) {
                expiredKeys.add(key);
              }
            } catch (e) {
              expiredKeys.add(key); // إزالة البيانات التالفة
            }
          }
        }
      }

      for (final key in expiredKeys) {
        await _prefs!.remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        debugPrint('تم تنظيف ${expiredKeys.length} عنصر منتهي الصلاحية');
      }
    } catch (e) {
      debugPrint('خطأ في تنظيف التخزين المؤقت: $e');
    }
  }

  /// الحصول على معلومات التخزين المؤقت
  Future<Map<String, dynamic>> getCacheInfo() async {
    await initialize();

    final memorySize = _memoryCache.length;
    final storageKeys =
        _prefs!.getKeys().where((k) => k.startsWith('cache_')).length;

    return {
      'memoryCache': memorySize,
      'storageCache': storageKeys,
      'activeTimers': _expirationTimers.length,
    };
  }
}

/// مزود التخزين المؤقت للاستخدام مع Provider
class CacheProvider extends ChangeNotifier {
  final CacheManager _cacheManager = CacheManager.instance;

  Future<void> initialize() async {
    await _cacheManager.initialize();
  }

  Future<T?> get<T>(String key) => _cacheManager.get<T>(key);

  Future<void> set<T>(String key, T data, {Duration? duration}) async {
    await _cacheManager.set(key, data, duration: duration);
    notifyListeners();
  }

  Future<void> remove(String key) async {
    await _cacheManager.remove(key);
    notifyListeners();
  }

  Future<void> clear() async {
    await _cacheManager.clear();
    notifyListeners();
  }
}
