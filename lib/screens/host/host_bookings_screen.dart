import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/booking_provider.dart';
import 'package:godarna/models/booking_model.dart';
import 'package:godarna/screens/booking/booking_details_screen.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/mixins/realtime_mixin.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.completed,
    required this.revenue,
  });

  final int total;
  final int pending;
  final int confirmed;
  final int completed;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item('إجمالي', total.toString(), Colors.black),
          _item('معلق', pending.toString(), Colors.orange),
          _item('مؤكد', confirmed.toString(), Colors.green),
          _item('مكتمل', completed.toString(), Colors.blue),
          _item('إيرادات', '${revenue.toStringAsFixed(0)} درهم', primaryColor),
        ],
      ),
    );
  }

  Widget _item(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _HostBookingsScreenState extends State<HostBookingsScreen>
    with SingleTickerProviderStateMixin, RealtimeMixin {
  late TabController _tabController;
  final primaryColor = const Color(0xFFFF3A44);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final hostId =
          auth.currentUser?.id ?? Supabase.instance.client.auth.currentUser?.id;
      if (hostId != null && hostId.isNotEmpty) {
        await context.read<BookingProvider>().fetchHostBookings(hostId);
        _setupRealtimeSubscriptions();
      }
    });
  }

  void _setupRealtimeSubscriptions() {
    final auth = context.read<AuthProvider>();
    final hostId = auth.currentUser?.id ?? Supabase.instance.client.auth.currentUser?.id;
    
    if (hostId == null || hostId.isEmpty) return;

    // اشتراك في تحديثات الحجوزات للمضيف الحالي
    subscribeToTable(
      table: 'bookings',
      filter: 'host_id',
      filterValue: hostId,
      onInsert: (payload) {
        if (mounted) {
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings(forceRefresh: true);
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings(forceRefresh: true);
        }
      },
      onDelete: (payload) {
        if (mounted) {
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings(forceRefresh: true);
        }
      },
    );
  }

  @override
  void dispose() {
    unsubscribeAll();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: AppStrings.getString('hostBookings', context),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'معلق'),
            Tab(text: 'مؤكد'),
            Tab(text: 'مكتمل'),
            Tab(text: 'ملغى'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          final all = bookingProvider.hostBookings;
          final pending = all.where((b) => b.status == 'pending').toList();
          final confirmed = all.where((b) => b.status == 'confirmed').toList();
          final completed = all.where((b) => b.status == 'completed').toList();
          final cancelled = all.where((b) => b.status == 'cancelled').toList();

          return Column(
            children: [
              _StatsHeader(
                total: all.length,
                pending: pending.length,
                confirmed: confirmed.length,
                completed: completed.length,
                revenue: all
                    .where((b) => b.isPaid)
                    .fold<double>(0.0, (sum, b) => sum + b.totalPrice),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(context, pending, 'pending'),
                    _buildList(context, confirmed, 'confirmed'),
                    _buildList(context, completed, 'completed'),
                    _buildList(context, cancelled, 'cancelled'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<BookingModel> items, String status) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_statusIcon(status), size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _emptyText(context, status),
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        final hostId = auth.currentUser?.id ??
            Supabase.instance.client.auth.currentUser?.id;
        if (hostId != null) {
          await context.read<BookingProvider>().fetchHostBookings(hostId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BookingDetailsScreen(bookingId: items[index].id),
                ),
              );
            },
            child: _BookingCard(
              booking: items[index],
              onConfirm: (id) => _confirm(id),
              onCancel: (id) => _cancel(id),
              onComplete: (id) => _complete(id),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(String id) async {
    final provider = context.read<BookingProvider>();
    final ok = await provider.confirmBooking(id);
    if (!mounted) return;
    _showSnack(ok ? 'تم تأكيد الحجز' : 'فشل التأكيد');
  }

  Future<void> _cancel(String id) async {
    final provider = context.read<BookingProvider>();
    final ok = await provider.cancelBooking(id);
    if (!mounted) return;
    _showSnack(ok ? 'تم الإلغاء' : 'فشل الإلغاء');
  }

  Future<void> _complete(String id) async {
    final provider = context.read<BookingProvider>();
    final ok = await provider.completeBooking(id);
    if (!mounted) return;
    _showSnack(ok ? 'تم الإكمال' : 'فشل الإكمال');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF3A44)),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.verified;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.bookmark_outline;
    }
  }

  String _emptyText(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return AppStrings.getString('noPendingHostBookings', context);
      case 'confirmed':
        return AppStrings.getString('noConfirmedHostBookings', context);
      case 'completed':
        return AppStrings.getString('noCompletedHostBookings', context);
      case 'cancelled':
        return AppStrings.getString('noCancelledHostBookings', context);
      default:
        return AppStrings.getString('noBookings', context);
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
  });

  final BookingModel booking;
  final Future<void> Function(String id) onConfirm;
  final Future<void> Function(String id) onCancel;
  final Future<void> Function(String id) onComplete;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'حجز #${booking.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: Text(
                        _statusText(context, booking.status),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: _statusColor(booking.status),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('d MMM').format(booking.checkIn),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Text(' - ', style: TextStyle(fontSize: 14)),
                    Text(
                      DateFormat('d MMM').format(booking.checkOut),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.nights_stay, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${booking.nights} ليلة',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payments, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${booking.totalPrice.toStringAsFixed(2)} درهم',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(booking.paymentStatusDisplay,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white)),
                      backgroundColor: _paymentColor(booking.paymentStatus),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (booking.status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onConfirm(booking.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('تأكيد',
                          style: TextStyle(color: Colors.green)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCancel(booking.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('رفض',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ] else if (booking.status == 'confirmed') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onComplete(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إكمال',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCancel(booking.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إلغاء',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailsScreen(bookingId: booking.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('التفاصيل',
                          style: TextStyle(color: Colors.white)),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _paymentColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return AppStrings.getString('pending', context);
      case 'confirmed':
        return AppStrings.getString('confirmed', context);
      case 'cancelled':
        return AppStrings.getString('cancelled', context);
      case 'completed':
        return AppStrings.getString('completed', context);
      default:
        return status;
    }
  }
}
