import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:godarna/providers/favorites_provider.dart';
import 'package:godarna/constants/app_colors.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/widgets/skeleton.dart';
import 'package:godarna/widgets/empty_state.dart';
import 'package:godarna/models/property_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isSearching = false;

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'الكل', 'icon': Icons.apps_rounded},
    {'id': 'apartment', 'label': 'شقق', 'icon': Icons.apartment_rounded},
    {'id': 'villa', 'label': 'فيلات', 'icon': Icons.villa_rounded},
    {'id': 'riad', 'label': 'رياضات', 'icon': Icons.mosque_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    await favoritesProvider.fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundPrimaryDark
          : AppColors.backgroundPrimary,
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildModernSliverAppBar(favoritesProvider, isDark),
              if (!_isSearching) _buildFiltersSection(isDark),
              if (_isSearching) _buildSearchSection(isDark),
              if (favoritesProvider.isLoading)
                _buildLoadingSliverView()
              else if (favoritesProvider.error != null)
                _buildErrorSliverView(favoritesProvider)
              else if (favoritesProvider.favorites.isEmpty)
                _buildEmptySliverView(isDark)
              else
                _buildFavoritesSliverView(favoritesProvider, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernSliverAppBar(FavoritesProvider provider, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.backgroundPrimaryDark : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryRed.withAlpha(20),
                (isDark ? AppColors.backgroundPrimaryDark : Colors.white)
                    .withAlpha(200),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المفضلة',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.favorites.length} عقار مفضل',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _isSearching
                ? AppColors.primaryRed.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: _isSearching
                  ? AppColors.primaryRed
                  : (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ),
        if (provider.favorites.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showClearAllDialog(provider),
              icon: const Icon(Icons.clear_all_rounded, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltersSection(bool isDark) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter['id'];

            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedFilter = filter['id']);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [
                              AppColors.primaryRed,
                              AppColors.primaryRed.withAlpha(200)
                            ])
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? AppColors.backgroundSecondaryDark
                              : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryRed
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(filter['icon'],
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600])),
                        const SizedBox(width: 8),
                        Text(
                          filter['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey[300]
                                    : AppColors.textPrimary),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundSecondaryDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              hintText: 'ابحث في المفضلة...',
              prefixIcon: Icon(Icons.search_rounded),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSliverView() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            height: 300,
            margin: const EdgeInsets.only(bottom: 16),
            child: const SkeletonList(itemCount: 1, itemHeight: 300),
          ),
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildErrorSliverView(FavoritesProvider provider) {
    return SliverFillRemaining(
      child: EmptyState(
        icon: Icons.error_outline,
        title: 'خطأ في تحميل المفضلة',
        message: provider.error ?? 'حدث خطأ غير متوقع',
        actionLabel: 'إعادة المحاولة',
        onAction: _loadFavorites,
      ),
    );
  }

  Widget _buildEmptySliverView(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primaryRed.withAlpha(25),
                  AppColors.saharaGold.withAlpha(25)
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.favoriteOutline,
                  size: 48, color: AppColors.primaryRed.withAlpha(150)),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد عقارات مفضلة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة العقارات التي تعجبك إلى المفضلة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('استكشاف العقارات',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSliverView(FavoritesProvider provider, bool isDark) {
    final favorites = _getFilteredFavorites(provider.favoriteProperties);

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final property = favorites[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildFavoriteCard(property, provider, isDark),
            );
          },
          childCount: favorites.length,
        ),
      ),
    );
  }

  List<PropertyModel> _getFilteredFavorites(List<PropertyModel> favorites) {
    var filtered = favorites;

    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((property) => property.propertyType == _selectedFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((property) =>
              property.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              property.city.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildFavoriteCard(
      PropertyModel property, FavoritesProvider provider, bool isDark) {
    return Hero(
      tag: 'favorite-${property.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/property/${property.id}');
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppColors.backgroundSecondaryDark : Colors.white,
                  isDark ? AppColors.backgroundTertiaryDark : Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withAlpha(15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      child: CachedNetworkImage(
                        imageUrl: property.photos.isNotEmpty
                            ? property.photos.first
                            : '',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 220,
                          color: Colors.grey[300],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 220,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, size: 48),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => _removeFavorite(property, provider),
                          icon: const Icon(AppIcons.favorite,
                              color: AppColors.primaryRed),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${property.city}, المغرب',
                            style: TextStyle(
                                color: Colors.grey[600], fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${NumberFormat('#,##0', 'ar_MA').format(property.pricePerNight)} درهم/ليلة',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                              fontFamily: 'Cairo',
                            ),
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
      ),
    );
  }

  Future<void> _removeFavorite(
      PropertyModel property, FavoritesProvider provider) async {
    HapticFeedback.lightImpact();
    final success = await provider.removeFromFavorites(property.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'تم إزالة ${property.title} من المفضلة'
              : 'فشل في إزالة العقار'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _showClearAllDialog(FavoritesProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح جميع المفضلة'),
        content: const Text('هل أنت متأكد من مسح جميع العقارات المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );

    if (result == true) {
      HapticFeedback.mediumImpact();
      final success = await provider.clearAllFavorites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'تم مسح جميع المفضلة' : 'فشل في مسح المفضلة'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
