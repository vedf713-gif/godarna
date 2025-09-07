import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/property_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/language_provider.dart';
import '../../constants/app_strings.dart';
import '../../models/property_model.dart';
import '../../screens/main/favorites_screen.dart';
import '../../screens/main/bookings_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../mixins/realtime_mixin.dart';
import 'package:godarna/screens/map/map_screen.dart';
import 'package:godarna/screens/admin/admin_screen.dart';
import 'package:godarna/screens/host/host_bookings_screen.dart';
import 'package:godarna/widgets/skeleton.dart';
import 'package:godarna/widgets/empty_state.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:godarna/utils/permissions.dart';
import 'package:godarna/widgets/permission_rationale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/widgets/app_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RealtimeMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  late final FlutterLocalNotificationsPlugin _fln;
  bool _askedOnceThisSession = false;

  @override
  void initState() {
    super.initState();

    _fln = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    _fln.initialize(const InitializationSettings(android: android, iOS: ios));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();

      _scrollController.addListener(() {
        final currentScroll = _scrollController.offset;
        _scrollOffset.value = currentScroll.clamp(0.0, 100.0) / 100.0;
      });
    });
  }

  Future<void> _initializeData() async {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    
    // تفعيل Realtime للشاشة الرئيسية
    _setupRealtimeSubscriptions();
    
    await Future.wait([
      propertyProvider.initialize(),
      notificationProvider.loadNotifications(),
    ]);
    
    if (!mounted) return;
    await _maybeRequestAllPermissionsOnce();
  }

  void _setupRealtimeSubscriptions() {
    debugPrint('🔄 [HomeScreen] Setting up realtime subscriptions');
    
    // اشتراك في تحديثات العقارات
    subscribeToTable(
      table: 'properties',
      onInsert: (payload) {
        debugPrint('🏠 [HomeScreen] Property inserted');
        final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
        propertyProvider.fetchProperties(forceRefresh: true);
      },
      onUpdate: (payload) {
        debugPrint('🏠 [HomeScreen] Property updated');
        final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
        propertyProvider.fetchProperties(forceRefresh: true);
      },
      onDelete: (payload) {
        debugPrint('🏠 [HomeScreen] Property deleted');
        final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
        propertyProvider.fetchProperties(forceRefresh: true);
      },
    );
    
    // اشتراك في تحديثات الإشعارات للمستخدم الحالي
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      subscribeToTable(
        table: 'notifications',
        filter: 'user_id',
        filterValue: currentUserId,
        onInsert: (payload) {
          debugPrint('🔔 [HomeScreen] Notification received');
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.loadNotifications();
        },
      );
    }
    
    // اشتراك في تحديثات الحجوزات للمستخدم الحالي
    if (currentUserId != null) {
      subscribeToTable(
        table: 'bookings',
        filter: 'tenant_id',
        filterValue: currentUserId,
        onInsert: (payload) {
          debugPrint('📅 [HomeScreen] Booking created');
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings();
        },
        onUpdate: (payload) {
          debugPrint('📅 [HomeScreen] Booking updated');
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings();
        },
      );
    }
  }

  Future<void> _refreshProperties() async {
    HapticFeedback.lightImpact();
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    await propertyProvider.fetchProperties(forceRefresh: true);
  }

  Future<void> _maybeRequestAllPermissionsOnce() async {
    if (_askedOnceThisSession) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final items = [
      (
        key: 'perm_notifications_requested',
        title: PermissionRationaleTexts.notificationsTitle(context),
        body: PermissionRationaleTexts.notificationsBody(context),
        action: () => PermissionsHelper.requestNotificationPermission(_fln),
      ),
      (
        key: 'perm_location_requested',
        title: PermissionRationaleTexts.locationTitle(context),
        body: PermissionRationaleTexts.locationBody(context),
        action: PermissionsHelper.requestLocationPermission,
      ),
      (
        key: 'perm_camera_requested',
        title: PermissionRationaleTexts.cameraTitle(context),
        body: PermissionRationaleTexts.cameraBody(context),
        action: PermissionsHelper.requestCameraPermission,
      ),
      (
        key: 'perm_media_requested',
        title: PermissionRationaleTexts.photosTitle(context),
        body: PermissionRationaleTexts.photosBody(context),
        action: PermissionsHelper.requestMediaPermission,
      ),
    ];

    for (final item in items) {
      final already = prefs.getBool(item.key) ?? false;
      if (already) continue;

      if (!mounted) return;
      final proceed = await showPermissionRationale(
        context,
        title: item.title,
        message: item.body,
        proceedText: AppStrings.getString('continue', context),
        cancelText: AppStrings.getString('later', context),
      );
      await prefs.setBool(item.key, true);
      if (!mounted) return;
      if (!proceed) continue;
      await item.action();
    }

    _askedOnceThisSession = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    const primaryColor = Color(0xFFFF3A44);

    final pages = <Widget>[
      _buildHomePage(),
      const MapScreen(),
      const FavoritesScreen(),
    ];
    if (authProvider.isHost) {
      pages.add(const HostBookingsScreen());
    }
    pages.addAll([
      const BookingsScreen(),
      if (authProvider.isAdmin) const AdminScreen(),
      const ProfileScreen(),
    ]);

    final maxIndex = pages.length - 1;
    if (_currentIndex > maxIndex) {
      _currentIndex = maxIndex;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        elevation: 8,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppStrings.getString('home', context),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            activeIcon: const Icon(Icons.map),
            label: AppStrings.getString('map', context),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: const Icon(Icons.favorite),
            label: AppStrings.getString('favorites', context),
          ),
          if (authProvider.isHost)
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today_outlined),
              activeIcon: const Icon(Icons.calendar_today),
              label: AppStrings.getString('hostBookings', context),
            ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmarks_outlined),
            activeIcon: const Icon(Icons.bookmarks),
            label: AppStrings.getString('bookings', context),
          ),
          if (authProvider.isAdmin)
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              activeIcon: const Icon(Icons.admin_panel_settings),
              label: AppStrings.getString('admin', context),
            ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: const Icon(Icons.person),
            label: AppStrings.getString('profile', context),
          ),
        ],
      ),
      floatingActionButton: authProvider.isHost
          ? FloatingActionButton(
              onPressed: () {
                context.push('/property/add');
              },
              backgroundColor: primaryColor,
              child: const Icon(AppIcons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHomePage() {
    return Consumer2<PropertyProvider, FavoritesProvider?>(
      builder: (context, propertyProvider, favoritesProvider, child) {
        if (propertyProvider.isLoading) {
          return _buildLoadingView();
        } else if (propertyProvider.error != null) {
          return _buildErrorView(propertyProvider);
        }

        // 🏙️ جمع العقارات حسب المدينة
        final groupedByCity = <String, List<PropertyModel>>{};
        for (final prop in propertyProvider.filteredProperties) {
          final city = prop.city.isNotEmpty ? prop.city : 'Unknown';
          groupedByCity.putIfAbsent(city, () => []);
          groupedByCity[city]!.add(prop);
        }

        // 🌟 العقارات المميزة
        final featuredProperties = propertyProvider.filteredProperties
            .where((prop) => prop.rating >= 4.5)
            .take(5)
            .toList();

        if (groupedByCity.isEmpty) {
          return _buildEmptyView();
        }

        return RefreshIndicator(
          onRefresh: _refreshProperties,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ✅ الشريط العلوي المتحرك
              _buildTopBarSliver(),

              // ✅ شريط البحث والفلتر
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchBar(propertyProvider),
                ),
              ),

              // ✅ فئات العقارات
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCategoryChips(),
                ),
              ),

              // ✅ العقارات المميزة
              if (featuredProperties.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العقارات المميزة',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF3A44),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: featuredProperties.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            physics: const BouncingScrollPhysics(),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final property = featuredProperties[index];
                              return GestureDetector(
                                onTap: () {
                                  context.push('/property/${property.id}');
                                },
                                child: SizedBox(
                                  width: 290,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[850]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withAlpha((0.08 * 255).round()),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // صورة العقار مع تأثير تدرج
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(18)),
                                              child: property.photos.isNotEmpty
                                                  ? Image.network(
                                                      property.photos.first,
                                                      width: double.infinity,
                                                      height: 180,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      height: 180,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                          Icons.home_outlined),
                                                    ),
                                            ),
                                            // تأثير تدرج في الجزء السفلي من الصورة
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 60,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black54,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // زر المفضلة في الزاوية العلوية اليمنى
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.white70,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  onPressed: () async {
                                                    await favoritesProvider
                                                        ?.toggleFavorite(
                                                            property.id);
                                                  },
                                                  icon: Icon(
                                                    (favoritesProvider
                                                                ?.isFavorite(
                                                                    property.id) ??
                                                            false)
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color:
                                                        const Color(0xFFFF3A44),
                                                    size: 20,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // تفاصيل العقار
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // نوع العقار والمدينة
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _getPropertyTypeLabel(
                                                        property.propertyType),
                                                    style: const TextStyle(
                                                      color: Color(0xFFFF3A44),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    property.city,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // العنوان
                                              Text(
                                                property.title,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              // الموقع
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      property.area,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // التقييم والسعر
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // التقييم
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        property.rating
                                                            .toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '(${property.reviewCount})',
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // السعر
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        NumberFormat('#,##0',
                                                                'ar_MA')
                                                            .format(property
                                                                .pricePerNight),
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFFFF3A44),
                                                        ),
                                                      ),
                                                      const Text(
                                                        'لليلة',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ✅ عرض العقارات مقسمة حسب المدينة
              ...groupedByCity.entries.map((entry) {
                final city = entry.key;
                final properties = entry.value;

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عنوان المدينة
                        Text(
                          city,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF3A44),
                                  ),
                        ),
                        const SizedBox(height: 12),

                        // قائمة أفقية للعقارات
                        SizedBox(
                          height: 340, // زيادة الارتفاع قليلاً
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: properties.length,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8), // إضافة padding جانبي
                            physics:
                                const BouncingScrollPhysics(), // إضافة تأثير ارتداد للتمرير
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final property = properties[index];
                              return GestureDetector(
                                onTap: () {
                                  context.push('/property/${property.id}');
                                },
                                child: SizedBox(
                                  width: 290,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[850]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withAlpha((0.08 * 255).round()),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // صورة العقار مع زر المفضلة
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(18)),
                                              child: CachedNetworkImage(
                                                imageUrl: property
                                                        .photos.isNotEmpty
                                                    ? property.photos.first
                                                    : 'https://placehold.co/400x200',
                                                height: 180,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const SkeletonList(
                                                  itemCount: 1,
                                                  itemHeight: 180,
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            ),
                                            // زر المفضلة في الزاوية العلوية اليمنى
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.white70,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  onPressed: () async {
                                                    await favoritesProvider
                                                        ?.toggleFavorite(
                                                            property.id);
                                                  },
                                                  icon: Icon(
                                                    (favoritesProvider
                                                                ?.isFavorite(
                                                                    property.id) ??
                                                            false)
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color:
                                                        const Color(0xFFFF3A44),
                                                    size: 20,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // تفاصيل العقار
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // نوع العقار والمدينة
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _getPropertyTypeLabel(
                                                        property.propertyType),
                                                    style: const TextStyle(
                                                      color: Color(0xFFFF3A44),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    property.city,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // العنوان
                                              Text(
                                                property.title,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              // الموقع
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      property.area,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // التقييم والسعر
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // التقييم
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        property.rating
                                                            .toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '(${property.reviewCount})',
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // السعر
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        NumberFormat('#,##0',
                                                                'ar_MA')
                                                            .format(property
                                                                .pricePerNight),
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFFFF3A44),
                                                        ),
                                                      ),
                                                      const Text(
                                                        'لليلة',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF3A44),
              const Color(0xFFFF3A44).withAlpha((0.8 * 255).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الشعار المحسن
                Row(
                  children: [
                    AppLogo(
                      size: 40,
                      borderRadius: 12,
                      backgroundColor:
                          Colors.white.withAlpha((0.2 * 255).toInt()),
                      animate: false,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'GoDarna',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // الأيقونات المحسنة
                Row(
                  children: [
                    // إشعارات مع badge
                    Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildTopBarButton(
                              onPressed: () {
                                context.push('/notifications');
                              },
                              icon: Icons.notifications_outlined,
                            ),
                            if (notificationProvider.hasUnreadNotifications)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    notificationProvider.unreadCount > 9
                                        ? '9+'
                                        : notificationProvider.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    // تبديل اللغة
                    _buildTopBarButton(
                      onPressed: () {
                        final languageProvider = Provider.of<LanguageProvider>(
                            context,
                            listen: false);
                        languageProvider.toggleLanguage();
                      },
                      child: Text(
                        Provider.of<LanguageProvider>(context).isArabic
                            ? 'FR'
                            : 'AR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarButton({
    required VoidCallback onPressed,
    IconData? icon,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha((0.3 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: child ??
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(PropertyProvider propertyProvider) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن عقار...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: 24,
                ),
              ),
              onChanged: (value) {
                propertyProvider.setSearchQuery(value);
              },
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3A44).withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune,
                color: Color(0xFFFF3A44),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        final selectedPropertyType = propertyProvider.selectedPropertyType;

        // أنواع العقارات المتاحة
        final propertyTypes = [
          ('', 'الكل'),
          ('apartment', 'شقة'),
          ('studio', 'استوديو'),
          ('villa', 'فيلا'),
          ('riad', 'رياض'),
          ('kasbah', 'قصبة'),
          ('village_house', 'بيت قروي'),
          ('desert_camp', 'مخيم صحراوي'),
          ('eco_lodge', 'نزل بيئي'),
          ('guesthouse', 'بيت ضيافة'),
          ('hotel', 'فندق'),
          ('resort', 'منتجع'),
        ];

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: propertyTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final type = propertyTypes[index];
              final isSelected = selectedPropertyType == type.$1;

              return ChoiceChip(
                label: Text(
                  type.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  propertyProvider.setSelectedPropertyType(
                    selected ? type.$1 : '',
                  );
                },
                selectedColor: const Color(0xFFFF3A44),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF3A44)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                labelStyle: const TextStyle(fontSize: 15),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            },
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        _buildTopBarSliver(),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  const SkeletonList(itemCount: 1, itemHeight: 200),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBarSliver() {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, child) {
        final opacity = 1.0 - offset.clamp(0.0, 1.0);
        final translateY = -50 * offset;

        return SliverToBoxAdapter(
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: _buildTopBar(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(PropertyProvider provider) {
    return Center(
      child: EmptyState(
        title: AppStrings.getString('error', context),
        message: provider.error!,
        icon: Icons.error_outline,
        actionLabel: AppStrings.getString('retry', context),
        onAction: () => provider.fetchProperties(),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: EmptyState(
        icon: Icons.sentiment_dissatisfied_rounded,
        title: AppStrings.getString('no_properties_found', context),
        message: AppStrings.getString('try_adjusting_filters', context),
        actionLabel: AppStrings.getString('clear_filters', context),
        onAction: () => Provider.of<PropertyProvider>(context, listen: false)
            .clearFilters(),
      ),
    );
  }

  String _getPropertyTypeLabel(String propertyType) {
    switch (propertyType) {
      case 'apartment':
        return 'شقة';
      case 'studio':
        return 'استوديو';
      case 'villa':
        return 'فيلا';
      case 'riad':
        return 'رياض';
      case 'kasbah':
        return 'قصبة';
      case 'village_house':
        return 'بيت قروي';
      case 'desert_camp':
        return 'مخيم صحراوي';
      case 'eco_lodge':
        return 'نزل بيئي';
      case 'guesthouse':
        return 'بيت ضيافة';
      case 'hotel':
        return 'فندق';
      case 'resort':
        return 'منتجع';
      default:
        return 'عقار';
    }
  }
}
