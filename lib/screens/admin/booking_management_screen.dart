import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/services/admin_service.dart';
import 'package:godarna/utils/csv_exporter.dart';
import 'package:godarna/widgets/admin/admin_search_bar.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _mutating = false;
  final int _pageSize = 20;
  int _offset = 0;
  int _total = 0;
  String? _status;
  DateTime? _from;
  DateTime? _to;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _load(reset: true));
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial =
        isFrom ? (_from ?? now) : (_to ?? now.add(const Duration(days: 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
    _load(reset: true);
  }

  Future<void> _clearDates() async {
    setState(() {
      _from = null;
      _to = null;
    });
    await _load(reset: true);
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
      final res = await _adminService.listBookings(
        search: _searchCtrl.text.trim(),
        status: _status,
        from: _from,
        to: _to,
        limit: _pageSize,
        offset: _offset,
      );
      final items = List<Map<String, dynamic>>.from(res['items'] ?? []);
      final total = (res['total'] ?? 0) as int;
      if (!mounted) return;
      setState(() {
        _total = total;
        _items = reset ? items : [..._items, ...items];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      dev.log('Load bookings failed: $e', name: 'BookingManagement');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحميل الحجوزات: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_items.length >= _total || _loading) return;
    setState(() => _offset += _pageSize);
    await _load();
  }

  Future<void> _changeStatus(Map<String, dynamic> b, String status) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await _adminService.setBookingStatus(bookingId: b['id'], status: status);
      if (!mounted) return;
      setState(() => b['status'] = status);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الحجز')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر التحديث: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'إدارة الحجوزات',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: () => _load(reset: true),
          ),
          IconButton(
            tooltip: 'تصدير CSV',
            icon: const Icon(AppIcons.download),
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildFilters(),
              ),
            ),
            if (_loading && _items.isEmpty)
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
                    final b = _items[index];
                    return _buildBookingTile(b);
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
    String statusLabel(String? s) {
      switch (s) {
        case 'pending':
          return 'قيد الانتظار';
        case 'confirmed':
          return 'مؤكد';
        case 'completed':
          return 'مكتمل';
        case 'cancelled':
          return 'ملغى';
        default:
          return 'كل الحالات';
      }
    }

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: cs.onSurfaceVariant
                .withAlpha(25), // Using Colors.black for shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          AdminSearchBar(
            hint: 'بحث بعنوان العقار/بريد المستأجر/المضيف...',
            onSearch: (q) {
              _searchCtrl.text = q;
              _load(reset: true);
            },
          ),
          const SizedBox(height: AppDimensions.space8),
          Row(
            children: [
              Icon(AppIcons.filter, color: cs.onSurfaceVariant),
              const SizedBox(width: AppDimensions.space8),
              PopupMenuButton<String?>(
                tooltip: 'الحالة',
                initialValue: _status,
                onSelected: (v) {
                  setState(() => _status = v);
                  _load(reset: true);
                },
                itemBuilder: (BuildContext context) => const [
                  PopupMenuItem(value: null, child: Text('كل الحالات')),
                  PopupMenuItem(
                    value: 'pending',
                    child: Row(children: [
                      Icon(AppIcons.pending, size: 16),
                      SizedBox(width: 8),
                      Text('قيد الانتظار')
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'confirmed',
                    child: Row(children: [
                      Icon(AppIcons.confirmed, size: 16),
                      SizedBox(width: 8),
                      Text('مؤكد')
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'completed',
                    child: Row(children: [
                      Icon(AppIcons.confirmed, size: 16),
                      SizedBox(width: 8),
                      Text('مكتمل')
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'cancelled',
                    child: Row(children: [
                      Icon(AppIcons.cancelled, size: 16),
                      SizedBox(width: 8),
                      Text('ملغى')
                    ]),
                  ),
                ],
                child: Chip(
                  label: Text(statusLabel(_status)),
                  backgroundColor: const Color(0xFFD62F26).withAlpha(
                      (0.08 * 255).toInt()), // Using primary color with alpha
                  avatar: const Icon(AppIcons.filter, size: 16),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _pickDate(isFrom: true),
                icon: const Icon(AppIcons.dateRange),
                label: Text(
                  _from == null
                      ? 'من تاريخ'
                      : _from!.toLocal().toIso8601String().split('T').first,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              TextButton.icon(
                onPressed: () => _pickDate(isFrom: false),
                icon: const Icon(AppIcons.calendar),
                label: Text(
                  _to == null
                      ? 'إلى تاريخ'
                      : _to!.toLocal().toIso8601String().split('T').first,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'مسح التواريخ',
                onPressed: _clearDates,
                icon: const Icon(AppIcons.clear),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTile(Map<String, dynamic> b) {
    final title = b['property_title']?.toString() ?? '';
    final tenant = b['tenant_email']?.toString() ?? '';
    final host = b['host_email']?.toString() ?? '';
    final status = b['status']?.toString() ?? '';
    final checkIn = DateTime.tryParse(b['check_in']?.toString() ?? '');
    final checkOut = DateTime.tryParse(b['check_out']?.toString() ?? '');
    final dates = (checkIn != null && checkOut != null)
        ? '${checkIn.toLocal().toIso8601String().split('T').first} → ${checkOut.toLocal().toIso8601String().split('T').first}'
        : '';

    final cs = Theme.of(context).colorScheme;

    Color statusColor() {
      return switch (status) {
        'confirmed' => cs.primary,
        'completed' => cs.secondary,
        'cancelled' => cs.error,
        'pending' || _ => cs.tertiary,
      };
    }

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: cs.onSurfaceVariant
                .withAlpha(25), // Using Colors.black for shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.bookings, color: cs.primary),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              PopupMenuButton<String>(
                tooltip: 'تغيير الحالة',
                onSelected: (v) => _changeStatus(b, v),
                itemBuilder: (BuildContext context) => const [
                  PopupMenuItem(
                    value: 'pending',
                    child: Row(children: [
                      Icon(AppIcons.pending, size: 16),
                      SizedBox(width: 8),
                      Text('قيد الانتظار')
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'confirmed',
                    child: Row(children: [
                      Icon(AppIcons.confirmed, size: 16),
                      SizedBox(width: 8),
                      Text('مؤكد')
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'completed',
                    child: Row(children: [
                      Icon(AppIcons.confirmed, size: 16),
                      SizedBox(width: 8),
                      Text('مكتمل')
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'cancelled',
                    child: Row(children: [
                      Icon(AppIcons.cancelled, size: 16),
                      SizedBox(width: 8),
                      Text('ملغى')
                    ]),
                  ),
                ],
                child: Chip(
                  label: Text(status),
                  backgroundColor: statusColor().withAlpha(30),
                  labelStyle: TextStyle(
                      color: statusColor(), fontWeight: FontWeight.w600),
                  avatar: _mutating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space6),
          Row(
            children: [
              Icon(AppIcons.calendar, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: AppDimensions.space4),
              Text(dates, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppDimensions.space6),
          Row(
            children: [
              Icon(AppIcons.profile, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: AppDimensions.space4),
              Expanded(
                child: Text('مستأجر: $tenant',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(width: AppDimensions.space8),
              Icon(AppIcons.home, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: AppDimensions.space4),
              Expanded(
                child: Text('مضيف: $host',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    if (_items.length >= _total) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: ElevatedButton.icon(
        onPressed: _loadMore,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: const RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusMedium),
        ),
        icon: _loading
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator())
            : const Icon(AppIcons.expand),
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
        final res = await _adminService.listBookings(
          search: _searchCtrl.text.trim(),
          status: _status,
          from: _from,
          to: _to,
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
          'property_title',
          'tenant_email',
          'host_email',
          'status',
          'check_in',
          'check_out',
          'total_price',
          'created_at'
        ],
        headers: const {
          'id': 'المعرف',
          'property_title': 'العقار',
          'tenant_email': 'المستأجر',
          'host_email': 'المضيف',
          'status': 'الحالة',
          'check_in': 'تسجيل الدخول',
          'check_out': 'تسجيل الخروج',
          'total_price': 'الإجمالي',
          'created_at': 'أُنشئ في',
        },
      );
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تصدير CSV'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: SelectableText(csv, style: const TextStyle(fontSize: 12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('تم نسخ CSV إلى الحافظة')),
                );
              },
              icon: const Icon(AppIcons.copy),
              label: const Text('نسخ'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التصدير: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
