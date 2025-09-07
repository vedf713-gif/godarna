import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godarna/utils/permissions.dart';
import 'package:godarna/widgets/permission_rationale.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as gmcm;
import 'package:go_router/go_router.dart';
import 'package:godarna/widgets/skeleton.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/models/property_model.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/screens/property/property_details_screen.dart';
import 'package:godarna/widgets/filter_bottom_sheet.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/widgets/common/app_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  late gmcm.ClusterManager<_PropertyItem> _clusterManager;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  final List<_PropertyItem> _clusterItems = [];
  String? _selectedPropertyId;
  bool _locationGranted = false;
  Offset? _overlayPos;
  LatLng? _selectedLatLng;
  late final BitmapDescriptor _iconSelected;
  late final BitmapDescriptor _iconDefault;
  Timer? _moveThrottle;
  VoidCallback? _providerListener;
  PropertyProvider? _propertyProvider; // Store provider reference
  BitmapDescriptor? _brandMarker;
  BitmapDescriptor? _brandMarkerSelected;
  final Map<int, BitmapDescriptor> _clusterIconCache = {};

  // حدود المغرب
  static const LatLng _maSouthWest = LatLng(20.0, -17.5);
  static const LatLng _maNorthEast = LatLng(36.5, -0.5);
  static final LatLngBounds _moroccoBounds = LatLngBounds(
    southwest: _maSouthWest,
    northeast: _maNorthEast,
  );

  // أنماط الخريطة
  static const String _mapStyleLight =
      '[{"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]}, {"elementType":"labels.icon","stylers":[{"visibility":"off"}]}, {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]}, {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]}, {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]}, {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]}, {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]}, {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]}, {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}, {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]}, {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]}, {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]}, {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]}, {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}, {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]}, {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9d7f0"}]}, {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}]';
  static const String _mapStyleDark =
      '[{"elementType":"geometry","stylers":[{"color":"#1f1f1f"}]}, {"elementType":"labels.icon","stylers":[{"visibility":"off"}]}, {"elementType":"labels.text.fill","stylers":[{"color":"#9aa0a6"}]}, {"elementType":"labels.text.stroke","stylers":[{"color":"#1f1f1f"}]}, {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#2f2f2f"}]}, {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]}, {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263238"}]}, {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]}, {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#303134"}]}, {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c4043"}]}, {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f2f2f"}]}, {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e2433"}]}]';

  String get _currentMapStyle {
    final brightness = Theme.of(context).brightness;
    final style =
        brightness == Brightness.dark ? _mapStyleDark : _mapStyleLight;
    return style;
  }

  @override
  void initState() {
    super.initState();
    _iconSelected =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    _iconDefault =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _clusterManager = gmcm.ClusterManager<_PropertyItem>(
      _clusterItems,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      stopClusteringZoom: 16,
    );

    _loadMoroccoBoundary();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      final brand = cs.primary;
      _brandMarker = await _createCircleMarker(
          fill: brand, border: Colors.white, diameter: 48);
      _brandMarkerSelected = await _createCircleMarker(
          fill: brand, border: Colors.white, diameter: 56);
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'perm_location_requested';
      final already = prefs.getBool(key) ?? false;
      if (already) return;

      if (!mounted) return;
      final proceed = await showPermissionRationale(
        context,
        title: PermissionRationaleTexts.locationTitle(context),
        message: PermissionRationaleTexts.locationBody(context),
      );
      await prefs.setBool(key, true);
      final granted =
          proceed ? await PermissionsHelper.requestLocationPermission() : false;
      if (mounted) setState(() => _locationGranted = granted);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      if (_propertyProvider!.properties.isEmpty && !_propertyProvider!.isLoading) {
        _propertyProvider!.fetchProperties();
      } else {
        _refreshClusterItems(_propertyProvider!.filteredProperties);
      }

      _providerListener =
          () => _refreshClusterItems(_propertyProvider!.filteredProperties);
      _propertyProvider!.addListener(_providerListener!);
    });
  }

  Future<void> _loadMoroccoBoundary() async {
    try {
      final text =
          await rootBundle.loadString('assets/geo/morocco_full.geojson');
      if (kDebugMode) debugPrint('[Map] GeoJSON loaded: ${text.length} chars');
      final data = json.decode(text) as Map<String, dynamic>;
      final polygons = <Polygon>{};

      void addPolygonFromCoords(List coords, int idx) {
        final points = <LatLng>[];
        for (final c in coords) {
          if (c is List && c.length >= 2) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            points.add(LatLng(lat, lon));
          }
        }
        if (points.length >= 3 && mounted) {
          final cs = Theme.of(context).colorScheme;
          polygons.add(Polygon(
            polygonId: PolygonId('ma_$idx'),
            points: points,
            strokeWidth: 2,
            strokeColor: cs.primary,
            fillColor: cs.primary.withAlpha((0.08 * 255).round()),
            geodesic: true,
          ));
        }
      }

      if (data['type'] == 'FeatureCollection') {
        final features = data['features'] as List;
        if (kDebugMode) debugPrint('[Map] Features: ${features.length}');
        int idx = 0;
        for (final f in features) {
          final geom = f['geometry'] as Map<String, dynamic>?;
          if (geom == null) continue;
          final type = geom['type'] as String?;
          final coords = geom['coordinates'];
          if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
            addPolygonFromCoords(coords[0] as List, idx++);
          } else if (type == 'MultiPolygon' && coords is List) {
            for (final poly in coords) {
              if (poly is List && poly.isNotEmpty) {
                addPolygonFromCoords(poly[0] as List, idx++);
              }
            }
          }
        }
      }

      if (mounted) {
        if (kDebugMode) debugPrint('[Map] Polygons: ${polygons.length}');
        setState(() => _polygons = polygons);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Map] Load GeoJSON failed: $e');
    }
  }

  bool _isInMorocco(PropertyModel p) {
    return p.latitude >= _maSouthWest.latitude &&
        p.latitude <= _maNorthEast.latitude &&
        p.longitude >= _maSouthWest.longitude &&
        p.longitude <= _maNorthEast.longitude;
  }

  void _refreshClusterItems(List<PropertyModel> properties) {
    final valid = properties
        .where((p) => p.latitude != 0 && p.longitude != 0)
        .where(_isInMorocco)
        .map((p) => _PropertyItem(p))
        .toList();
    _clusterManager.setItems(valid);
  }

  Future<void> _updateMarkers(Set<Marker> markers) async {
    if (mounted) setState(() => _markers = markers);
  }

  Future<Marker> _markerBuilder(gmcm.Cluster<_PropertyItem> cluster) async {
    if (cluster.isMultiple) {
      final cs = Theme.of(context).colorScheme;
      final propertiesText = AppStrings.getString('properties', context);
      final icon =
          await _createClusterIcon(cluster.count, cs.primary, Colors.white);
      return Marker(
        markerId: MarkerId('cluster_${cluster.getId()}'),
        position: cluster.location,
        icon: icon,
        infoWindow: InfoWindow(
            title: '$propertiesText: ${cluster.count}'),
        onTap: () async {
          if (_mapController == null) return;
          final bounds = _getBoundsForItems(
              cluster.items.map((it) => it.property).toList());
          await _mapController!
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
        },
      );
    } else {
      final p = cluster.items.first.property;
      final isSelected = _selectedPropertyId == p.id;
      final icon = isSelected
          ? (_brandMarkerSelected ?? _iconSelected)
          : (_brandMarker ?? _iconDefault);
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.latitude, p.longitude),
        icon: icon,
        infoWindow: const InfoWindow(),
        onTap: () {
          setState(() {
            _selectedPropertyId = p.id;
            _selectedLatLng = LatLng(p.latitude, p.longitude);
          });
          _clusterManager.updateMap();
          _animateToProperty(p);
          _updateOverlayPosition();
        },
      );
    }
  }

  LatLngBounds _getBoundsForItems(List<PropertyModel> items) {
    double minLat = items[0].latitude, maxLat = minLat;
    double minLng = items[0].longitude, maxLng = minLng;
    for (final p in items) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    return LatLngBounds(
        southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  Future<void> _animateToProperty(PropertyModel p) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(p.latitude, p.longitude), zoom: 13),
    ));
  }

  Future<void> _fitToBounds(List<PropertyModel> properties) async {
    if (_mapController == null || properties.isEmpty) return;
    if (properties.length == 1) return _animateToProperty(properties.first);
    await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_getBoundsForItems(properties), 60));
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  Future<BitmapDescriptor> _createCircleMarker({
    required Color fill,
    required Color border,
    required double diameter,
    double borderWidth = 3,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = ui.Size(diameter, diameter);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (diameter / 2) - borderWidth;

    final paintFill = Paint()..color = fill;
    final paintBorder = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(center, radius, paintFill);
    canvas.drawCircle(center, radius, paintBorder);

    final img = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createClusterIcon(int count, Color fill, Color text,
      {double diameter = 64}) async {
    if (_clusterIconCache.containsKey(count)) return _clusterIconCache[count]!;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = ui.Size(diameter, diameter);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = diameter / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((0.18 * 255).round())
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 2), radius - 4, shadowPaint);

    final fillPaint = Paint()..color = fill;
    canvas.drawCircle(center, radius - 4, fillPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: TextStyle(
            color: text,
            fontSize: diameter * 0.42,
            fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: diameter);
    final tpOffset = Offset(
        center.dx - textPainter.width / 2, center.dy - textPainter.height / 2);
    textPainter.paint(canvas, tpOffset);

    final img = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final bd = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _clusterIconCache[count] = bd;
    return bd;
  }

  Future<void> _updateOverlayPosition() async {
    if (_mapController == null || _selectedLatLng == null || !mounted) return;
    try {
      final sc = await _mapController!.getScreenCoordinate(_selectedLatLng!);
      const cardWidth = 260.0, cardHeight = 140.0, markerTipToCard = 12.0;
      if (!mounted) return;
      final screenSize = MediaQuery.of(context).size;
      double left = sc.x.toDouble() - (cardWidth / 2);
      double top = sc.y.toDouble() - cardHeight - markerTipToCard;
      left = left.clamp(8.0, screenSize.width - cardWidth - 8.0);
      top =
          top.clamp(kToolbarHeight + 8.0, screenSize.height - cardHeight - 8.0);
      if (mounted) setState(() => _overlayPos = Offset(left, top));
    } catch (e) {
      if (kDebugMode) debugPrint('[Map] Update overlay failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppStrings.getString('propertiesMap', context),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(AppIcons.filter),
            tooltip: AppStrings.getString('filters', context),
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          final properties = provider.filteredProperties;
          final moroccoProperties = properties.where(_isInMorocco).toList();

          final initialTarget = moroccoProperties.isNotEmpty
              ? LatLng(moroccoProperties.first.latitude,
                  moroccoProperties.first.longitude)
              : const LatLng(31.7917, -7.0926);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: initialTarget, zoom: 6.5),
                style: _currentMapStyle,
                markers: _markers,
                polygons: _polygons,
                myLocationEnabled: _locationGranted,
                myLocationButtonEnabled: _locationGranted,
                zoomControlsEnabled: true,
                liteModeEnabled: false,
                cameraTargetBounds: CameraTargetBounds(_moroccoBounds),
                minMaxZoomPreference: const MinMaxZoomPreference(5.5, 20),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _clusterManager.setMapId(controller.mapId);
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;
                    await _fitToBounds(moroccoProperties);
                    if (moroccoProperties.isEmpty) {
                      await _mapController!
                          .animateCamera(CameraUpdate.newCameraPosition(
                        const CameraPosition(
                            target: LatLng(31.7917, -7.0926), zoom: 5.8),
                      ));
                    }
                  });
                },
                onCameraMove: (pos) {
                  _clusterManager.onCameraMove(pos);
                  if (_selectedLatLng == null) return;
                  _moveThrottle?.cancel();
                  _moveThrottle = Timer(
                      const Duration(milliseconds: 16), _updateOverlayPosition);
                },
                onCameraIdle: () {
                  _clusterManager.updateMap();
                  _updateOverlayPosition();
                },
              ),
              if (_selectedPropertyId != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() {
                      _selectedPropertyId = null;
                      _overlayPos = null;
                      _selectedLatLng = null;
                    }),
                  ),
                ),
              if (_selectedPropertyId != null && _overlayPos != null)
                Positioned(
                  left: _overlayPos!.dx,
                  top: _overlayPos!.dy,
                  child: _FloatingPropertyCard(
                    property: moroccoProperties.firstWhere(
                      (p) => p.id == _selectedPropertyId,
                      orElse: () => moroccoProperties.isNotEmpty
                          ? moroccoProperties.first
                          : properties.first,
                    ),
                    onClose: () => setState(() {
                      _selectedPropertyId = null;
                      _overlayPos = null;
                      _selectedLatLng = null;
                    }),
                    onBook: (p) => context.go('/booking/create', extra: p),
                    onDetails: (p) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PropertyDetailsScreen(property: p)),
                      );
                    },
                  ),
                ),
              Positioned(
                right: AppDimensions.space16,
                bottom: AppDimensions.space16,
                child: FloatingActionButton.extended(
                  heroTag: 'fitBoundsBtn',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: () => _fitToBounds(moroccoProperties),
                  icon: const Icon(Icons.fullscreen),
                  label: Text(AppStrings.getString('fitBounds', context)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _moveThrottle?.cancel();
    if (_providerListener != null && _propertyProvider != null) {
      _propertyProvider!.removeListener(_providerListener!);
    }
    super.dispose();
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

class _FloatingPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onClose;
  final void Function(PropertyModel) onBook;
  final void Function(PropertyModel) onDetails;

  const _FloatingPropertyCard(
      {required this.property,
      required this.onClose,
      required this.onBook,
      required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 260,
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: AppDimensions.borderRadiusLarge,
              border:
                  Border.all(color: cs.primary.withAlpha((0.12 * 255).round())),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha((0.2 * 255).round()),
                    blurRadius: 18,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusLarge),
                        bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                      ),
                      child: _image(context),
                    ),
                    Expanded(
                      child: Padding(
                        padding: AppDimensions.paddingAll10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    property.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                InkWell(
                                  onTap: onClose,
                                  child: const Padding(
                                    padding: AppDimensions.paddingAll2,
                                    child: Icon(Icons.close, size: 18),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space2),
                            Text(
                              property.locationDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: cs.onSurface
                                          .withAlpha((0.7 * 255).round())),
                            ),
                            const SizedBox(height: AppDimensions.space6),
                            Wrap(
                              spacing: AppDimensions.space6,
                              runSpacing: AppDimensions.space4,
                              children: [
                                _chip(context, Icons.king_bed,
                                    '${property.bedrooms} غرف'),
                                _chip(context, Icons.bathtub,
                                    '${property.bathrooms} حمام'),
                                _chip(context, Icons.people,
                                    '${property.maxGuests} ضيوف'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppDimensions.space1),
                Padding(
                  padding: AppDimensions.paddingSymmetric10x8,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'احجز الآن',
                          onPressed: () => onBook(property),
                          type: AppButtonType.primary,
                          size: AppButtonSize.medium,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: AppButton(
                          text: 'التفاصيل',
                          onPressed: () => onDetails(property),
                          type: AppButtonType.secondary,
                          size: AppButtonSize.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -6,
            left: 123,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(
                      color: cs.primary.withAlpha((0.12 * 255).round())),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(BuildContext context) {
    const double width = 92, height = 68;
    if (property.mainPhoto != null && property.mainPhoto!.isNotEmpty) {
      return Image.network(
        property.mainPhoto!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: 184,
        cacheHeight: 136,
        loadingBuilder: (context, child, loadingProgress) =>
            const Skeleton.rect(width: width, height: height, radius: 12),
        errorBuilder: (_, __, ___) =>
            const Skeleton.rect(width: width, height: height, radius: 12),
      );
    }
    return const Skeleton.rect(width: width, height: height, radius: 12);
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppDimensions.paddingSymmetric8x4,
      decoration: BoxDecoration(
        color: cs.primary.withAlpha((0.6 * 255).round()),
        borderRadius: AppDimensions.borderRadiusMedium,
        border: Border.all(color: cs.primary.withAlpha((0.12 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: AppDimensions.space4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha((0.8 * 255).round()),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
