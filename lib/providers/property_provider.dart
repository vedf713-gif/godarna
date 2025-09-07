import 'package:flutter/material.dart';
import 'package:godarna/models/property_model.dart';
import 'package:godarna/services/property_service.dart';
import 'package:godarna/services/booking_service.dart';
import 'package:godarna/utils/cache_manager.dart';
import 'package:godarna/utils/optimistic_ui_manager.dart';
import 'package:godarna/utils/realtime_sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

/// مزود العقارات - إدارة العمليات المتعلقة بالعقارات
class PropertyProvider with ChangeNotifier, OptimisticOperationsMixin, RealtimeSyncMixin {
  final PropertyService _propertyService = PropertyService.instance;
  final BookingService _bookingService = BookingService.instance;
  final CacheManager _cacheManager = CacheManager.instance;

  List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];
  List<PropertyModel> _myProperties = [];
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  String? _error;
  
  RealtimeChannel? _realtimeChannel;

  /// تهيئة المزود مع المزامنة الفورية
  void initializeRealtime() {
    startRealtimeSync(RealtimeEventType.properties, onEvent: (event) {
      debugPrint('🔄 تحديث فوري للعقارات: ${event.action}');
      if (event.action == RealtimeAction.insert ||
          event.action == RealtimeAction.delete ||
          event.action == RealtimeAction.update) {
        // إعادة جلب العقارات من الخادم
        fetchProperties(forceRefresh: true);
      }
    });

    // إضافة اشتراك Realtime مباشر
    _realtimeChannel = _propertyService.subscribeToProperties(
      onInsert: (data) {
        dev.log('🏠 [Property] New property added: ${data['id']}');
        final newProperty = PropertyModel.fromJson(data);
        _properties.add(newProperty);
        _applyFilters();
        notifyListeners();
      },
      onUpdate: (data) {
        dev.log('🏠 [Property] Property updated: ${data['id']}');
        final updatedProperty = PropertyModel.fromJson(data);
        final index = _properties.indexWhere((p) => p.id == updatedProperty.id);
        if (index != -1) {
          _properties[index] = updatedProperty;
          _applyFilters();
          notifyListeners();
        }
      },
      onDelete: (data) {
        dev.log('🏠 [Property] Property deleted: ${data['id']}');
        _properties.removeWhere((p) => p.id == data['id']);
        _applyFilters();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
  
  // مفاتيح التخزين المؤقت
  static const String _propertiesKey = 'cache_properties';
  static const String _myPropertiesKey = 'cache_my_properties';

  // Search and filter state
  String _searchQuery = '';
  String _selectedRegion = '';
  String _selectedCity = '';
  String _selectedPropertyType = '';
  double _minPrice = 0;
  double _maxPrice = 10000;
  int _selectedGuests = 1;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  // Advanced filters
  List<String> _selectedAmenities = [];
  String _sortBy =
      'none'; // 'none' | 'price_asc' | 'price_desc' | 'rating_desc'
  // Cache of unavailable property IDs for the selected date range
  Set<String> _unavailableForDates = {};

  // Getters
  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get filteredProperties => _filteredProperties;
  List<PropertyModel> get myProperties => _myProperties;
  PropertyModel? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Search and filter getters
  String get searchQuery => _searchQuery;
  String get selectedRegion => _selectedRegion;
  String get selectedCity => _selectedCity;
  String get selectedPropertyType => _selectedPropertyType;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  int get selectedGuests => _selectedGuests;
  DateTime? get checkInDate => _checkInDate;
  DateTime? get checkOutDate => _checkOutDate;
  List<String> get selectedAmenities => _selectedAmenities;
  String get sortBy => _sortBy;

  // Initialize properties
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await fetchProperties();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all properties with caching
  Future<void> fetchProperties({bool forceRefresh = false}) async {
    try {
      // جلب من التخزين المؤقت أولاً
      if (!forceRefresh) {
        final cachedProperties = await _cacheManager.get<List<dynamic>>(_propertiesKey);
        if (cachedProperties != null) {
          _properties = cachedProperties.map((data) => PropertyModel.fromJson(data)).toList();
          await _refreshUnavailableForDateRange();
          _resetPriceRangeToDataIfDefault();
          _applyFilters();
          // تحديث في الخلفية
          _fetchAndCacheProperties(updateUI: false);
          return;
        }
      }
      
      _setLoading(true);
      _clearError();
      await _fetchAndCacheProperties();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// جلب وحفظ العقارات في التخزين المؤقت
  Future<void> _fetchAndCacheProperties({bool updateUI = true}) async {
    final properties = await _propertyService.getProperties();
    
    // حفظ في التخزين المؤقت
    await _cacheManager.set(
      _propertiesKey,
      properties.map((p) => p.toJson()).toList(),
      duration: CacheManager.longCacheDuration,
    );
    
    if (updateUI) {
      _properties = properties;
      await _refreshUnavailableForDateRange();
      _resetPriceRangeToDataIfDefault();
      _applyFilters();
    }
  }

  // Fetch properties by host
  Future<void> fetchPropertiesByHost(String hostId) async {
    try {
      _setLoading(true);
      _clearError();

      final properties = await _propertyService.getPropertiesByHost(hostId);
      _properties = properties;
      await _refreshUnavailableForDateRange();
      _resetPriceRangeToDataIfDefault();
      _applyFilters();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Fetch my properties (for current host) with caching
  Future<void> fetchMyProperties(String hostId, {bool forceRefresh = false}) async {
    try {
      final cacheKey = '${_myPropertiesKey}_$hostId';
      
      // جلب من التخزين المؤقت أولاً
      if (!forceRefresh) {
        final cachedProperties = await _cacheManager.get<List<dynamic>>(cacheKey);
        if (cachedProperties != null) {
          _myProperties = cachedProperties.map((data) => PropertyModel.fromJson(data)).toList();
          notifyListeners();
          // تحديث في الخلفية
          _fetchAndCacheMyProperties(hostId, updateUI: false);
          return;
        }
      }
      
      _setLoading(true);
      _clearError();
      await _fetchAndCacheMyProperties(hostId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// جلب وحفظ عقاراتي في التخزين المؤقت
  Future<void> _fetchAndCacheMyProperties(String hostId, {bool updateUI = true}) async {
    final properties = await _propertyService.getPropertiesByHost(hostId);
    final cacheKey = '${_myPropertiesKey}_$hostId';
    
    // حفظ في التخزين المؤقت
    await _cacheManager.set(
      cacheKey,
      properties.map((p) => p.toJson()).toList(),
      duration: CacheManager.defaultCacheDuration,
    );
    
    if (updateUI) {
      _myProperties = properties;
      notifyListeners();
    }
  }

  // Get property by ID
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      _setLoading(true);
      _clearError();

      final property = await _propertyService.getPropertyById(propertyId);
      _selectedProperty = property;
      return property;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Add new property with optimistic updates
  Future<bool> addProperty(PropertyModel property) async {
    final tempProperty = property.copyWith(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await performOptimisticOperation<bool>(
      operationId: 'add_property_${tempProperty.id}',
      optimisticUpdate: () {
        _properties.add(tempProperty);
        _myProperties.add(tempProperty);
        _applyFilters();
      },
      serverOperation: () async {
        final newProperty = await _propertyService.addProperty(property);
        if (newProperty != null) {
          // استبدال العقار المؤقت بالحقيقي
          final tempIndex = _properties.indexWhere((p) => p.id == tempProperty.id);
          if (tempIndex != -1) {
            _properties[tempIndex] = newProperty;
          }
          
          final myTempIndex = _myProperties.indexWhere((p) => p.id == tempProperty.id);
          if (myTempIndex != -1) {
            _myProperties[myTempIndex] = newProperty;
          }
          
          _applyFilters();
          
          // تحديث التخزين المؤقت
          _invalidatePropertyCaches(property.hostId);
          
          return true;
        }
        return false;
      },
      rollbackUpdate: () {
        _properties.removeWhere((p) => p.id == tempProperty.id);
        _myProperties.removeWhere((p) => p.id == tempProperty.id);
        _applyFilters();
      },
      successMessage: 'تم إضافة العقار بنجاح',
      errorMessage: 'فشل في إضافة العقار',
    );
  }

  // Add new property and return it (with generated id)
  Future<PropertyModel?> addPropertyAndGet(PropertyModel property) async {
    try {
      _setLoading(true);
      _clearError();

      final newProperty = await _propertyService.addProperty(property);
      if (newProperty != null) {
        _properties.add(newProperty);
        _applyFilters();
        notifyListeners();
      }
      return newProperty;
    } catch (e) {
      final errorMessage = 'خطأ في إضافة العقار: $e';
      _setError(errorMessage);
      // Re-throw the error so the UI can handle it properly
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Update property with optimistic updates
  Future<bool> updateProperty(PropertyModel property) async {
    // حفظ النسخة الأصلية للتراجع
    final originalProperty = _properties.firstWhere(
      (p) => p.id == property.id,
      orElse: () => property,
    );

    return await performOptimisticOperation<bool>(
      operationId: 'update_property_${property.id}',
      optimisticUpdate: () {
        final index = _properties.indexWhere((p) => p.id == property.id);
        if (index != -1) {
          _properties[index] = property.copyWith(updatedAt: DateTime.now());
        }
        
        final myIndex = _myProperties.indexWhere((p) => p.id == property.id);
        if (myIndex != -1) {
          _myProperties[myIndex] = property.copyWith(updatedAt: DateTime.now());
        }
        
        _applyFilters();
      },
      serverOperation: () async {
        final updatedProperty = await _propertyService.updateProperty(property);
        if (updatedProperty != null) {
          final index = _properties.indexWhere((p) => p.id == property.id);
          if (index != -1) {
            _properties[index] = updatedProperty;
          }
          
          final myIndex = _myProperties.indexWhere((p) => p.id == property.id);
          if (myIndex != -1) {
            _myProperties[myIndex] = updatedProperty;
          }
          
          _applyFilters();
          
          // تحديث التخزين المؤقت
          _invalidatePropertyCaches(property.hostId);
          
          return true;
        }
        return false;
      },
      rollbackUpdate: () {
        final index = _properties.indexWhere((p) => p.id == property.id);
        if (index != -1) {
          _properties[index] = originalProperty;
        }
        
        final myIndex = _myProperties.indexWhere((p) => p.id == property.id);
        if (myIndex != -1) {
          _myProperties[myIndex] = originalProperty;
        }
        
        _applyFilters();
      },
      successMessage: 'تم تحديث العقار بنجاح',
      errorMessage: 'فشل في تحديث العقار',
    );
  }

  // Delete property with optimistic updates
  Future<bool> deleteProperty(String propertyId) async {
    // حفظ العقار المحذوف للتراجع
    final deletedProperty = _properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => PropertyModel(
        id: propertyId,
        title: '',
        description: '',
        pricePerNight: 0,
        pricePerMonth: 0,
        propertyType: '',
        address: '',
        region: '',
        city: '',
        area: '',
        bedrooms: 0,
        bathrooms: 0,
        maxGuests: 0,
        photos: [],
        amenities: [],
        hostId: '',
        isAvailable: false,
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final originalIndex = _properties.indexWhere((p) => p.id == propertyId);
    final myOriginalIndex = _myProperties.indexWhere((p) => p.id == propertyId);

    return await performOptimisticOperation<bool>(
      operationId: 'delete_property_$propertyId',
      optimisticUpdate: () {
        _properties.removeWhere((p) => p.id == propertyId);
        _myProperties.removeWhere((p) => p.id == propertyId);
        _applyFilters();
      },
      serverOperation: () async {
        final success = await _propertyService.deleteProperty(propertyId);
        if (success) {
          // تحديث التخزين المؤقت
          _invalidatePropertyCaches(deletedProperty.hostId);
        }
        return success;
      },
      rollbackUpdate: () {
        if (originalIndex != -1) {
          _properties.insert(originalIndex, deletedProperty);
        } else {
          _properties.add(deletedProperty);
        }
        
        if (myOriginalIndex != -1) {
          _myProperties.insert(myOriginalIndex, deletedProperty);
        } else {
          _myProperties.add(deletedProperty);
        }
        
        _applyFilters();
      },
      successMessage: 'تم حذف العقار بنجاح',
      errorMessage: 'فشل في حذف العقار',
    );
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedCity(String city) {
    _selectedCity = city;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedRegion(String region) {
    _selectedRegion = region;
    // عند تغيير الجهة، إذا كانت المدينة الحالية لا تنتمي لها، صفّر المدينة
    if (_selectedCity.isNotEmpty) {
      // لا يمكننا الوصول إلى MoroccoRegionsCities هنا لتحديد الانتماء؛
      // نعتمد على أن UI سيعيد ضبط المدينة عند تغيير الجهة.
    }
    _applyFilters();
    notifyListeners();
  }

  void setSelectedPropertyType(String propertyType) {
    _selectedPropertyType = propertyType;
    _applyFilters();
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedGuests(int guests) {
    _selectedGuests = guests;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTime? checkIn, DateTime? checkOut) {
    _checkInDate = checkIn;
    _checkOutDate = checkOut;
    _refreshUnavailableForDateRange().then((_) {
      _applyFilters();
      notifyListeners();
    });
  }

  void setSelectedAmenities(List<String> amenities) {
    _selectedAmenities = amenities;
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedRegion = '';
    _selectedCity = '';
    _selectedPropertyType = '';
    // Reset price range dynamically to current data
    final range = priceRange;
    _minPrice = range['min'] ?? 0;
    _maxPrice = range['max'] ?? 10000;
    _selectedGuests = 1;
    _checkInDate = null;
    _checkOutDate = null;
    _selectedAmenities = [];
    _sortBy = 'none';
    _applyFilters();
    notifyListeners();
  }

  // Apply filters to properties
  void _applyFilters() {
    _filteredProperties = _properties.where((property) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!property.title.toLowerCase().contains(query) &&
            !property.description.toLowerCase().contains(query) &&
            !property.city.toLowerCase().contains(query) &&
            !property.area.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Region filter
      if (_selectedRegion.isNotEmpty && property.region != _selectedRegion) {
        return false;
      }

      // City filter
      if (_selectedCity.isNotEmpty && property.city != _selectedCity) {
        return false;
      }

      // Property type filter
      if (_selectedPropertyType.isNotEmpty &&
          property.propertyType != _selectedPropertyType) {
        return false;
      }

      // Price filter
      if (property.pricePerNight < _minPrice ||
          property.pricePerNight > _maxPrice) {
        return false;
      }

      // Guests filter
      if (property.maxGuests < _selectedGuests) {
        return false;
      }

      // Amenities filter: require all selected amenities to be present
      if (_selectedAmenities.isNotEmpty) {
        final amenitySet = property.amenities.toSet();
        for (final a in _selectedAmenities) {
          if (!amenitySet.contains(a)) return false;
        }
      }

      // Availability filter
      if (!property.isAvailable) {
        return false;
      }
      if (_checkInDate != null && _checkOutDate != null) {
        // Exclude properties known to be unavailable for the selected dates
        if (_unavailableForDates.contains(property.id)) return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'price_asc':
        _filteredProperties
            .sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        break;
      case 'price_desc':
        _filteredProperties
            .sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        break;
      case 'rating_desc':
        _filteredProperties.sort((a, b) {
          final r = b.rating.compareTo(a.rating);
          if (r != 0) return r;
          return b.reviewCount.compareTo(a.reviewCount);
        });
        break;
      case 'none':
      default:
        // keep original order
        break;
    }

    notifyListeners();
  }

  // Refresh the cached set of unavailable property IDs for current date range
  Future<void> _refreshUnavailableForDateRange() async {
    try {
      if (_checkInDate == null || _checkOutDate == null) {
        _unavailableForDates = {};
        return;
      }
      // Scope query to current properties to reduce network and latency
      final ids = _properties.map((p) => p.id).toList();
      final set = await _bookingService.getUnavailablePropertyIds(
        checkIn: _checkInDate!,
        checkOut: _checkOutDate!,
        propertyIds: ids,
      );
      _unavailableForDates = set;
    } catch (_) {
      // On error, keep previous cache; do not block filters
    }
  }

  // Get available cities
  List<String> get availableCities {
    final cities = _properties.map((p) => p.city).toSet().toList();
    cities.sort();
    return cities;
  }

  // Get available property types
  List<String> get availablePropertyTypes {
    return [
      'apartment',
      'villa',
      'riad',
      'studio',
      'kasbah',
      'village_house',
      'desert_camp',
      'eco_lodge',
      'guesthouse',
      'hotel',
      'resort',
    ];
  }

  // Get available amenities from loaded properties
  List<String> get availableAmenities {
    final set = <String>{};
    for (final p in _properties) {
      set.addAll(p.amenities);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  // Get price range
  Map<String, double> get priceRange {
    if (_properties.isEmpty) {
      return {'min': 0, 'max': 10000};
    }

    final prices = _properties.map((p) => p.pricePerNight).toList();
    return {
      'min': prices.reduce((a, b) => a < b ? a : b),
      'max': prices.reduce((a, b) => a > b ? a : b),
    };
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

  // If price range is still at defaults, align it with current data
  void _resetPriceRangeToDataIfDefault() {
    final isDefaultRange = _minPrice == 0 && _maxPrice == 10000;
    if (isDefaultRange) {
      final range = priceRange;
      _minPrice = range['min'] ?? 0;
      _maxPrice = range['max'] ?? 10000;
    }
  }
  
  /// إلغاء صحة التخزين المؤقت للعقارات
  void _invalidatePropertyCaches(String hostId) {
    _cacheManager.remove(_propertiesKey);
    _cacheManager.remove('${_myPropertiesKey}_$hostId');
  }
  
  /// تحديث العقارات في الخلفية
  Future<void> refreshInBackground({String? hostId}) async {
    await _cacheManager.refreshInBackground(
      _propertiesKey,
      () => _fetchAndCacheProperties(updateUI: false),
    );
    
    if (hostId != null) {
      await _cacheManager.refreshInBackground(
        '${_myPropertiesKey}_$hostId',
        () => _fetchAndCacheMyProperties(hostId, updateUI: false),
      );
    }
  }
}
