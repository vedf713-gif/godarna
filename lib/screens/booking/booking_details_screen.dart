import 'package:flutter/material.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:godarna/constants/app_colors.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/models/booking_model.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/booking_provider.dart';
import 'package:godarna/screens/payment/payment_screen.dart';
import 'package:godarna/screens/chat/chat_screen.dart';
import 'package:godarna/services/notifications_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> with RealtimeMixin {
  BookingModel? booking;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
    });
    _load();
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    // اشتراك في تحديثات الحجز المحدد
    subscribeToTable(
      table: 'bookings',
      filter: 'id',
      filterValue: widget.bookingId,
      onInsert: (payload) {
        if (mounted) {
          _load();
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          _load();
        }
      },
      onDelete: (payload) {
        if (mounted) {
          // الحجز تم حذفه - العودة للقائمة
          Navigator.of(context).pop();
        }
      },
    );

    // اشتراك في تحديثات الرسائل للحجز
    final chatId = 'booking_${widget.bookingId}';
    subscribeToTable(
      table: 'messages',
      filter: 'chat_id',
      filterValue: chatId,
      onInsert: (payload) {
        if (mounted) {
          // رسالة جديدة - يمكن إظهار إشعار
          setState(() {});
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          setState(() {});
        }
      },
      onDelete: (payload) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _shareBooking() {
    HapticFeedback.lightImpact();
    // Share.share('تفاصيل حجزي في GoDarna\nرقم الحجز: ${booking!.id}\nالتواريخ: ${DateFormat('d MMM').format(booking!.checkIn)} - ${DateFormat('d MMM').format(booking!.checkOut)}\nالإجمالي: ${booking!.displayTotalPrice}');
  }

  void _openChat() {
    HapticFeedback.lightImpact();
    // Create chat ID based on booking ID for consistency
    final chatId = 'booking_${widget.bookingId}';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          title: 'محادثة الحجز ${booking!.id.substring(0, 8)}',
        ),
      ),
    );
  }


  Future<void> _load() async {
    final prov = context.read<BookingProvider>();
    final result = await prov.getBookingById(widget.bookingId);
    if (!mounted) return;
    setState(() {
      booking = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundPrimaryDark
          : AppColors.backgroundPrimary,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            )
          : booking == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لم يتم العثور على الحجز',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontSize: 18,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // === Enhanced App Bar ===
                    SliverAppBar(
                      expandedHeight: 120,
                      pinned: true,
                      backgroundColor: isDark
                          ? AppColors.backgroundPrimaryDark
                          : AppColors.backgroundPrimary,
                      elevation: 0,
                      systemOverlayStyle: isDark
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundCardDark
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.1 * 255).toInt()),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            AppIcons.back,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                          iconSize: 20,
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundCardDark
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withAlpha((0.1 * 255).toInt()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _shareBooking,
                            icon: Icon(
                              Icons.share_outlined,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                            iconSize: 20,
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'تفاصيل الحجز',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        centerTitle: true,
                      ),
                    ),

                    // === Content ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // === 1. Booking Status Header ===
                            _buildStatusHeader(isDark),

                            const SizedBox(height: 24),

                            // === 2. Booking Timeline ===
                            _buildBookingTimeline(isDark),

                            const SizedBox(height: 24),

                            // === 3. Payment Information ===
                            _buildPaymentInfo(isDark),

                            const SizedBox(height: 24),

                            // === 4. Booking Details ===
                            _buildBookingDetails(isDark),

                            if (booking!.notes != null &&
                                booking!.notes!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildNotesSection(isDark),
                            ],

                            const SizedBox(height: 24),

                            // === 5. Chat Section ===
                            _buildChatSection(isDark),

                            const SizedBox(height: 24),

                            // === 6. Action Buttons ===
                            _buildActionButtons(auth, isDark),

                            const SizedBox(
                                height: 100), // Space for bottom actions
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

      // === Enhanced Bottom Action Bar ===
      bottomNavigationBar:
          booking != null ? _buildBottomActionBar(auth, isDark) : null,
    );
  }

  Future<void> _changeStatus(String status) async {
    final ok = await context
        .read<BookingProvider>()
        .updateBookingStatus(widget.bookingId, status);
    if (!mounted) return;
    if (ok) {
      // إرسال إشعارات عند تأكيد أو إكمال الحجز
      await _sendStatusUpdateNotification(status);

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم التحديث بنجاح'),
            backgroundColor: Color(0xFF00D1B2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addReview() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التقييم قيد التطوير')),
    );
  }

  Future<void> _sendStatusUpdateNotification(String newStatus) async {
    if (booking == null) return;

    try {
      final notificationService = NotificationsService();
      String title;
      String message;
      String notificationType;

      switch (newStatus) {
        case 'confirmed':
          title = '✅ تم تأكيد حجزك';
          message =
              'تم تأكيد حجزك رقم ${booking!.id.substring(0, 8)} بنجاح. يمكنك الآن الاستعداد لرحلتك!';
          notificationType = 'booking_confirmed';
          break;
        case 'completed':
          title = '🎉 تم إكمال الحجز';
          message =
              'تم إكمال حجزك رقم ${booking!.id.substring(0, 8)} بنجاح. نتمنى أن تكون قد استمتعت بإقامتك!';
          notificationType = 'booking_completed';
          break;
        case 'cancelled':
          title = '❌ تم إلغاء الحجز';
          message =
              'تم إلغاء حجزك رقم ${booking!.id.substring(0, 8)}. في حالة وجود أي استفسارات، يرجى التواصل معنا.';
          notificationType = 'booking_cancelled';
          break;
        default:
          return; // لا نرسل إشعار للحالات الأخرى
      }

      // إرسال إشعار للمستأجر
      await notificationService.sendNotification(
        userId: booking!.tenantId,
        title: title,
        message: message,
        type: notificationType,
        data: {
          'booking_id': booking!.id,
          'property_id': booking!.propertyId,
          'new_status': newStatus,
        },
      );

      // إرسال إشعار للمضيف أيضاً
      String hostTitle;
      String hostMessage;

      switch (newStatus) {
        case 'confirmed':
          hostTitle = '📋 تم تأكيد حجز';
          hostMessage =
              'تم تأكيد الحجز رقم ${booking!.id.substring(0, 8)} للضيف. تأكد من الاستعداد لاستقبال الضيف.';
          break;
        case 'completed':
          hostTitle = '✨ تم إكمال حجز';
          hostMessage =
              'تم إكمال الحجز رقم ${booking!.id.substring(0, 8)} بنجاح. يمكنك الآن طلب تقييم من الضيف.';
          break;
        case 'cancelled':
          hostTitle = '🔄 تم إلغاء حجز';
          hostMessage =
              'تم إلغاء الحجز رقم ${booking!.id.substring(0, 8)}. تم تحرير التواريخ وهي متاحة للحجز مرة أخرى.';
          break;
        default:
          return;
      }

      await notificationService.sendNotification(
        userId: booking!.hostId,
        title: hostTitle,
        message: hostMessage,
        type: notificationType,
        data: {
          'booking_id': booking!.id,
          'property_id': booking!.propertyId,
          'new_status': newStatus,
          'tenant_id': booking!.tenantId,
        },
      );
    } catch (e) {
      // لا نعرض خطأ للمستخدم لأن التحديث تم بنجاح
      debugPrint('خطأ في إرسال إشعار تحديث حالة الحجز: $e');
    }
  }

  Widget _buildStatusHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.backgroundCardDark, AppColors.backgroundTertiaryDark]
              : [Colors.white, AppColors.grey50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor(booking!.status)
                      .withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _statusIcon(booking!.status),
                  color: _statusColor(booking!.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حجز رقم ${booking!.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(booking!.status)
                            .withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor(booking!.status)
                              .withAlpha((0.3 * 255).toInt()),
                        ),
                      ),
                      child: Text(
                        booking!.statusDisplay,
                        style: TextStyle(
                          color: _statusColor(booking!.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withAlpha((0.05 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryRed.withAlpha((0.1 * 255).toInt()),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  booking!.displayTotalPrice,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }






  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.grey500;
    }
  }

  Color _paymentColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      case 'refunded':
        return AppColors.info;
      case 'processing':
        return AppColors.info;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  Widget _buildBookingTimeline(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.2 * 255).toInt())
                : AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.atlasBlue.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColors.atlasBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'جدول الحجز',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimelineItem(
                  'تاريخ الوصول',
                  DateFormat('d MMMM yyyy', 'ar').format(booking!.checkIn),
                  Icons.login_rounded,
                  AppColors.mintGreen,
                  isDark,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.mintGreen, AppColors.spiceOrange],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Expanded(
                child: _buildTimelineItem(
                  'تاريخ المغادرة',
                  DateFormat('d MMMM yyyy', 'ar').format(booking!.checkOut),
                  Icons.logout_rounded,
                  AppColors.spiceOrange,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundTertiaryDark : AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.nights_stay_rounded,
                    color: AppColors.royalPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${booking!.nights} ليلة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.2 * 255).toInt())
                : AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.saharaGold.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: AppColors.saharaGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات الدفع',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPaymentDetail(
                  'حالة الدفع',
                  booking!.paymentStatusDisplay,
                  _paymentColor(booking!.paymentStatus),
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPaymentDetail(
                  'طريقة الدفع',
                  booking!.paymentMethodDisplay,
                  AppColors.atlasBlue,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(
      String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.2 * 255).toInt())
                : AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.royalPurple.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: AppColors.royalPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل الحجز',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('رقم الحجز', booking!.id,
              Icons.confirmation_number_rounded, isDark),
          const SizedBox(height: 12),
          _buildDetailRow(
              'تاريخ الإنشاء',
              DateFormat('d MMMM yyyy', 'ar').format(booking!.createdAt),
              Icons.schedule_rounded,
              isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.2 * 255).toInt())
                : AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.spiceOrange.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_rounded,
                  color: AppColors.spiceOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ملاحظات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundTertiaryDark : AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              booking!.notes!,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.2 * 255).toInt())
                : AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.atlasBlue.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.atlasBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'التواصل مع المضيف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundTertiaryDark : AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.message_rounded,
                      size: 18,
                      color: AppColors.atlasBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'لديك أسئلة حول حجزك؟',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك التواصل مباشرة مع المضيف لمناقشة تفاصيل الحجز أو طرح أي استفسارات',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    height: 1.4,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.atlasBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text(
                      'بدء المحادثة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider auth, bool isDark) {
    return Container();
  }

  Widget _buildBottomActionBar(AuthProvider auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderMediumDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : AppColors.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (booking!.paymentMethod == 'online' &&
                booking!.paymentStatus == 'pending')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              bookingId: booking!.id,
                              amount: booking!.totalPrice,
                              propertyTitle:
                                  'حجز رقم ${booking!.id.substring(0, 8)}',
                            ),
                          ),
                        )
                        .then((_) => _load());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor:
                        AppColors.primaryRed.withAlpha((0.4 * 255).toInt()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: const Text(
                    'ادفع الآن',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            if (booking!.canBeReviewed) ...[
              if (booking!.paymentMethod == 'online' &&
                  booking!.paymentStatus == 'pending')
                const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _addReview();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.star_rounded, size: 20),
                  label: const Text(
                    'أضف تقييمك',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ],
            if (auth.isHost &&
                (booking!.status == 'pending' ||
                    booking!.status == 'confirmed')) ...[
              if (booking!.paymentMethod == 'online' &&
                      booking!.paymentStatus == 'pending' ||
                  booking!.canBeReviewed)
                const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (booking!.status == 'pending') {
                            _changeStatus('confirmed');
                          } else {
                            _changeStatus('completed');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          booking!.status == 'pending' ? 'تأكيد' : 'إكمال',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _changeStatus('cancelled');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.error, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
