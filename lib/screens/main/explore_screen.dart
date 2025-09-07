import 'package:flutter/material.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:godarna/providers/public_browse_provider.dart';
import 'package:godarna/widgets/public_property_card.dart';
import 'package:godarna/widgets/public_property_card_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:godarna/widgets/public_filter_bottom_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _GeoQuickActions extends StatefulWidget {
  const _GeoQuickActions();

  @override
  State<_GeoQuickActions> createState() => _GeoQuickActionsState();
}

class _GeoQuickActionsState extends State<_GeoQuickActions> {
  bool _busy = false;

  Future<void> _useMyLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء تفعيل خدمة الموقع')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('صلاحية الموقع غير متاحة')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      final prov = context.read<PublicBrowseProvider>();
      final double radius = prov.radiusKm ?? 10.0;
      prov.updateQuery(
          centerLat: pos.latitude, centerLng: pos.longitude, radiusKm: radius);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر الحصول على الموقع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearLocation() {
    final prov = context.read<PublicBrowseProvider>();
    prov.updateQuery(centerLat: null, centerLng: null, radiusKm: null);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _useMyLocation,
            icon: _busy ? Container() : const Icon(Icons.location_on, size: 18),
            label: Text(_busy ? '...جاري تحديد الموقع' : 'ابحث بالقرب مني'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3A44),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _clearLocation,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('إزالة'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[400]!),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _ExploreScreenState extends State<ExploreScreen> with RealtimeMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _setupRealtimeSubscriptions();
    _scrollController.addListener(_onScroll);
  }

  void _setupRealtimeSubscriptions() {
    // اشتراك في تحديثات العقارات العامة
    subscribeToTable(
      table: 'properties',
      filter: null, // جميع العقارات العامة
      filterValue: null,
      onInsert: (payload) {
        if (mounted) {
          final provider = context.read<PublicBrowseProvider>();
          provider.refresh();
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final provider = context.read<PublicBrowseProvider>();
          provider.refresh();
        }
      },
      onDelete: (payload) {
        if (mounted) {
          final provider = context.read<PublicBrowseProvider>();
          provider.refresh();
        }
      },
    );
  }

  void _onScroll() {
    final prov = context.read<PublicBrowseProvider>();
    if (!prov.loading &&
        prov.hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      prov.loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    unsubscribeAll();
    super.dispose();
  }

  void _loadProperties() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<PublicBrowseProvider>();
        provider.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44); // Airbnb Red

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppAppBar(
        title: 'استكشف العقارات',
        centerTitle: true,
      ),
      body: Consumer<PublicBrowseProvider>(
        builder: (context, prov, _) {
          return RefreshIndicator(
            color: primaryColor,
            onRefresh: prov.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // === 1. Search & Filters ===
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.05 * 255).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن مدينة أو عنوان',
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              _debounce?.cancel();
                              _debounce =
                                  Timer(const Duration(milliseconds: 400), () {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  final prov =
                                      context.read<PublicBrowseProvider>();
                                  prov.updateQuery(
                                      search: value.isEmpty ? null : value);
                                });
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Filter & Sort Row
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await showModalBottomSheet<
                                      Map<String, dynamic>>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (ctx) =>
                                        const PublicFilterBottomSheet(),
                                  );
                                  if (result != null && context.mounted) {
                                    final prov =
                                        context.read<PublicBrowseProvider>();
                                    prov.updateQuery(
                                      city: result['city'] as String?,
                                      propertyType:
                                          result['propertyType'] as String?,
                                      maxGuests: result['maxGuests'] as int?,
                                      minPrice: result['minPrice'] as num?,
                                      maxPrice: result['maxPrice'] as num?,
                                      centerLat: result['centerLat'] as double?,
                                      centerLng: result['centerLng'] as double?,
                                      radiusKm: result['radiusKm'] as double?,
                                      orderBy: result['orderBy'] as String?,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.filter_list, size: 18),
                                label: const Text('تصفية'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  foregroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon:
                                  const Icon(Icons.sort, color: Colors.black54),
                              tooltip: 'فرز',
                              onSelected: (v) => prov.updateQuery(orderBy: v),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                    value: 'recent', child: Text('الأحدث')),
                                const PopupMenuItem(
                                    value: 'price_asc',
                                    child: Text('السعر: تصاعدي')),
                                const PopupMenuItem(
                                    value: 'price_desc',
                                    child: Text('السعر: تنازلي')),
                                const PopupMenuItem(
                                    value: 'rating_desc',
                                    child: Text('الأعلى تقييماً')),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'distance_asc',
                                  enabled: prov.centerLat != null &&
                                      prov.centerLng != null,
                                  child: const Text('الأقرب'),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Quick Location Actions
                        const _GeoQuickActions(),
                      ],
                    ),
                  ),
                ),

                // === 2. Error ===
                if (prov.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        prov.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                // === 3. Loading Skeletons ===
                if (prov.loading && prov.items.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: PublicPropertyCardSkeleton(),
                        ),
                        childCount: 6,
                      ),
                    ),
                  )

                // === 4. Properties List ===
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= prov.items.length) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: PublicPropertyCardSkeleton(),
                            );
                          }
                          final item = prov.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PublicPropertyCard(
                              item: item,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('تسجيل الدخول مطلوب'),
                                    content: const Text(
                                        'سجّل دخولك لمشاهدة التفاصيل الكاملة وإتمام الحجز.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text('إلغاء'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          if (mounted) context.go('/login');
                                        },
                                        child: const Text('تسجيل الدخول'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: prov.items.length +
                            (prov.loading && prov.hasMore ? 1 : 0),
                      ),
                    ),
                  ),

                // === 5. No Results ===
                if (!prov.loading && prov.items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.search, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text('لا توجد نتائج حالياً',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
