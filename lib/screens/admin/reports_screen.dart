import 'package:flutter/material.dart';
import 'package:godarna/services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:godarna/utils/csv_exporter.dart';
import 'package:flutter/services.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/theme/app_dimensions.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ColorScheme get cs => Theme.of(context).colorScheme;
  final AnalyticsService _analytics = AnalyticsService();
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _platformStats = {};
  List<Map<String, dynamic>> _bookingTrends = [];
  List<Map<String, dynamic>> _revenueTrends = [];
  List<Map<String, dynamic>> _popularTypes = [];
  Map<String, int> _statusCounts = {};
  int _days = 14;
  bool _showRevenue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _statusLabel(String key) {
    switch (key) {
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد المعالجة';
      default:
        return key;
    }
  }

  Future<void> _exportTrendsCsv() async {
    final list = _showRevenue ? _revenueTrends : _bookingTrends;
    if (list.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للتصدير حالياً')),
      );
      return;
    }

    final rows = list
        .map<Map<String, dynamic>>((e) => {
              'date': e['date'],
              _showRevenue ? 'revenue' : 'bookings':
                  _showRevenue ? (e['revenue'] ?? 0.0) : (e['bookings'] ?? 0),
            })
        .toList();

    final headers = {
      'date': 'التاريخ',
      'bookings': 'عدد الحجوزات',
      'revenue': 'الإيرادات',
    };
    final columns = ['date', _showRevenue ? 'revenue' : 'bookings'];
    final csv = CsvExporter.toCsv(rows, columns: columns, headers: headers);
    if (!mounted) return;
    _showCsvDialog(csv,
        title: _showRevenue
            ? 'تصدير اتجاهات الإيرادات (آخر $_days يومًا)'
            : 'تصدير اتجاهات الحجوزات (آخر $_days يومًا)');
  }

  Future<void> _showCsvDialog(String csv, {required String title}) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusLarge),
          title: Text(title),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: AppDimensions.paddingAll12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha((0.08 * 255).toInt()),
                    borderRadius: AppDimensions.borderRadiusMedium,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      csv,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                if (!context.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ CSV إلى الحافظة')),
                );
              },
              child: const Text('نسخ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _analytics.getPlatformStats();
      final trends = await _analytics.getBookingTrends(_days);
      final rev = await _analytics.getRevenueTrends(_days);
      final types = await _analytics.getPopularPropertyTypes();
      final status = await _analytics.getBookingStatusCounts(_days);
      if (!mounted) return;
      setState(() {
        _platformStats = stats;
        _bookingTrends = trends;
        _revenueTrends = rev;
        _popularTypes = types;
        _statusCounts = status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppAppBar(
        title: 'التقارير والتحليلات',
        actions: [
          _DaysFilter(
            selected: _days,
            onChanged: (v) {
              setState(() => _days = v);
              _load();
            },
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cs.onPrimary.withAlpha((0.12 * 255).toInt()),
              borderRadius: AppDimensions.borderRadiusMedium,
            ),
            child: ToggleButtons(
              isSelected: [!_showRevenue, _showRevenue],
              onPressed: (index) {
                setState(() => _showRevenue = index == 1);
              },
              borderRadius: AppDimensions.borderRadiusMedium,
              fillColor: cs.onPrimary.withAlpha((0.22 * 255).toInt()),
              selectedColor: cs.onPrimary,
              color: cs.onPrimary,
              constraints: const BoxConstraints(minHeight: 36, minWidth: 64),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('الحجوزات'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('الإيرادات'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'تصدير CSV',
            icon: const Icon(Icons.table_view),
            onPressed: _exportTrendsCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: AppDimensions.paddingAll20,
      children: [
        card(
          context,
          child: Row(
            children: [
              Icon(Icons.error_outline, color: cs.error),
              const SizedBox(width: 12),
              Expanded(child: Text('حدث خطأ أثناء تحميل التقارير: $_error')),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final totalUsers = (_platformStats['totalUsers'] ?? 0) as int;
    final totalProperties = (_platformStats['totalProperties'] ?? 0) as int;
    final totalBookings = (_platformStats['totalBookings'] ?? 0) as int;
    final totalRevenue = (_platformStats['totalRevenue'] ?? 0.0) as double;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final int createdTotal = _bookingTrends.fold<int>(
        0, (p, e) => p + ((e['bookings'] ?? 0) as int));
    final double periodRevenue = _revenueTrends.fold<double>(
        0.0, (p, e) => p + ((e['revenue'] ?? 0.0) as double));
    final int completedCount = _statusCounts['completed'] ?? 0;
    final int cancelledCount = _statusCounts['cancelled'] ?? 0;
    final int totalInPeriod =
        _statusCounts.values.fold<int>(0, (p, c) => p + c);
    final double aov = periodRevenue /
        (completedCount > 0
            ? completedCount
            : (createdTotal > 0 ? createdTotal : 1));
    final double cancelRate =
        totalInPeriod == 0 ? 0.0 : (cancelledCount / totalInPeriod) * 100.0;

    return ListView(
      padding: AppDimensions.paddingAll16,
      children: [
        // KPIs Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final cross = isWide ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 2.8 : 2.4,
              ),
              itemCount: 4,
              itemBuilder: (context, i) {
                final data = [
                  {
                    'title': 'المستخدمون',
                    'value': totalUsers.toString(),
                    'icon': Icons.people
                  },
                  {
                    'title': 'العقارات',
                    'value': totalProperties.toString(),
                    'icon': Icons.home_work
                  },
                  {
                    'title': 'الحجوزات',
                    'value': totalBookings.toString(),
                    'icon': Icons.receipt_long
                  },
                  {
                    'title': 'الإيرادات (د.م)',
                    'value': totalRevenue.toStringAsFixed(2),
                    'icon': Icons.payments
                  },
                ];
                final item = data[i];
                return kpiCard(
                  context,
                  item['title']! as String,
                  item['value']! as String,
                  item['icon']! as IconData,
                  subtitle: 'إجمالي',
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),

        // Booking/Revenue Chart
        card(
          context,
          title: _showRevenue ? 'اتجاهات الإيرادات' : 'اتجاهات الحجوزات',
          subtitle: 'القيم اليومية خلال آخر $_days يومًا',
          tooltip: _showRevenue
              ? 'المخطط يعرض مجموع الإيرادات لكل يوم خلال الفترة المحددة.'
              : 'المخطط يعرض عدد الحجوزات لكل يوم خلال الفترة المحددة.',
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        final list =
                            _showRevenue ? _revenueTrends : _bookingTrends;
                        if (i < 0 || i >= list.length) {
                          return const SizedBox.shrink();
                        }
                        final label = (list[i]['date'] as String)
                            .split('-')
                            .sublist(1)
                            .join('/');
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child:
                              Text(label, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  _showRevenue ? _revenueTrends.length : _bookingTrends.length,
                  (i) {
                    final v = _showRevenue
                        ? (_revenueTrends[i]['revenue'] ?? 0.0)
                        : (_bookingTrends[i]['bookings'] ?? 0).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: v,
                          color: cs.primary,
                          width: 12,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // AOV & Cancellation Rate
        Row(
          children: [
            Expanded(
              child: kpiCard(
                context,
                'متوسط قيمة الحجز (AOV)',
                aov.toStringAsFixed(2),
                Icons.stacked_line_chart,
                subtitle: 'آخر $_days يومًا',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: kpiCard(
                context,
                'معدل الإلغاء',
                '${cancelRate.toStringAsFixed(1)}%',
                Icons.cancel_schedule_send,
                subtitle: 'آخر $_days يومًا',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Status Distribution
        card(
          context,
          title: 'توزيع حالات الحجوزات',
          subtitle: 'حصة كل حالة من إجمالي الحجوزات خلال آخر $_days يومًا',
          tooltip: 'نسبة كل حالة من إجمالي الحجوزات.',
          child: SizedBox(
            height: 260,
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 44,
                          sections: _statusCounts.entries
                              .map((e) => PieChartSectionData(
                                    value: e.value.toDouble(),
                                    color: colorForStatus(context, e.key),
                                    title: '',
                                    radius: 72,
                                  ))
                              .toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'إجمالي',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withAlpha((0.7 * 255).toInt()),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalInPeriod',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _statusCounts.entries.map((e) {
                      final color = colorForStatus(context, e.key);
                      final label = _statusLabel(e.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withAlpha((0.6 * 255).toInt()),
                            borderRadius: AppDimensions.borderRadiusMedium,
                            border: Border.all(
                                color: color.withAlpha((0.18 * 255).toInt())),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: theme.dividerColor
                                          .withAlpha((0.12 * 255).toInt())),
                                ),
                                child: Text(
                                  e.value.toString(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Popular Types
        card(
          context,
          title: 'أنواع العقارات الشائعة',
          subtitle: 'النسب والتكرار لأنواع العقارات خلال آخر $_days يومًا',
          tooltip: 'النسبة المئوية لكل نوع من مجموع الحجوزات.',
          child: SizedBox(
            height: 260,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 44,
                      sections: _popularTypes.map((t) {
                        final value = (t['count'] ?? 0).toDouble();
                        final color =
                            colorForType(context, t['type'] ?? 'غير معرّف');
                        return PieChartSectionData(
                          value: value,
                          color: color,
                          title: '${t['count'] ?? 0}',
                          radius: 70,
                          titleStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _popularTypes.map((t) {
                      final type = (t['type'] ?? 'غير معرّف').toString();
                      final count = (t['count'] ?? 0).toString();
                      final color = colorForType(context, type);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              count,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withAlpha((0.7 * 255).toInt()),
                              ),
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
      ],
    );
  }
}

// === Widgets & Helpers ===

class _DaysFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _DaysFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color selectedColor = cs.primary;
    final Color unselectedBg = cs.surface.withAlpha((0.6 * 255).toInt());
    const TextStyle labelStyle = TextStyle(fontWeight: FontWeight.w600);

    Widget chip(int v) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ChoiceChip(
            label: Text('$v يوم', style: labelStyle),
            selected: selected == v,
            onSelected: (_) => onChanged(v),
            selectedColor: selectedColor.withAlpha((0.20 * 255).toInt()),
            backgroundColor: unselectedBg,
            side: BorderSide(
              color: selected == v
                  ? selectedColor.withAlpha((0.60 * 255).toInt())
                  : cs.shadow.withAlpha(0),
            ),
            shape: const RoundedRectangleBorder(
                borderRadius: AppDimensions.borderRadiusMedium),
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

    return Row(children: [chip(7), chip(14), chip(30)]);
  }
}

Color colorForStatus(BuildContext context, String status) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case 'completed':
      return cs.tertiary;
    case 'cancelled':
      return cs.error;
    case 'pending':
      return cs.secondary;
    case 'processing':
      return cs.primary;
    default:
      return cs.outline;
  }
}

Color colorForType(BuildContext context, String type) {
  final cs = Theme.of(context).colorScheme;
  final colors = [
    cs.primary,
    cs.secondary,
    cs.tertiary,
    cs.primaryContainer,
    cs.secondaryContainer,
    cs.tertiaryContainer,
    cs.outline,
  ];
  return colors[type.hashCode.abs() % colors.length];
}

Widget kpiCard(BuildContext context, String title, String value, IconData icon,
    {String? subtitle}) {
  final theme = Theme.of(context);
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: AppDimensions.paddingAll16,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface,
          theme.colorScheme.surface.withAlpha((0.96 * 255).toInt()),
        ],
      ),
      borderRadius: AppDimensions.borderRadiusLarge,
      border: Border.all(
          color: theme.colorScheme.outline.withAlpha((0.10 * 255).toInt())),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withAlpha((0.12 * 255).toInt()),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: AppDimensions.paddingAll12,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
            borderRadius: AppDimensions.borderRadiusMedium,
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color
                      ?.withAlpha((0.8 * 255).toInt()),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color
                        ?.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget card(BuildContext context,
    {String? title, String? subtitle, String? tooltip, Widget? child}) {
  final theme = Theme.of(context);
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface,
          theme.colorScheme.surface.withAlpha((0.96 * 255).toInt()),
        ],
      ),
      borderRadius: AppDimensions.borderRadiusLarge,
      border: Border.all(
          color: theme.colorScheme.outline.withAlpha((0.12 * 255).toInt())),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withAlpha((0.12 * 255).toInt()),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (tooltip != null)
                Tooltip(
                  message: tooltip,
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.textTheme.bodySmall?.color
                        ?.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 44,
            height: 3,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color
                    ?.withAlpha((0.8 * 255).toInt()),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
        if (child != null) child,
      ],
    ),
  );
}
