import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/services/analytics_service.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:godarna/screens/admin/user_management_screen.dart';
import 'package:godarna/screens/admin/property_management_screen.dart';
import 'package:godarna/screens/admin/booking_management_screen.dart';
import 'package:godarna/screens/admin/reports_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic> _platformStats = {};
  List<Map<String, dynamic>> _popularCities = [];
  List<Map<String, dynamic>> _popularPropertyTypes = [];
  List<Map<String, dynamic>> _bookingTrends = [];
  bool _isLoading = true;

  Future<void> _refreshRole() async {
    final auth = context.read<AuthProvider>();
    await auth.refreshUser();
    if (!mounted) return;
    if (auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الدور: مدير')),
      );
      _loadAdminData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا تزال الصلاحيات دون تغيير')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        auth.refreshUser().then((_) {
          if (!mounted) return;
          if (auth.isAdmin) {
            _loadAdminData();
          }
        });
      }
    });
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    try {
      final platformStats = await _analyticsService.getPlatformStats();
      final popularCities = await _analyticsService.getPopularCities();
      final popularPropertyTypes =
          await _analyticsService.getPopularPropertyTypes();
      final bookingTrends = await _analyticsService.getBookingTrends(7);

      if (!mounted) return;
      setState(() {
        _platformStats = platformStats;
        _popularCities = popularCities;
        _popularPropertyTypes = popularPropertyTypes;
        _bookingTrends = bookingTrends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل البيانات: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    if (!authProvider.isAuthenticated || !authProvider.isAdmin) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: const AppAppBar(title: 'الإدارة'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('غير مصرح لك بالوصول لهذه الصفحة',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: AppDimensions.space16),
              ElevatedButton.icon(
                onPressed: _refreshRole,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppDimensions.borderRadiusMedium),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الصلاحيات من الخادم'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppAppBar(
        title: 'لوحة الإدارة',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.refreshUser();
              if (mounted) await _loadAdminData();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final auth = context.read<AuthProvider>();
          await auth.refreshUser();
          if (mounted) await _loadAdminData();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppDimensions.paddingAll20,
                child: Column(
                  children: [
                    // === 1. Platform Overview ===
                    _buildPlatformOverview(),
                    const SizedBox(height: AppDimensions.space20),

                    // === 2. Statistics Grid ===
                    _buildStatisticsGrid(),
                    const SizedBox(height: AppDimensions.space20),

                    // === 3. Popular Cities ===
                    _buildPopularCities(),
                    const SizedBox(height: AppDimensions.space20),

                    // === 4. Popular Property Types ===
                    _buildPopularPropertyTypes(),
                    const SizedBox(height: AppDimensions.space20),

                    // === 5. Booking Trends Chart ===
                    _buildBookingTrends(),
                    const SizedBox(height: AppDimensions.space20),

                    // === 6. Admin Actions ===
                    _buildAdminActions(),
                    const SizedBox(height: AppDimensions.space40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlatformOverview() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppDimensions.paddingAll20,
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(15),
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.primary.withAlpha(26)),
      ),
      child: Row(
        children: [
          Container(
            padding: AppDimensions.paddingAll12,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(26),
              borderRadius: AppDimensions.borderRadiusMedium,
            ),
            child:
                Icon(Icons.admin_panel_settings, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظرة عامة على المنصة',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'إحصائيات شاملة لجميع المستخدمين والعقارات',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final cs = Theme.of(context).colorScheme;
    final items = [
      _buildStatCard('إجمالي المستخدمين',
          '${_platformStats['totalUsers'] ?? 0}', Icons.people, cs.primary),
      _buildStatCard('إجمالي العقارات',
          '${_platformStats['totalProperties'] ?? 0}', Icons.home, cs.tertiary),
      _buildStatCard(
          'إجمالي الحجوزات',
          '${_platformStats['totalBookings'] ?? 0}',
          Icons.bookmark,
          cs.secondary),
      _buildStatCard(
          'إجمالي الإيرادات',
          '${NumberFormat('#,###').format(_platformStats['totalRevenue'] ?? 0)} درهم',
          Icons.attach_money,
          const Color(0xFFFF3A44)), // Airbnb Red
    ];

    return Wrap(
      spacing: AppDimensions.space16,
      runSpacing: AppDimensions.space16,
      children: items
          .map((w) => SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 2, child: w))
          .toList(),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppDimensions.paddingAll12,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: AppDimensions.borderRadiusMedium,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCities() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppDimensions.paddingAll20,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المدن الأكثر شعبية',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_popularCities.isEmpty)
            Center(
              child: Text(
                'لا توجد بيانات متاحة',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _popularCities.length,
              itemBuilder: (context, index) {
                final city = _popularCities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primary.withAlpha(38),
                    child: Text('${index + 1}',
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(city['city'] ?? ''),
                  trailing: Container(
                    padding: AppDimensions.paddingSymmetric12x6,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: AppDimensions.borderRadiusXLarge,
                    ),
                    child: Text(
                      '${city['count']}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPopularPropertyTypes() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppDimensions.paddingAll20,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أنواع العقارات الأكثر شعبية',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_popularPropertyTypes.isEmpty)
            Center(
              child: Text(
                'لا توجد بيانات متاحة',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _popularPropertyTypes.length,
              itemBuilder: (context, index) {
                final type = _popularPropertyTypes[index];
                return ListTile(
                  leading: Icon(_getPropertyTypeIcon(type['type']),
                      color: cs.primary),
                  title: Text(_getPropertyTypeName(type['type'])),
                  subtitle: Text('${type['percentage'].toStringAsFixed(1)}%'),
                  trailing: Text(
                    '${type['count']}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBookingTrends() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppDimensions.paddingAll20,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اتجاهات الحجوزات (آخر 7 أيام)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_bookingTrends.isEmpty)
            Center(
              child: Text(
                'لا توجد بيانات متاحة',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _bookingTrends.length,
                itemBuilder: (context, index) {
                  final trend = _bookingTrends[index];
                  final max = _getMaxBookings();
                  final factor = max == 0
                      ? 0.0
                      : (trend['bookings'] as int).toDouble() / max.toDouble();
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: 40,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withAlpha(26),
                              borderRadius: AppDimensions.borderRadiusSmall,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: factor,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF3A44), // Airbnb Red
                                  borderRadius: AppDimensions.borderRadiusSmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Text(
                          trend['date'].split('-').last,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          '${trend['bookings']}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppDimensions.paddingAll20,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات الإدارة',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('إدارة المستخدمين'),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UserManagementScreen())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('إدارة العقارات'),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PropertyManagementScreen())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bookmark),
                  label: const Text('إدارة الحجوزات'),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BookingManagementScreen())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text('التقارير'),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPropertyTypeIcon(String type) {
    return switch (type) {
      'apartment' => Icons.apartment,
      'villa' => Icons.villa,
      'riad' => Icons.house,
      'studio' => Icons.single_bed,
      _ => Icons.home,
    };
  }

  String _getPropertyTypeName(String type) {
    return switch (type) {
      'apartment' => 'شقة',
      'villa' => 'فيلا',
      'riad' => 'رياض',
      'studio' => 'استوديو',
      _ => type,
    };
  }

  int _getMaxBookings() {
    if (_bookingTrends.isEmpty) return 0;
    return _bookingTrends.map((t) => t['bookings'] as int).reduce(math.max);
  }
}
