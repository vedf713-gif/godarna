import 'package:flutter/material.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:provider/provider.dart';
import 'package:godarna/providers/booking_provider.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:intl/intl.dart';
import 'package:godarna/widgets/skeleton.dart';
import 'package:godarna/widgets/empty_state.dart';
import 'package:godarna/screens/booking/booking_details_screen.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with RealtimeMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id;
      if (userId != null) {
        Provider.of<BookingProvider>(context, listen: false)
            .fetchUserBookings(userId);
        _setupRealtimeSubscriptions(userId);
      }
    });
  }

  void _setupRealtimeSubscriptions(String userId) {
    // اشتراك في تحديثات الحجوزات للمستأجر
    subscribeToTable(
      table: 'bookings',
      filter: 'tenant_id',
      filterValue: userId,
      onInsert: (payload) {
        if (mounted) {
          final provider = context.read<BookingProvider>();
          provider.fetchUserBookings(userId);
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final provider = context.read<BookingProvider>();
          provider.fetchUserBookings(userId);
        }
      },
      onDelete: (payload) {
        if (mounted) {
          final provider = context.read<BookingProvider>();
          provider.fetchUserBookings(userId);
        }
      },
    );

    // اشتراك في تحديثات الحجوزات للمضيف
    subscribeToTable(
      table: 'bookings',
      filter: 'host_id',
      filterValue: userId,
      onInsert: (payload) {
        if (mounted) {
          final provider = context.read<BookingProvider>();
          provider.fetchUserBookings(userId);
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final provider = context.read<BookingProvider>();
          provider.fetchUserBookings(userId);
        }
      },
      onDelete: (payload) {
        if (mounted) {
          final provider = context.read<BookingProvider>();
          provider.fetchUserBookings(userId);
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    const primaryColor = Color(0xFFFF3A44); // Airbnb Red

    if (!authProvider.isAuthenticated) {
      return _buildNotAuthenticated();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: AppStrings.getString('bookings', context),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: AppStrings.getString('upcoming', context)),
            Tab(text: AppStrings.getString('active', context)),
            Tab(text: AppStrings.getString('completed', context)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('upcoming'),
          _buildBookingsList('active'),
          _buildBookingsList('completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ميزة إنشاء حجز جديد قيد التطوير')),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotAuthenticated() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(title: AppStrings.getString('bookings', context)),
      body: Center(
        child: EmptyState(
          title: AppStrings.getString('loginRequired', context),
          message: AppStrings.getString('pleaseLoginToContinue', context),
          icon: Icons.lock_outline,
          actionLabel: AppStrings.getString('login', context),
          onAction: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
      ),
    );
  }

  Widget _buildBookingsList(String status) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonList(itemCount: 3, itemHeight: 140),
          );
        }

        List<dynamic> bookings;
        switch (status) {
          case 'upcoming':
            bookings = bookingProvider.upcomingBookings;
            break;
          case 'active':
            bookings = bookingProvider.activeBookings;
            break;
          case 'completed':
            bookings = bookingProvider.completedBookings;
            break;
          default:
            bookings = [];
        }

        if (bookings.isEmpty) {
          return EmptyState(
            title: _getEmptyMessage(status),
            message: null,
            icon: _getStatusIcon(status),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingDetailsScreen(bookingId: booking.id),
                    ),
                  );
                },
                child: _buildBookingCard(booking, status),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingCard(dynamic booking, String status) {
    const primaryColor = Color(0xFFFF3A44);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header: Image + Title + Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // صورة العقار
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 60,
                    color: primaryColor.withAlpha((0.1 * 255).toInt()),
                    child: const Icon(Icons.home, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عقار محجوز',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'حجز #${booking.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF3A44),
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    _getStatusText(booking.status),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(booking.status),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Booking Details
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha((0.05 * 255).toInt()),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailItem(Icons.calendar_today, 'وصول',
                        DateFormat('d MMM').format(booking.checkIn)),
                    _buildDetailItem(Icons.calendar_today, 'مغادرة',
                        DateFormat('d MMM').format(booking.checkOut)),
                    _buildDetailItem(
                        Icons.nights_stay, 'ليالٍ', '${booking.nights}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      '${booking.totalPrice.toStringAsFixed(2)} درهم',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF3A44),
                      ),
                    ),
                  ],
                ),

                // Actions
                if (status == 'upcoming' && booking.status == 'confirmed') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(booking.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('إلغاء',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('التفاصيل',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],

                if (status == 'completed' && booking.rating == null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showReviewDialog(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('أضف تقييمك',
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

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF3A44)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'upcoming':
        return Icons.schedule;
      case 'active':
        return Icons.home;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.bookmark;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'upcoming':
        return AppStrings.getString('noUpcomingBookings', context);
      case 'active':
        return AppStrings.getString('noActiveBookings', context);
      case 'completed':
        return AppStrings.getString('noCompletedBookings', context);
      default:
        return AppStrings.getString('noBookings', context);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF6B35);
      case 'confirmed':
        return const Color(0xFF00D1B2);
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF1E90FF);
    }
  }

  String _getStatusText(String status) {
    return AppStrings.getString(status, context);
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.getString('cancelBooking', context)),
        content: Text(AppStrings.getString('cancelBookingConfirm', context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.getString('cancel', context)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final bookingProvider =
                    Provider.of<BookingProvider>(context, listen: false);
                await bookingProvider.updateBookingStatus(
                    bookingId, 'cancelled');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إلغاء الحجز بنجاح'),
                      backgroundColor: Color(0xFF00D1B2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(AppStrings.getString('confirm', context)),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(String bookingId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ميزة التقييم قيد التطوير'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}
