import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:godarna/providers/favorites_provider.dart';
import 'package:godarna/constants/app_colors.dart';

/// شاشة المفضلة الحديثة بأسلوب Airbnb
class FavoritesScreenAirbnb extends StatefulWidget {
  const FavoritesScreenAirbnb({super.key});

  @override
  State<FavoritesScreenAirbnb> createState() => _FavoritesScreenAirbnbState();
}

class _FavoritesScreenAirbnbState extends State<FavoritesScreenAirbnb>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isSearching = false;
  
  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'الكل', 'icon': Icons.apps_rounded},
    {'id': 'apartment', 'label': 'شقق', 'icon': Icons.apartment_rounded},
    {'id': 'villa', 'label': 'فيلات', 'icon': Icons.villa_rounded},
    {'id': 'riad', 'label': 'رياضات', 'icon': Icons.mosque_rounded},
    {'id': 'recent', 'label': 'حديثة', 'icon': Icons.schedule_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
      _fadeController.forward();
      _scaleController.forward();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
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
              // SliverAppBar محسن بأسلوب Airbnb
              _buildModernSliverAppBar(favoritesProvider, isDark),
              
              // شريط البحث والفلاتر
              if (!_isSearching) _buildFiltersSection(isDark),
              if (_isSearching) _buildSearchSection(isDark),
              
              // المحتوى الرئيسي
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

  // بناء SliverAppBar محسن
  Widget _buildModernSliverAppBar(FavoritesProvider provider, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      snap: false,
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
                (isDark ? AppColors.backgroundPrimaryDark : Colors.white).withAlpha(200),
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
                  // العنوان الرئيسي
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المفضلة',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              fontFamily: 'Cairo',
                              height: 1.2,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // شريط الأدوات
      actions: [
        // زر البحث
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
            tooltip: _isSearching ? 'إغلاق البحث' : 'البحث',
          ),
        ),
        // زر مسح الكل
        if (provider.favorites.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showClearAllDialog(provider),
              icon: const Icon(
                Icons.clear_all_rounded,
                color: Colors.red,
              ),
              tooltip: 'مسح الكل',
            ),
          ),
      ],
    );
  }
  
  // بناء قسم الفلاتر
  Widget _buildFiltersSection(bool isDark) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter['id'];
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFilter = filter['id'];
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [AppColors.primaryRed, AppColors.primaryRed.withAlpha(200)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? AppColors.backgroundSecondaryDark : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryRed
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryRed.withAlpha(50),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'],
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          filter['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[300] : AppColors.textPrimary),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
