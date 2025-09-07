import 'package:flutter/material.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:godarna/models/property_model.dart';
import 'package:godarna/providers/favorites_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/constants/app_colors.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> 
    with RealtimeMixin, TickerProviderStateMixin {
  int _currentImageIndex = 0;
  late PageController _pageController;
  ScrollController? _scrollController;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPropertyDetails();
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    // اشتراك في تحديثات العقار المحدد
    subscribeToTable(
      table: 'properties',
      filter: 'id',
      filterValue: widget.property.id,
      onInsert: (payload) {
        if (mounted) {
          _loadPropertyDetails();
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          _loadPropertyDetails();
        }
      },
      onDelete: (payload) {
        if (mounted) {
          // العقار تم حذفه - العودة للقائمة
          Navigator.of(context).pop();
        }
      },
    );

    // اشتراك في تحديثات المراجعات
    subscribeToTable(
      table: 'reviews',
      filter: 'property_id',
      filterValue: widget.property.id,
      onInsert: (payload) {
        if (mounted) {
          _loadPropertyDetails();
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          _loadPropertyDetails();
        }
      },
      onDelete: (payload) {
        if (mounted) {
          _loadPropertyDetails();
        }
      },
    );
  }

  void _loadPropertyDetails() {
    // Load property details logic here
  }

  void _shareProperty(PropertyModel property) {
    // Share functionality - will implement with share_plus package
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController?.dispose();
    _tabController?.dispose();
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundPrimaryDark
          : AppColors.backgroundPrimary,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // === 1. Enhanced SliverAppBar with Image Carousel ===
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: isDark
                    ? AppColors.backgroundPrimaryDark
                    : AppColors.backgroundPrimary,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    children: [
                      // Enhanced Image Carousel
                      PageView.builder(
                        controller: _pageController,
                        itemCount: property.photos.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                          HapticFeedback.lightImpact();
                        },
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: 'property-${property.id}-$index',
                            child: CachedNetworkImage(
                              imageUrl: property.photos[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.grey100,
                                      AppColors.grey200,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: LinearProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryRed),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.grey100,
                                      AppColors.grey200
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(AppIcons.imageOff,
                                        size: 64, color: AppColors.grey500),
                                    SizedBox(height: 16),
                                    Text('صورة غير متاحة',
                                        style: TextStyle(
                                            color: AppColors.grey500,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Gradient overlay for better text visibility
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha((0.4 * 255).toInt()),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Top Navigation Bar
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors.black.withAlpha((0.3 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_rounded,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),

                            // Action Buttons
                            Row(
                              children: [
                                // Share Button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withAlpha((0.3 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.share_rounded,
                                        color: Colors.white),
                                    onPressed: () => _shareProperty(property),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Favorite Button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withAlpha((0.3 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      favoritesProvider.isFavorite(property.id)
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: favoritesProvider.isFavorite(property.id)
                                          ? AppColors.primaryRed
                                          : Colors.white,
                                    ),
                                    onPressed: () async {
                                      await favoritesProvider.toggleFavorite(property.id);
                                      HapticFeedback.lightImpact();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Image Indicators
                      if (property.photos.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                property.photos.asMap().entries.map((entry) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: entry.key == _currentImageIndex ? 24 : 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: entry.key == _currentImageIndex
                                      ? AppColors.primaryRed
                                      : Colors.white
                                          .withAlpha((0.5 * 255).toInt()),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withAlpha((0.2 * 255).toInt()),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // === 2. Property Information ===
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.backgroundSecondaryDark,
                              AppColors.backgroundTertiaryDark
                            ]
                          : [Colors.white, AppColors.grey50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withAlpha((0.3 * 255).toInt())
                            : AppColors.shadowLight,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.primaryRed,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        property.locationDisplay,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.saharaGold
                                  .withAlpha((0.1 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.saharaGold
                                    .withAlpha((0.3 * 255).toInt()),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.saharaGold,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${property.rating}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.saharaGold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Property Details
                      Row(
                        children: [
                          _buildDetailItem(
                            Icons.bed_rounded,
                            '${property.bedrooms}',
                            'غرف نوم',
                            AppColors.mintGreen,
                            isDark,
                          ),
                          const SizedBox(width: 16),
                          _buildDetailItem(
                            Icons.bathtub_rounded,
                            '${property.bathrooms}',
                            'حمام',
                            AppColors.spiceOrange,
                            isDark,
                          ),
                          const SizedBox(width: 16),
                          _buildDetailItem(
                            Icons.people_rounded,
                            '${property.maxGuests}',
                            'ضيوف',
                            AppColors.royalPurple,
                            isDark,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'الوصف',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        property.description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // === 3. Amenities ===
              if (property.amenities.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.backgroundSecondaryDark,
                                AppColors.backgroundTertiaryDark
                              ]
                            : [Colors.white, AppColors.grey50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withAlpha((0.3 * 255).toInt())
                              : AppColors.shadowLight,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المرافق',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: property.amenities.map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.atlasBlue
                                        .withAlpha((0.1 * 255).toInt()),
                                    AppColors.mintGreen
                                        .withAlpha((0.1 * 255).toInt()),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.atlasBlue
                                      .withAlpha((0.3 * 255).toInt()),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                amenity,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom padding for fixed bottom bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),

          // === Enhanced Bottom Bar with Price and Booking ===
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.backgroundSecondaryDark
                              .withAlpha((0.95 * 255).toInt()),
                          AppColors.backgroundTertiaryDark
                              .withAlpha((0.98 * 255).toInt()),
                        ]
                      : [
                          Colors.white.withAlpha((0.95 * 255).toInt()),
                          Colors.white,
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha((0.4 * 255).toInt())
                        : AppColors.shadowLight,
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Price Section
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                property.pricePerNight.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'درهم',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryRed,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'لكل ليلة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.saharaGold
                                      .withAlpha((0.1 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.saharaGold
                                        .withAlpha((0.3 * 255).toInt()),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: AppColors.saharaGold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${property.rating}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.saharaGold,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Booking Button
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              AppColors.primaryRedLight
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed
                                  .withAlpha((0.4 * 255).toInt()),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.pushNamed(
                                'createBooking',
                                extra: property,
                              );
                            },
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'احجز الآن',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
