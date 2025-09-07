import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/data/morocco_regions_cities.dart';
import 'package:godarna/providers/language_provider.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/constants/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedPropertyType;
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minBound = 0;
  double _maxBound = 10000;
  int _selectedGuests = 1;
  DateTimeRange? _dateRange;
  List<String> _selectedAmenities = [];
  String _sortBy = 'none';

  static const Map<String, List<String>> _propertyTypeGroups = {
    '🏘️ الإقامات العصرية': ['apartment', 'studio', 'villa'],
    '🏡 الإقامات التقليدية': ['riad', 'kasbah', 'village_house'],
    '🏕️ الإقامات البدوية': ['desert_camp', 'eco_lodge', 'guesthouse'],
    '🏨 الإقامات الفندقية': ['hotel', 'resort'],
  };

  late final List<String> _allPropertyTypes =
      _propertyTypeGroups.values.expand((e) => e).toList();

  @override
  void initState() {
    super.initState();
    _initializeFromProvider();
  }

  void _initializeFromProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PropertyProvider>();
      final priceRange = provider.priceRange;

      setState(() {
        _selectedRegion =
            provider.selectedRegion.isEmpty ? null : provider.selectedRegion;
        _selectedCity =
            provider.selectedCity.isEmpty ? null : provider.selectedCity;
        _selectedPropertyType = provider.selectedPropertyType.isEmpty
            ? null
            : provider.selectedPropertyType;
        _minBound = priceRange['min'] ?? 0;
        _maxBound = priceRange['max'] ?? 10000;
        _priceRange = RangeValues(
          provider.minPrice.clamp(_minBound, _maxBound),
          provider.maxPrice.clamp(_minBound, _maxBound),
        );
        _selectedGuests = provider.selectedGuests;
        if (provider.checkInDate != null && provider.checkOutDate != null) {
          _dateRange = DateTimeRange(
            start: provider.checkInDate!,
            end: provider.checkOutDate!,
          );
        }
        _selectedAmenities = List.from(provider.selectedAmenities);
        _sortBy = provider.sortBy;
      });
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _dateRange = picked);
    }
  }

  void _applyFilters() {
    HapticFeedback.selectionClick();

    final provider = context.read<PropertyProvider>();
    provider.setSelectedRegion(_selectedRegion ?? '');
    provider.setSelectedCity(_selectedCity ?? '');
    provider.setSelectedPropertyType(_selectedPropertyType ?? '');
    provider.setPriceRange(_priceRange.start, _priceRange.end);
    provider.setSelectedGuests(_selectedGuests);
    provider.setDateRange(_dateRange?.start, _dateRange?.end);
    provider.setSelectedAmenities(_selectedAmenities);
    provider.setSortBy(_sortBy);

    context.pop();
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    context.read<PropertyProvider>().clearFilters();
    context.pop();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<PropertyProvider>();
    final lang = context.watch<LanguageProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.backgroundCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHandleIndicator(theme),
          _buildHeader(theme, provider),
          Expanded(
            child: _buildFiltersContent(context, theme, lang),
          ),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHandleIndicator(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey600 : AppColors.grey300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  void _showPropertyTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _PropertyTypeSelector(
          selectedType: _selectedPropertyType,
          allTypes: _allPropertyTypes,
        ),
      ),
    ).then((selectedType) {
      if (selectedType != null && mounted) {
        setState(() {
          _selectedPropertyType = selectedType;
        });
      }
    });
  }

  Widget _buildHeader(ThemeData theme, PropertyProvider provider) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.backgroundCardDark,
                  AppColors.backgroundSecondaryDark
                ]
              : [AppColors.backgroundCard, AppColors.grey50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderLightDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // تحديد حجم الـ Row لتجنب العرض غير المحدود
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppStrings.getString('filters', context),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16), // استبدال Spacer بـ SizedBox
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.error.withAlpha(128),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 100, // عرض أدنى
                maxWidth: 150, // عرض أقصى
              ),
              child: TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(100, 40), // ضمان حجم مناسب
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  AppStrings.getString('clearFilters', context),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersContent(
      BuildContext context, ThemeData theme, LanguageProvider lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Property Type
          _FilterSection(
            title: AppStrings.getString('accommodationTypes', context),
            child: InkWell(
              onTap: _showPropertyTypeSelector,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(77),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.home_work_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedPropertyType == null
                            ? AppStrings.getString('all', context)
                            : _getPropertyTypeLabel(
                                context, _selectedPropertyType!),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Region
          _FilterSection(
            title: 'الجهة',
            child: DropdownButtonFormField<String?>(
              value: _selectedRegion,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    AppStrings.getString('allRegions', context),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ...MoroccoRegionsCities.regions
                    .map((region) => DropdownMenuItem(
                          value: region,
                          child: Text(
                            MoroccoRegionsCities.displayRegion(region,
                                french: lang.isFrench),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        )),
              ],
              onChanged: (value) => setState(() {
                _selectedRegion = value;
                _selectedCity = null;
              }),
            ),
          ),
          const SizedBox(height: 16),

          // City
          _FilterSection(
            title: AppStrings.getString('city', context),
            child: DropdownButtonFormField<String?>(
              value: _selectedCity,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    AppStrings.getString('allCities', context),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ...MoroccoRegionsCities.citiesFor(_selectedRegion)
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(
                            MoroccoRegionsCities.displayCity(city,
                                french: lang.isFrench),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        )),
              ],
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
          ),
          const SizedBox(height: 16),

          // Date Range
          _FilterSection(
            title: AppStrings.getString('dateRange', context),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(AppIcons.dateRange),
                    label: Text(
                      _dateRange == null
                          ? AppStrings.getString('selectDates', context)
                          : '${_formatDate(_dateRange!.start)} → ${_formatDate(_dateRange!.end)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: AppStrings.getString('clear', context),
                  onPressed: _dateRange != null
                      ? () => setState(() => _dateRange = null)
                      : null,
                  icon: const Icon(AppIcons.clear),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Price Range
          _FilterSection(
            title: AppStrings.getString('priceRange', context),
            child: Column(
              children: [
                RangeSlider(
                  values: _priceRange,
                  min: _minBound,
                  max: _maxBound,
                  divisions:
                      ((_maxBound - _minBound) / 100).round().clamp(1, 200),
                  labels: RangeLabels(
                    '${_priceRange.start.round()} ${AppStrings.getString('currencyShort', context)}',
                    '${_priceRange.end.round()} ${AppStrings.getString('currencyShort', context)}',
                  ),
                  onChanged: (values) => setState(() => _priceRange = values),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${_priceRange.start.round()} ${AppStrings.getString('currencyShort', context)}'),
                    Text(
                        '${_priceRange.end.round()} ${AppStrings.getString('currencyShort', context)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Guests
          _FilterSection(
            title: AppStrings.getString('guestsFilter', context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _selectedGuests > 1
                      ? () => setState(() => _selectedGuests--)
                      : null,
                  icon: const Icon(AppIcons.removeCircle),
                ),
                const SizedBox(width: 16),
                Text(
                  '$_selectedGuests ${AppStrings.getString('guests', context)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => setState(() => _selectedGuests++),
                  icon: const Icon(AppIcons.addCircle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Amenities
          _FilterSection(
            title: AppStrings.getString('amenities', context),
            child: _buildAmenitiesChips(context),
          ),
          const SizedBox(height: 20),

          // Sort By
          _FilterSection(
            title: AppStrings.getString('sortBy', context),
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                _buildSortDropdownItem('none', 'sortNone'),
                _buildSortDropdownItem('price_asc', 'sortPriceAsc'),
                _buildSortDropdownItem('price_desc', 'sortPriceDesc'),
                _buildSortDropdownItem('rating_desc', 'sortRatingDesc'),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sortBy = value);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildSortDropdownItem(String value, String key) {
    return DropdownMenuItem(
      value: value,
      child: Text(AppStrings.getString(key, context)),
    );
  }

  Widget _buildAmenitiesChips(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final amenities = context.select<PropertyProvider, List<String>>(
        (provider) => provider.availableAmenities
            .where((a) => a.isNotEmpty && a.trim().isNotEmpty)
            .toList());

    if (amenities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundSecondaryDark : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderLightDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.getString('noAmenities', context),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: amenities.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: FilterChip(
            label: Text(
              amenity,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
                fontFamily: 'Cairo',
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.royalPurple,
            backgroundColor: isDark
                ? AppColors.backgroundSecondaryDark
                : AppColors.backgroundCard,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.royalPurple
                  : (isDark
                      ? AppColors.borderLightDark
                      : AppColors.borderLight),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isSelected ? 4 : 0,
            shadowColor: AppColors.royalPurple.withAlpha(77),
            onSelected: (selected) {
              HapticFeedback.selectionClick();
              setState(() {
                selected
                    ? _selectedAmenities.add(amenity)
                    : _selectedAmenities.remove(amenity);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.backgroundCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderLightDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.15 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Clear Filters Button
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxHeight: 48,
              ),
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _clearFilters();
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: AppColors.error.withAlpha(128),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.clear_all_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.getString('clearFilters', context),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Apply Filters Button
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxHeight: 48,
              ),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _applyFilters();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.getString('applyFilters', context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
    );
  }

  String _getPropertyTypeLabel(BuildContext context, String type) {
    final labels = {
      'apartment': AppStrings.getString('typeApartment', context),
      'studio': AppStrings.getString('typeStudio', context),
      'villa': AppStrings.getString('typeVilla', context),
      'riad': AppStrings.getString('typeRiad', context),
      'kasbah': AppStrings.getString('typeKasbah', context),
      'village_house': AppStrings.getString('typeVillageHouse', context),
      'desert_camp': AppStrings.getString('typeDesertCamp', context),
      'eco_lodge': AppStrings.getString('typeEcoLodge', context),
      'guesthouse': AppStrings.getString('typeGuesthouse', context),
      'hotel': AppStrings.getString('typeHotel', context),
      'resort': AppStrings.getString('typeResort', context),
    };

    return labels[type] ?? type;
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.zelligeGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _PropertyTypeSelector extends StatelessWidget {
  final String? selectedType;
  final List<String> allTypes;

  const _PropertyTypeSelector({
    required this.selectedType,
    required this.allTypes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  AppStrings.getString('accommodationTypes', context),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allTypes.length,
              itemBuilder: (context, index) {
                final type = allTypes[index];
                final isSelected = selectedType == type;

                return ListTile(
                  title: Text(
                    _getTypeLabel(context, type),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(BuildContext context, String type) {
    final labels = {
      'apartment': AppStrings.getString('typeApartment', context),
      'studio': AppStrings.getString('typeStudio', context),
      'villa': AppStrings.getString('typeVilla', context),
      'riad': AppStrings.getString('typeRiad', context),
      'kasbah': AppStrings.getString('typeKasbah', context),
      'village_house': AppStrings.getString('typeVillageHouse', context),
      'desert_camp': AppStrings.getString('typeDesertCamp', context),
      'eco_lodge': AppStrings.getString('typeEcoLodge', context),
      'guesthouse': AppStrings.getString('typeGuesthouse', context),
      'hotel': AppStrings.getString('typeHotel', context),
      'resort': AppStrings.getString('typeResort', context),
    };

    return labels[type] ?? type;
  }
}
