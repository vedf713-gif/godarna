import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:godarna/services/payment_service.dart';
import 'package:godarna/utils/error_handler.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:intl/intl.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/theme/app_theme.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/widgets/common/app_button.dart';
import 'package:godarna/mixins/realtime_mixin.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> with RealtimeMixin {
  final PaymentService _paymentService = PaymentService();
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    final authProvider = context.read<AuthProvider?>();
    String? userId = authProvider?.currentUser?.id;
    userId ??= Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) return;

    // اشتراك في تحديثات المدفوعات للمستخدم الحالي
    subscribeToTable(
      table: 'payments',
      filter: 'user_id',
      filterValue: userId,
      onInsert: (payload) {
        if (mounted) {
          // تحديث قائمة المدفوعات عند إضافة دفعة جديدة
          _loadPaymentData();
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          // تحديث قائمة المدفوعات عند تحديث حالة الدفع
          _loadPaymentData();
        }
      },
      onDelete: (payload) {
        if (mounted) {
          // تحديث قائمة المدفوعات عند حذف دفعة
          _loadPaymentData();
        }
      },
    );
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user ID from AuthProvider or Supabase
      final authProvider = context.read<AuthProvider?>();
      String? userId = authProvider?.currentUser?.id;
      userId ??= Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception(
            AppStrings.getString('userNotIdentifiedPleaseLogin', context));
      }

      final payments = await _paymentService.getPaymentHistory(userId);
      final stats = await _paymentService.getPaymentStatistics(userId);

      setState(() {
        _payments = payments;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          '${AppStrings.getString('paymentsLoadError', context)}: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppAppBar(
        title: AppStrings.getString('paymentHistory', context),
        actions: [
          IconButton(
            onPressed: _loadPaymentData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  // Use theme's progressIndicatorTheme
                  ),
            )
          : RefreshIndicator(
              onRefresh: _loadPaymentData,
              color: cs.primary,
              child: SingleChildScrollView(
                padding: AppDimensions.paddingAll20,
                child: Column(
                  children: [
                    // Statistics
                    _buildStatistics(),

                    const SizedBox(height: AppDimensions.space24),

                    // Payments List
                    _buildPaymentsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatistics() {
    final cs = Theme.of(context).colorScheme;
    final cc = Theme.of(context).extension<CustomColors>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha((0.08 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('paymentsStats', context),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppStrings.getString('totalPaid', context),
                  "${_statistics['totalPaid']?.toStringAsFixed(2) ?? '0.00'} ${AppStrings.getString('currencyMad', context)}",
                  Icons.check_circle,
                  (cc?.success ?? cs.tertiary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  AppStrings.getString('totalPending', context),
                  "${_statistics['totalPending']?.toStringAsFixed(2) ?? '0.00'} ${AppStrings.getString('currencyMad', context)}",
                  Icons.schedule,
                  (cc?.warning ?? cs.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppStrings.getString('successfulPayments', context),
                  '${_statistics['successfulPayments'] ?? 0}',
                  Icons.thumb_up,
                  (cc?.success ?? cs.tertiary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  AppStrings.getString('failedPayments', context),
                  '${_statistics['failedPayments'] ?? 0}',
                  Icons.thumb_down,
                  cs.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    final cs = Theme.of(context).colorScheme;
    if (_payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: AppDimensions.paddingAll40,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant,
          borderRadius: BorderRadius.circular(16),
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
            Icon(
              Icons.payment,
              size: 64,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.getString('noPayments', context),
              style: TextStyle(
                fontSize: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.getString('paymentsEmptySubtitle', context),
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha((0.08 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              AppStrings.getString('paymentHistory', context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final payment = _payments[index];
              return _buildPaymentCard(payment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amount = (payment['amount'] ?? 0).toDouble();
    final status = payment['status'] ?? '';
    final method = payment['payment_method'] ?? '';
    final createdAt =
        DateTime.tryParse(payment['created_at'] ?? '') ?? DateTime.now();
    final cs = Theme.of(context).colorScheme;
    final cc = Theme.of(context).extension<CustomColors>();

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'paid':
        statusColor = (cc?.success ?? cs.tertiary);
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = (cc?.warning ?? cs.secondary);
        statusIcon = Icons.schedule;
        break;
      case 'failed':
        statusColor = cs.error;
        statusIcon = Icons.error;
        break;
      case 'refunded':
        statusColor = (cc?.info ?? cs.tertiaryContainer);
        statusIcon = Icons.undo;
        break;
      default:
        statusColor = cs.onSurfaceVariant;
        statusIcon = Icons.help;
    }

    return Container(
      margin: AppDimensions.paddingSymmetric20x8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: AppDimensions.paddingAll8,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.1 * 255).toInt()),
                  borderRadius: AppDimensions.borderRadiusMedium,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPaymentMethodName(method),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: AppDimensions.paddingSymmetric8x4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: AppDimensions.borderRadiusMedium,
                ),
                child: Text(
                  _getStatusText(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.getString('amountLabel', context),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "${amount.toStringAsFixed(2)} ${AppStrings.getString('currencyMad', context)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (payment['transaction_id'] != null) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.getString('transactionId', context),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        payment['transaction_id'].toString().substring(0, 8),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Property Info
          if (payment['bookings'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: AppDimensions.paddingAll12,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home,
                    color: cs.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      AppStrings.getString('bookedProperty', context),
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(
                      DateTime.tryParse(
                              payment['bookings']['check_in'] ?? '') ??
                          DateTime.now(),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions
          if (status == 'paid' && method != 'cash_on_delivery') ...[
            const SizedBox(height: 16),
            AppButton(
              text: AppStrings.getString('refundRequest', context),
              onPressed: () => _showRefundDialog(payment),
              type: AppButtonType.secondary,
              size: AppButtonSize.medium,
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods
  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return AppStrings.getString('cashOnDelivery', context);
      default:
        return method;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return AppStrings.getString('statusPaid', context);
      case 'pending':
        return AppStrings.getString('statusPending', context);
      case 'failed':
        return AppStrings.getString('statusFailed', context);
      case 'refunded':
        return AppStrings.getString('statusRefunded', context);
      case 'cancelled':
        return AppStrings.getString('statusCancelled', context);
      default:
        return status;
    }
  }

  void _showRefundDialog(Map<String, dynamic> payment) {
    final amount = (payment['amount'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.getString('refundRequest', context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${AppStrings.getString('amountLabel', context)}: ${amount.toStringAsFixed(2)} ${AppStrings.getString('currencyMad', context)}"),
            const SizedBox(height: 16),
            Text(AppStrings.getString('refundReason', context)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: AppStrings.getString('refundHint', context),
                // Use themed input decoration
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          AppButton(
            text: AppStrings.getString('cancel', context),
            onPressed: () => Navigator.pop(context),
            type: AppButtonType.text,
            size: AppButtonSize.medium,
          ),
          AppButton(
            text: AppStrings.getString('sendRequest', context),
            onPressed: () {
              Navigator.pop(context);
              _processRefund(payment['id'], amount,
                  AppStrings.getString('refundReason', context));
            },
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
          ),
        ],
      ),
    );
  }

  Future<void> _processRefund(
      String paymentId, double amount, String reason) async {
    try {
      final result =
          await _paymentService.refundPayment(paymentId, amount, reason);

      if (result['success'] == true) {
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            AppStrings.getString('refundRequestSent', context),
          );
          _loadPaymentData(); // Refresh data
        }
      } else {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            result['message'] ??
                AppStrings.getString('refundRequestError', context),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          AppStrings.getString('refundProcessError', context),
        );
      }
    }
  }
}
