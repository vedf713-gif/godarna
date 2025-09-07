import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:godarna/services/clipboard.dart';
import 'package:godarna/services/admin_service.dart';
import 'package:godarna/utils/csv_exporter.dart';
import 'package:godarna/widgets/admin/admin_search_bar.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/theme/app_dimensions.dart';

class PropertyManagementScreen extends StatefulWidget {
  const PropertyManagementScreen({super.key});

  @override
  State<PropertyManagementScreen> createState() =>
      _PropertyManagementScreenState();
}

class _PropertyManagementScreenState extends State<PropertyManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _mutating = false;
  final int _pageSize = 20;
  int _offset = 0;
  int _total = 0;
  bool? _filterActive;
  bool? _filterVerified;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
    _searchCtrl.addListener(_onSearchChanged);
    _cityCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _offset = 0;
        _items = [];
      });
    }
    try {
      final res = await _adminService.listProperties(
        search: _searchCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        isActive: _filterActive,
        isVerified: _filterVerified,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      final items = List<Map<String, dynamic>>.from(res['items'] ?? []);
      final total = (res['total'] ?? 0) as int;
      setState(() {
        _total = total;
        _items = reset ? items : [..._items, ...items];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      dev.log('Load properties failed: $e', name: 'PropertyManagement');
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل تحميل العقارات: $e'), backgroundColor: cs.error),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_items.length >= _total) return;
    setState(() => _offset += _pageSize);
    await _load();
  }

  Future<void> _toggleActive(Map<String, dynamic> p, bool value) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await _adminService.setPropertyActive(
          propertyId: p['id'], isActive: value);
      if (!mounted) return;
      setState(() => p['is_active'] = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'تم تفعيل العقار' : 'تم تعطيل العقار')),
      );
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر التحديث: $e'), backgroundColor: cs.error),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _toggleVerified(Map<String, dynamic> p, bool value) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await _adminService.setPropertyVerified(
          propertyId: p['id'], isVerified: value);
      if (!mounted) return;
      setState(() => p['is_verified'] = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(value ? 'تم توثيق العقار' : 'تم إلغاء توثيق العقار')),
      );
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر التحديث: $e'), backgroundColor: cs.error),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppAppBar(
        title: 'إدارة العقارات',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(reset: true),
          ),
          IconButton(
            tooltip: 'تصدير CSV',
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppDimensions.paddingAll16,
                child: _buildFilters(),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('لا توجد نتائج')),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _items.length) return _buildLoadMore();
                    final p = _items[index];
                    return _buildPropertyTile(p);
                  },
                  childCount: _items.length + (_items.length < _total ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppDimensions.paddingAll12,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha((0.08 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AdminSearchBar(
            hint: 'بحث بالعنوان/المدينة/بريد المضيف...',
            onSearch: (q) {
              _searchCtrl.text = q;
              _load(reset: true);
            },
          ),
          const SizedBox(height: AppDimensions.space8),
          Row(
            children: [
              Icon(Icons.location_city, color: cs.onSurfaceVariant),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: TextField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(
                    hintText: 'فلترة حسب المدينة (اختياري)',
                    border: InputBorder.none,
                  ),
                ),
              ),
              PopupMenuButton<bool?>(
                tooltip: 'الحالة',
                icon:
                    Icon(Icons.power_settings_new, color: cs.onSurfaceVariant),
                onSelected: (v) {
                  setState(() => _filterActive = v);
                  _load(reset: true);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: null, child: Text('الكل')),
                  PopupMenuItem(value: true, child: Text('مفعّل')),
                  PopupMenuItem(value: false, child: Text('غير مفعّل')),
                ],
              ),
              const SizedBox(width: AppDimensions.space8),
              PopupMenuButton<bool?>(
                tooltip: 'التوثيق',
                icon: Icon(Icons.verified, color: cs.onSurfaceVariant),
                onSelected: (v) {
                  setState(() => _filterVerified = v);
                  _load(reset: true);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: null, child: Text('الكل')),
                  PopupMenuItem(value: true, child: Text('موثّق')),
                  PopupMenuItem(value: false, child: Text('غير موثّق')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTile(Map<String, dynamic> p) {
    final title = (p['title'] ?? '').toString();
    final city = (p['city'] ?? '').toString();
    final price = (p['price_per_night'] ?? 0).toString();
    final hostEmail = (p['host_email'] ?? '').toString();
    final isActive = (p['is_active'] ?? true) as bool;
    final isVerified = (p['is_verified'] ?? false) as bool;

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: AppDimensions.paddingSymmetric16x8,
      padding: AppDimensions.paddingAll12,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha((0.08 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha((0.08 * 255).toInt()),
              borderRadius: AppDimensions.borderRadiusMedium,
            ),
            child: Icon(Icons.home, color: cs.primary),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Text(
                      '$price د.م/ليلة',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: cs.onSurfaceVariant.withAlpha((0.8 * 255).toInt()),
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Icon(
                      Icons.alternate_email,
                      size: 14,
                      color: cs.onSurfaceVariant.withAlpha((0.8 * 255).toInt()),
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Expanded(
                      child: Text(
                        hostEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('موثّق'),
                      selected: isVerified,
                      onSelected: (v) => _toggleVerified(p, v),
                      selectedColor: cs.primary.withAlpha((0.15 * 255).toInt()),
                      labelStyle: TextStyle(
                        color: isVerified ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Row(
                      children: [
                        const Text('مفعّل'),
                        Switch(
                          value: isActive,
                          activeColor: cs.primary,
                          onChanged: (v) => _toggleActive(p, v),
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
    );
  }

  Widget _buildLoadMore() {
    final canLoad = _items.length < _total;
    if (!canLoad) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ElevatedButton.icon(
        onPressed: _loadMore,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD62F26), // primaryRed
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        icon: const Icon(Icons.expand_more),
        label: const Text('تحميل المزيد'),
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final all = <Map<String, dynamic>>[];
      int offset = 0;
      const step = 200;
      while (true) {
        final res = await _adminService.listProperties(
          search: _searchCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          isActive: _filterActive,
          isVerified: _filterVerified,
          limit: step,
          offset: offset,
        );
        final items = List<Map<String, dynamic>>.from(res['items'] ?? []);
        all.addAll(items);
        final total = (res['total'] ?? all.length) as int;
        offset += step;
        if (all.length >= total || items.isEmpty) break;
      }
      if (!mounted) return;
      final csv = CsvExporter.toCsv(
        all,
        columns: const [
          'id',
          'title',
          'city',
          'price_per_night',
          'host_email',
          'is_active',
          'is_verified',
          'created_at'
        ],
        headers: const {
          'id': 'المعرف',
          'title': 'العنوان',
          'city': 'المدينة',
          'price_per_night': 'السعر/ليلة',
          'host_email': 'بريد المضيف',
          'is_active': 'مفعّل',
          'is_verified': 'موثّق',
          'created_at': 'أُنشئ في',
        },
      );
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تصدير CSV'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(child: SelectableText(csv)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ CSV إلى الحافظة')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('نسخ'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التصدير: $e'), backgroundColor: cs.error),
      );
    }
  }
}
