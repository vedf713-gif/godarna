import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/models/favorite_model.dart';
import 'package:godarna/models/property_model.dart';
import 'package:godarna/utils/cache_manager.dart';
import 'package:godarna/utils/optimistic_ui_manager.dart';
import 'package:godarna/utils/realtime_sync_manager.dart';

/// مزود المفضلة - إدارة العقارات المفضلة للمستخدم
class FavoritesProvider with ChangeNotifier, OptimisticOperationsMixin, RealtimeSyncMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheManager _cacheManager = CacheManager.instance;

  List<FavoriteModel> _favorites = [];
  bool _isLoading = false;
  String? _error;
  
  /// تهيئة المزود مع المزامنة الفورية
  void initializeRealtime() {
    startRealtimeSync(RealtimeEventType.favorites, onEvent: (event) {
      debugPrint('🔄 تحديث فوري للمفضلة: ${event.action}');
      if (event.action == RealtimeAction.insert ||
          event.action == RealtimeAction.delete ||
          event.action == RealtimeAction.update) {
        // إعادة جلب المفضلة من الخادم
        fetchFavorites(forceRefresh: true);
      }
    });
  }
  
  // مفاتيح التخزين المؤقت
  static const String _favoritesKey = 'cache_favorites';
  static const String _favoritePropertiesKey = 'cache_favorite_properties';

  // Getters
  List<FavoriteModel> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// الحصول على قائمة العقارات المفضلة فقط
  List<PropertyModel> get favoriteProperties {
    return _favorites
        .where((fav) => fav.property != null)
        .map((fav) => fav.property!)
        .toList();
  }

  /// الحصول على قائمة المفضلة المحذوفة (العقارات غير موجودة)
  List<FavoriteModel> get deletedFavorites {
    return _favorites.where((fav) => fav.property == null).toList();
  }

  /// التحقق من كون العقار مفضل
  bool isFavorite(String propertyId) {
    return _favorites.any((fav) => fav.listingId == propertyId);
  }

  /// جلب المفضلة من قاعدة البيانات مع التخزين المؤقت
  Future<void> fetchFavorites({bool forceRefresh = false}) async {
    try {
      debugPrint('🔄 بدء جلب المفضلة...');
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ المستخدم غير مسجل الدخول');
        _setError('المستخدم غير مسجل الدخول');
        return;
      }
      debugPrint('✅ المستخدم مسجل الدخول: ${user.id}');

      // محاولة جلب البيانات من التخزين المؤقت أولاً
      if (!forceRefresh) {
        debugPrint('🔄 فحص التخزين المؤقت...');
        final cachedFavorites = await _cacheManager.get<List<dynamic>>('${_favoritesKey}_${user.id}');
        if (cachedFavorites != null) {
          debugPrint('✅ تم العثور على بيانات مؤقتة: ${cachedFavorites.length} عنصر');
          _loadFavoritesFromCache(cachedFavorites);
          // تحديث في الخلفية
          _fetchAndCacheFavorites(user.id, updateUI: false);
          return;
        } else {
          debugPrint('⚠️ لا توجد بيانات مؤقتة');
        }
      }

      debugPrint('🔄 جلب البيانات من الخادم...');
      _setLoading(true);
      _setError(null);
      await _fetchAndCacheFavorites(user.id);

    } catch (e) {
      _setError('خطأ في جلب المفضلة: ${e.toString()}');
      debugPrint('Error fetching favorites: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// جلب وحفظ المفضلة في التخزين المؤقت
  Future<void> _fetchAndCacheFavorites(String userId, {bool updateUI = true}) async {
    debugPrint('📡 بدء استعلام قاعدة البيانات للمستخدم: $userId');
    
    try {
      final response = await _supabase.from('favorites').select('''
            id,
            tenant_id,
            listing_id,
            created_at,
            listings:listing_id (
              id,
              title,
              description,
              price_per_night,
              price_per_month,
              property_type,
              address,
              region,
              city,
              area,
              bedrooms,
              bathrooms,
              max_guests,
              amenities,
              photos,
              average_rating,
              review_count,
              lat,
              lng,
              host_id,
              is_available,
              created_at,
              updated_at
            )
          ''').eq('tenant_id', userId).order('created_at', ascending: false);

      debugPrint('📊 استجابة قاعدة البيانات: ${response.length} صف');
      
      final List<FavoriteModel> loadedFavorites = [];
      final List<String> orphanedFavoriteIds = [];

      for (final item in response as List) {
        debugPrint('🔍 معالجة عنصر: ${item['id']}');
        final listingData = item['listings'] as Map<String, dynamic>?;
        PropertyModel? property;

        if (listingData != null) {
          debugPrint('✅ بيانات العقار موجودة: ${listingData['title']}');
          try {
            property = PropertyModel.fromJson(listingData);
          } catch (e) {
            debugPrint('❌ خطأ في تحليل بيانات العقار: $e');
            orphanedFavoriteIds.add(item['id'] as String);
            continue;
          }
        } else {
          debugPrint('⚠️ لا توجد بيانات عقار للمفضلة: ${item['listing_id']}');
          orphanedFavoriteIds.add(item['id'] as String);
          continue; // تخطي المفضلة بدون عقار
        }

        loadedFavorites.add(FavoriteModel(
          id: item['id'] as String,
          tenantId: item['tenant_id'] as String,
          listingId: item['listing_id'] as String,
          createdAt: DateTime.parse(item['created_at'] as String),
          property: property,
        ));
      }
      
      // تنظيف المفضلة اليتيمة فوراً
      if (orphanedFavoriteIds.isNotEmpty) {
        debugPrint('🧹 تنظيف ${orphanedFavoriteIds.length} مفضلة يتيمة...');
        await _cleanupOrphanedFavorites(orphanedFavoriteIds);
      }

      debugPrint('💾 حفظ ${loadedFavorites.length} مفضلة صالحة في التخزين المؤقت');
      
      // حفظ في التخزين المؤقت (فقط المفضلة الصالحة)
      final validResponseData = response.where((item) => 
        item['listings'] != null && 
        !orphanedFavoriteIds.contains(item['id'])
      ).toList();
      
      await _cacheManager.set(
        '${_favoritesKey}_$userId',
        validResponseData,
        duration: CacheManager.defaultCacheDuration,
      );

      if (updateUI) {
        _favorites = loadedFavorites;
        debugPrint('🔄 تحديث الواجهة: ${_favorites.length} مفضلة صالحة');
        notifyListeners();
      } else {
        debugPrint('ℹ️ تم تجاهل تحديث الواجهة');
      }
      
    } catch (e) {
      debugPrint('❌ خطأ في جلب المفضلة: $e');
      if (updateUI) {
        _setError('فشل في جلب المفضلة: ${e.toString()}');
      }
    }
  }

  /// تحميل المفضلة من التخزين المؤقت
  void _loadFavoritesFromCache(List<dynamic> cachedData) {
    final List<FavoriteModel> loadedFavorites = [];

    for (final item in cachedData) {
      final listingData = item['listings'] as Map<String, dynamic>?;
      PropertyModel? property;

      if (listingData != null) {
        property = PropertyModel.fromJson(listingData);
      }

      loadedFavorites.add(FavoriteModel(
        id: item['id'] as String,
        tenantId: item['tenant_id'] as String,
        listingId: item['listing_id'] as String,
        createdAt: DateTime.parse(item['created_at'] as String),
        property: property,
      ));
    }

    _favorites = loadedFavorites;
    notifyListeners();
  }

  /// إضافة عقار إلى المفضلة مع التحديث المتفائل
  Future<bool> addToFavorites(String propertyId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _setError('المستخدم غير مسجل الدخول');
      return false;
    }

    // التحقق من عدم وجود العقار مسبقاً
    if (isFavorite(propertyId)) {
      return true;
    }

    return await performOptimisticOperation<bool>(
      operationId: 'add_favorite_$propertyId',
      optimisticUpdate: () {
        // إضافة متفائلة للواجهة
        final tempFavorite = FavoriteModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          tenantId: user.id,
          listingId: propertyId,
          createdAt: DateTime.now(),
        );
        _favorites.insert(0, tempFavorite);
      },
      serverOperation: () async {
        // التحقق من قاعدة البيانات
        final existingFavorite = await _supabase
            .from('favorites')
            .select('id')
            .eq('tenant_id', user.id)
            .eq('listing_id', propertyId)
            .maybeSingle();

        if (existingFavorite != null) {
          return true; // موجود مسبقاً
        }

        // إضافة جديدة
        final response = await _supabase
            .from('favorites')
            .insert({
              'tenant_id': user.id,
              'listing_id': propertyId,
            })
            .select()
            .single();

        // تحديث القائمة المحلية بالبيانات الحقيقية
        final realFavorite = FavoriteModel(
          id: response['id'] as String,
          tenantId: response['tenant_id'] as String,
          listingId: response['listing_id'] as String,
          createdAt: DateTime.parse(response['created_at'] as String),
        );

        // استبدال المفضلة المؤقتة بالحقيقية
        final tempIndex = _favorites.indexWhere((f) => f.listingId == propertyId && f.id.startsWith('temp_'));
        if (tempIndex != -1) {
          _favorites[tempIndex] = realFavorite;
        }

        // تحديث التخزين المؤقت
        _invalidateCache(user.id);

        return true;
      },
      rollbackUpdate: () {
        // إزالة المفضلة المؤقتة عند الفشل
        _favorites.removeWhere((f) => f.listingId == propertyId && f.id.startsWith('temp_'));
      },
      successMessage: 'تم إضافة العقار للمفضلة',
      errorMessage: 'فشل في إضافة العقار للمفضلة',
    );
  }

  /// إزالة عقار من المفضلة مع التحديث المتفائل
  Future<bool> removeFromFavorites(String propertyId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _setError('المستخدم غير مسجل الدخول');
      return false;
    }

    // حفظ نسخة من المفضلة للتراجع
    final removedFavorite = _favorites.firstWhere(
      (f) => f.listingId == propertyId,
      orElse: () => FavoriteModel(
        id: '',
        tenantId: user.id,
        listingId: propertyId,
        createdAt: DateTime.now(),
      ),
    );
    final originalIndex = _favorites.indexWhere((f) => f.listingId == propertyId);

    return await performOptimisticOperation<bool>(
      operationId: 'remove_favorite_$propertyId',
      optimisticUpdate: () {
        // إزالة متفائلة من الواجهة
        _favorites.removeWhere((fav) => fav.listingId == propertyId);
      },
      serverOperation: () async {
        await _supabase
            .from('favorites')
            .delete()
            .eq('tenant_id', user.id)
            .eq('listing_id', propertyId);

        // تحديث التخزين المؤقت
        _invalidateCache(user.id);

        return true;
      },
      rollbackUpdate: () {
        // إعادة إدراج المفضلة عند الفشل
        if (originalIndex != -1) {
          _favorites.insert(originalIndex, removedFavorite);
        } else {
          _favorites.add(removedFavorite);
        }
      },
      successMessage: 'تم إزالة العقار من المفضلة',
      errorMessage: 'فشل في إزالة العقار من المفضلة',
    );
  }

  /// تبديل حالة المفضلة (إضافة/إزالة) مع التحديث المتفائل
  Future<bool> toggleFavorite(String propertyId) async {
    if (isFavorite(propertyId)) {
      return await removeFromFavorites(propertyId);
    } else {
      return await addToFavorites(propertyId);
    }
  }

  /// مسح جميع المفضلة مع التحديث المتفائل
  Future<bool> clearAllFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _setError('المستخدم غير مسجل الدخول');
      return false;
    }

    // حفظ نسخة احتياطية للتراجع
    final backupFavorites = List<FavoriteModel>.from(_favorites);

    return await performOptimisticOperation<bool>(
      operationId: 'clear_all_favorites',
      optimisticUpdate: () {
        _favorites.clear();
      },
      serverOperation: () async {
        await _supabase.from('favorites').delete().eq('tenant_id', user.id);
        
        // تحديث التخزين المؤقت
        _invalidateCache(user.id);
        
        return true;
      },
      rollbackUpdate: () {
        _favorites = backupFavorites;
      },
      successMessage: 'تم مسح جميع المفضلة',
      errorMessage: 'فشل في مسح المفضلة',
    );
  }

  /// إعادة تعيين الحالة مع تنظيف التخزين المؤقت
  void reset() {
    _favorites.clear();
    _isLoading = false;
    _error = null;
    
    // تنظيف التخزين المؤقت
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _invalidateCache(user.id);
    }
    
    notifyListeners();
  }

  /// تنظيف المفضلة اليتيمة من قاعدة البيانات
  Future<void> _cleanupOrphanedFavorites(List<String> orphanedIds) async {
    if (orphanedIds.isEmpty) return;
    
    try {
      // حذف المفضلة اليتيمة واحدة تلو الأخرى
      for (final id in orphanedIds) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('id', id);
      }
      
      debugPrint('✅ تم تنظيف ${orphanedIds.length} مفضلة يتيمة بنجاح');
      
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف المفضلة اليتيمة: $e');
      // لا نرمي الخطأ لأن هذا تنظيف اختياري
    }
  }

  /// إلغاء صحة التخزين المؤقت
  void _invalidateCache(String userId) {
    _cacheManager.remove('${_favoritesKey}_$userId');
    _cacheManager.remove('${_favoritePropertiesKey}_$userId');
  }

  /// تحديث المفضلة في الخلفية
  Future<void> refreshInBackground() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _cacheManager.refreshInBackground(
        '${_favoritesKey}_${user.id}',
        () => _fetchAndCacheFavorites(user.id, updateUI: false),
      );
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
