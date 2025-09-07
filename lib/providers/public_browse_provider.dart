import 'package:flutter/foundation.dart';
import 'package:godarna/data/repositories/public_properties_repository.dart';
import 'package:godarna/models/public_property.dart';

class PublicBrowseProvider extends ChangeNotifier {
  final PublicPropertiesRepository _repo;
  PublicBrowseProvider({PublicPropertiesRepository? repo}) : _repo = repo ?? PublicPropertiesRepository();

  // Query params
  String? search;
  String? city;
  String? propertyType; // e.g., apartment, villa, riad, studio
  double? centerLat;
  double? centerLng;
  double? radiusKm;
  num? minPrice;
  num? maxPrice;
  int? maxGuests;
  String orderBy = 'recent';

  // State
  final List<PublicProperty> _items = [];
  bool _loading = false;
  bool _initialized = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _error;

  List<PublicProperty> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get initialized => _initialized;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> refresh() async {
    _items.clear();
    _offset = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.browse(
        search: search,
        city: city,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
        minPrice: minPrice,
        maxPrice: maxPrice,
        propertyType: propertyType,
        maxGuests: maxGuests,
        limit: _limit,
        offset: _offset,
        orderBy: orderBy,
      );
      _items.addAll(data);
      _offset += data.length;
      if (data.length < _limit) _hasMore = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  void updateQuery({
    String? search,
    String? city,
    String? propertyType,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    num? minPrice,
    num? maxPrice,
    int? maxGuests,
    String? orderBy,
  }) {
    this.search = search ?? this.search;
    this.city = city ?? this.city;
    this.propertyType = propertyType ?? this.propertyType;
    this.centerLat = centerLat ?? this.centerLat;
    this.centerLng = centerLng ?? this.centerLng;
    // إذا تم تمرير lat/lng بدون radius، عيّن قيمة افتراضية 10 كم
    if ((centerLat != null || centerLng != null) && radiusKm == null && this.radiusKm == null) {
      this.radiusKm = 10.0;
    } else {
      this.radiusKm = radiusKm ?? this.radiusKm;
    }
    this.minPrice = minPrice ?? this.minPrice;
    this.maxPrice = maxPrice ?? this.maxPrice;
    this.maxGuests = maxGuests ?? this.maxGuests;
    this.orderBy = orderBy ?? this.orderBy;
    refresh();
  }
}
