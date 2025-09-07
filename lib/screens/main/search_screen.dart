import 'package:flutter/material.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/widgets/search_bar_widget.dart';
import 'package:godarna/widgets/filter_bottom_sheet.dart';
import 'package:godarna/screens/property/property_details_screen.dart';
import 'package:godarna/widgets/property_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godarna/models/property_model.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as gmcm;
import 'package:go_router/go_router.dart';
import 'package:godarna/widgets/skeleton.dart';
import 'package:godarna/widgets/empty_state.dart';
import 'package:godarna/data/morocco_regions_cities.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with RealtimeMixin {
  String _searchQuery = '';
  bool _showMap = false;
  GoogleMapController? _mapController;
  String? _selectedPropertyId;
  late gmcm.ClusterManager<_PropertyItem> _clusterManager;
  Set<Marker> _markers = {};
  List<_PropertyItem> _clusterItems = [];
  Timer? _debounce;

  // Grouped property types for filter
  static const Map<String, List<String>> _typeGroups = {
    '🏘️ الإقامات العصرية': ['apartment', 'studio', 'villa'],
    '🏡 الإقامات التقليدية': ['riad', 'kasbah', 'village_house'],
    '🏕️ الإقامات البديلة': ['desert_camp', 'eco_lodge', 'guesthouse'],
    '🏨 الإقامات السياحية': ['hotel', 'resort'],
  };

  String _typeLabelAr(String type) {
    switch (type) {
      case 'apartment':
        return 'شقق';
      case 'studio':
        return 'ستوديوهات';
      case 'villa':
        return 'فيلات';
      case 'riad':
        return 'رياض';
      case 'kasbah':
        return 'قصور/قصبات';
      case 'village_house':
        return 'منازل قروية';
      case 'desert_camp':
        return 'خيام صحراوية';
      case 'eco_lodge':
        return 'نزل بيئية';
      case 'guesthouse':
        return 'بيوت ضيافة';
      case 'hotel':
        return 'فنادق';
      case 'resort':
        return 'منتجعات';
      default:
        return type;
    }
  }

  @override
  void initState() {
    super.initState();
    _clusterManager = gmcm.ClusterManager<_PropertyItem>(
      _clusterItems,
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      propertyProvider.fetchProperties();
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    // تم تعطيل اشتراكات Realtime لتحسين الأداء
    // يمكن إعادة تفعيلها حسب الحاجة
  }

  String _sortLabel(String sortBy) {
    switch (sortBy) {
      case 'price_asc':
        return 'السعر: تصاعدي';
      case 'price_desc':
        return 'السعر: تنازلي';
      case 'rating_desc':
        return 'الأفضل تقييماً';
      default:
        return 'بدون ترتيب';
    }
  }

  List<Widget> _buildActiveFilterChips(PropertyProvider p) {
    final List<Widget> chips = [];

    if (p.selectedRegion.isNotEmpty) {
      chips.add(Chip(
        label: Text('الجهة: ${p.selectedRegion}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setSelectedRegion(''),
      ));
    }

    if (p.selectedCity.isNotEmpty) {
      chips.add(Chip(
        label: Text('المدينة: ${p.selectedCity}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setSelectedCity(''),
      ));
    }

    if (p.selectedPropertyType.isNotEmpty) {
      chips.add(Chip(
        label: Text('النوع: ${_typeLabelAr(p.selectedPropertyType)}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setSelectedPropertyType(''),
      ));
    }

    final pr = p.priceRange;
    final minBound = pr['min'] ?? 0;
    final maxBound = pr['max'] ?? 10000;
    if (p.minPrice > minBound || p.maxPrice < maxBound) {
      chips.add(Chip(
        label: Text('السعر: ${p.minPrice.round()} - ${p.maxPrice.round()}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setPriceRange(minBound, maxBound),
      ));
    }

    if (p.selectedGuests > 1) {
      chips.add(Chip(
        label: Text('الضيوف: ${p.selectedGuests}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setSelectedGuests(1),
      ));
    }

    if (p.checkInDate != null && p.checkOutDate != null) {
      chips.add(Chip(
        label: Text(
            'التواريخ: ${p.checkInDate!.toString().split(' ').first} → ${p.checkOutDate!.toString().split(' ').first}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setDateRange(null, null),
      ));
    }

    if (p.selectedAmenities.isNotEmpty) {
      chips.add(Chip(
        label: Text('المرافق: ${p.selectedAmenities.length}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setSelectedAmenities([]),
      ));
    }

    if (p.sortBy != 'none') {
      chips.add(Chip(
        label: Text('الترتيب: ${_sortLabel(p.sortBy)}'),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => p.setSortBy('none'),
      ));
    }

    return chips;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unsubscribeAll();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Provider.of<PropertyProvider>(context, listen: false)
          .setSearchQuery(query);
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44); // Airbnb Red

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        tooltip: 'افتح الخريطة',
        backgroundColor: primaryColor,
        onPressed: () => context.go('/map'),
        child: const Icon(Icons.map, color: Colors.white),
      ),
      body: Column(
        children: [
          // === 1. Search Bar ===
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBarWidget(
              onSearch: _onSearch,
              onFilterTap: _showFilterBottomSheet,
              initialQuery: _searchQuery,
            ),
          ),

          // === 2. Region & City Filters ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<PropertyProvider>(
              builder: (context, p, _) {
                final selectedRegion =
                    p.selectedRegion.isEmpty ? null : p.selectedRegion;
                final cities = MoroccoRegionsCities.citiesFor(selectedRegion);
                return Column(
                  children: [
                    _dropdown(
                        'الجهة', selectedRegion, MoroccoRegionsCities.regions,
                        (value) {
                      p.setSelectedRegion(value ?? '');
                      p.setSelectedCity('');
                    }),
                    const SizedBox(height: 12),
                    _dropdown(
                        'المدينة',
                        p.selectedCity.isEmpty ? null : p.selectedCity,
                        cities, (value) {
                      if (value != null) p.setSelectedCity(value);
                    }),
                  ],
                );
              },
            ),
          ),

          // === 3. Property Type Chips ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<PropertyProvider>(
              builder: (context, p, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _typeGroups.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((t) {
                              final selected = p.selectedPropertyType == t;
                              return FilterChip(
                                label: Text(_typeLabelAr(t)),
                                selected: selected,
                                selectedColor:
                                    primaryColor.withAlpha((0.1 * 255).round()),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                    color: selected
                                        ? primaryColor
                                        : Colors.grey[700]),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                      color: selected
                                          ? primaryColor
                                          : Colors.grey[300]!,
                                      width: 1),
                                ),
                                onSelected: (val) {
                                  p.setSelectedPropertyType(val ? t : '');
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // === 4. Toggle View & Active Filters ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ToggleButtons(
                    isSelected: [_showMap == false, _showMap == true],
                    onPressed: (index) {
                      setState(() {
                        _showMap = index == 1;
                      });
                      if (_showMap) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final provider = Provider.of<PropertyProvider>(
                              context,
                              listen: false);
                          _fitToBounds(provider.filteredProperties);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    fillColor: primaryColor.withAlpha((0.1 * 255).round()),
                    selectedColor: primaryColor,
                    borderColor: Colors.grey[300],
                    selectedBorderColor: primaryColor,
                    children: const [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.list, size: 18),
                            SizedBox(width: 4),
                            Text('قائمة'),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.map, size: 18),
                            SizedBox(width: 4),
                            Text('خريطة'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: () => context.go('/map'),
                ),
              ],
            ),
          ),

          // === 5. Active Filters Chips ===
          Consumer<PropertyProvider>(
            builder: (context, p, _) {
              final chips = _buildActiveFilterChips(p);
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(spacing: 8, runSpacing: 8, children: chips),
              );
            },
          ),

          // === 6. Results ===
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                if (propertyProvider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonList(itemCount: 4, itemHeight: 140),
                  );
                }

                final properties = propertyProvider.filteredProperties;

                if (properties.isEmpty) {
                  return EmptyState(
                    title: _searchQuery.isEmpty
                        ? 'لا توجد عقارات'
                        : 'لا توجد نتائج',
                    message: _searchQuery.isNotEmpty ? _searchQuery : null,
                    icon: Icons.search_off,
                  );
                }

                return _showMap
                    ? _buildMap(properties)
                    : _buildList(properties);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF3A44), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      items:
          items.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildList(List<PropertyModel> properties) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onLongPress: () => _showOnMap(property),
            child: PropertyCardCompact(
              property: property,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsScreen(property: property),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap(List<PropertyModel> properties) {
    final valid =
        properties.where((p) => p.latitude != 0 && p.longitude != 0).toList();
    _clusterItems = valid.map((p) => _PropertyItem(p)).toList();
    _clusterManager.setItems(_clusterItems);

    final initialTarget = valid.isNotEmpty
        ? LatLng(valid.first.latitude, valid.first.longitude)
        : const LatLng(31.7917, -7.0926);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: initialTarget, zoom: 6.5),
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          mapToolbarEnabled: false,
          compassEnabled: true,
          cameraTargetBounds: CameraTargetBounds(
            LatLngBounds(
              southwest: const LatLng(27.0, -13.5),
              northeast: const LatLng(36.0, -0.9),
            ),
          ),
          minMaxZoomPreference: const MinMaxZoomPreference(5.5, 20),
          onMapCreated: (controller) {
            _mapController = controller;
            try {
              _clusterManager.setMapId(controller.mapId);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _mapController != null) {
                  _fitToBounds(valid);
                }
              });
            } catch (e) {
              debugPrint('خطأ في تهيئة الخريطة: $e');
            }
          },
          onCameraMove: (position) {
            try {
              _clusterManager.onCameraMove(position);
            } catch (e) {
              debugPrint('خطأ في تحريك الكاميرا: $e');
            }
          },
          onCameraIdle: () {
            try {
              if (mounted && _mapController != null) {
                _clusterManager.updateMap();
              }
            } catch (e) {
              debugPrint('خطأ في تحديث الخريطة: $e');
            }
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            elevation: 4,
            onPressed: () => _fitToBounds(valid),
            child: const Icon(Icons.fullscreen, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Future<void> _animateToProperty(PropertyModel p) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(p.latitude, p.longitude), zoom: 13),
      ),
    );
  }

  Future<void> _fitToBounds(List<PropertyModel> properties) async {
    if (_mapController == null || properties.isEmpty || !mounted) return;

    try {
      if (properties.length == 1) {
        await _animateToProperty(properties.first);
        return;
      }

      double minLat = properties.first.latitude;
      double maxLat = properties.first.latitude;
      double minLng = properties.first.longitude;
      double maxLng = properties.first.longitude;

      for (final p in properties) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      final update = CameraUpdate.newLatLngBounds(bounds, 60);
      if (mounted && _mapController != null) {
        await _mapController!.animateCamera(update);
      }
    } catch (e) {
      debugPrint('خطأ في تحديد حدود الخريطة: $e');
    }
  }

  void _showOnMap(PropertyModel p) {
    setState(() {
      _showMap = true;
      _selectedPropertyId = p.id;
    });
    _clusterManager.updateMap();
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateToProperty(p));
  }

  void _showPropertyCard(PropertyModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property images
                    if (property.photos.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(property.photos.first),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Property title
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.locationDisplay,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price and details
                    Row(
                      children: [
                        Text(
                          '${property.pricePerNight.toStringAsFixed(0)} درهم',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF3A44),
                          ),
                        ),
                        const Text(' / ليلة'),
                        const Spacer(),
                        if (property.rating > 0) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(property.rating.toStringAsFixed(1)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Property details
                    Row(
                      children: [
                        _buildDetailChip(Icons.bed, '${property.bedrooms} غرف'),
                        const SizedBox(width: 8),
                        _buildDetailChip(
                            Icons.bathroom, '${property.bathrooms} حمام'),
                        const SizedBox(width: 8),
                        _buildDetailChip(
                            Icons.people, '${property.maxGuests} ضيوف'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    if (property.description.isNotEmpty) ...[
                      const Text(
                        'الوصف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailsScreen(property: property),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3A44),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'عرض التفاصيل',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMarkers(Set<Marker> markers) async {
    setState(() {
      _markers = markers;
    });
  }

  Future<Marker> _markerBuilder(gmcm.Cluster<_PropertyItem> cluster) async {
    if (cluster.isMultiple) {
      return Marker(
        markerId: MarkerId('cluster_${cluster.getId()}'),
        position: cluster.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(title: 'عدد العقارات: ${cluster.count}'),
        onTap: () async {
          if (_mapController != null) {
            final currentZoom = await _mapController!.getZoomLevel();
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: cluster.location, zoom: currentZoom + 2),
              ),
            );
          }
        },
      );
    } else {
      final p = cluster.items.first.property;
      final hue = _selectedPropertyId == p.id
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueAzure;
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.latitude, p.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: p.title,
          snippet: p.locationDisplay,
        ),
        consumeTapEvents: true,
        onTap: () {
          setState(() {
            _selectedPropertyId = p.id;
          });
          _clusterManager.updateMap();
          _animateToProperty(p);

          // عرض بطاقة العقار عند النقر
          _showPropertyCard(p);
        },
      );
    }
  }
}

class _PropertyItem implements gmcm.ClusterItem {
  final PropertyModel property;
  _PropertyItem(this.property);

  @override
  LatLng get location => LatLng(property.latitude, property.longitude);

  @override
  String get geohash => gmcm.Geohash.encode(
      latLng: location, codeLength: gmcm.ClusterManager.precision);
}
