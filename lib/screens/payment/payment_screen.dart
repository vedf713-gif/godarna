import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:godarna/services/payment_service.dart';
import 'package:godarna/services/notifications_service.dart';
import 'package:godarna/utils/error_handler.dart';
import 'package:godarna/theme/app_theme.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/widgets/common/app_button.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:godarna/providers/auth_provider.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String propertyTitle;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.propertyTitle,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with RealtimeMixin {
  final PaymentService _paymentService = PaymentService();
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  Map<String, dynamic>? _paymentResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    
    if (userId == null) return;

    // اشتراك في تحديثات المدفوعات للحجز الحالي
    subscribeToTable(
      table: 'payments',
      filter: 'booking_id',
      filterValue: widget.bookingId,
      onInsert: (payload) {
        if (mounted) {
          // تحديث حالة الدفع عند إضافة دفعة جديدة
          setState(() {
            // يمكن إضافة منطق تحديث الواجهة هنا
          });
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          // تحديث حالة الدفع عند تحديث الدفعة
          setState(() {
            // يمكن إضافة منطق تحديث الواجهة هنا
          });
        }
      },
    );
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppStrings.getString('payment', context),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            _buildBookingSummary(),

            const SizedBox(height: AppDimensions.space24),

            // Payment Methods
            _buildPaymentMethods(),

            const SizedBox(height: AppDimensions.space24),

            // Payment Button
            if (_selectedPaymentMethod != null) _buildPaymentButton(),

            const SizedBox(height: AppDimensions.space24),

            // Payment Result
            if (_paymentResult != null) _buildPaymentResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .shadow
                  .withAlpha((0.6 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: AppDimensions.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: AppDimensions.paddingAll12,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha((0.12 * 255).toInt()),
                    borderRadius: AppDimensions.borderRadiusMedium,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: cs.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.getString('bookingSummary', context),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        AppStrings.getString('confirmPayment', context),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space20),

            // Property Info
            Row(
              children: [
                Icon(
                  Icons.home,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Text(
                    widget.propertyTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space16),

            // Amount
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.space12),
                Text(
                  '${AppStrings.getString('totalAmount', context)}:',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  '${widget.amount.toStringAsFixed(2)} ${AppStrings.getString('currencyMad', context)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space16),

            // Booking ID
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.space12),
                Text(
                  '${AppStrings.getString('bookingId', context)}:',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  widget.bookingId.substring(0, 8),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final theme = Theme.of(context);
    final paymentMethods = _paymentService.getAvailablePaymentMethods();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .shadow
                  .withAlpha((0.6 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: AppDimensions.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.getString('choosePaymentMethod', context),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.space16),
            ...paymentMethods.map((method) => _buildPaymentMethodCard(method)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelected = _selectedPaymentMethod == method['id'];

    return Container(
      margin: AppDimensions.marginBottom12,
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withAlpha((0.08 * 255).toInt())
            : Theme.of(context)
                .colorScheme
                .surface
                .withAlpha((0.0 * 255).toInt()),
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(
          color: isSelected ? cs.primary : cs.outlineVariant,
          width: 2,
        ),
      ),
      child: RadioListTile<String>(
        value: method['id'],
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        title: Row(
          children: [
            Icon(
              _getPaymentMethodIcon(method['icon']),
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  Text(
                    method['description'],
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: cs.primary,
        contentPadding: AppDimensions.paddingSymmetric16x8,
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AppButton(
        text: _isProcessing
            ? AppStrings.getString('processing', context)
            : AppStrings.getString('confirmPayment', context),
        onPressed: _isProcessing ? null : _processPayment,
        isLoading: _isProcessing,
        type: AppButtonType.primary,
      ),
    );
  }

  Widget _buildPaymentResult() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cc = theme.extension<CustomColors>();
    final isSuccess = _paymentResult!['success'] == true;
    final successColor = cc?.success ?? cs.tertiary;
    final errorColor = cs.error;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .shadow
                  .withAlpha((0.6 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: AppDimensions.paddingAll20,
        child: Column(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? successColor : errorColor,
              size: 48,
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              _paymentResult!['message'],
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSuccess ? successColor : errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (_paymentResult!['transaction_id'] != null) ...[
              const SizedBox(height: AppDimensions.space16),
              Container(
                padding: AppDimensions.paddingSymmetric16x8,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: AppDimensions.borderRadiusCircular,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppStrings.getString('transactionId', context)}: ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      _paymentResult!['transaction_id'],
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.space20),
            if (isSuccess) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AppButton(
                  text: AppStrings.getString('returnHome', context),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  type: AppButtonType.primary,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: AppButton(
                        text: AppStrings.getString('retry', context),
                        onPressed: () {
                          setState(() {
                            _paymentResult = null;
                          });
                        },
                        type: AppButtonType.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: AppButton(
                        text: AppStrings.getString('back', context),
                        onPressed: () => Navigator.pop(context),
                        type: AppButtonType.secondary,
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

  // Helper methods
  IconData _getPaymentMethodIcon(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _paymentService.processPayment(
        bookingId: widget.bookingId,
        paymentMethod: _selectedPaymentMethod!,
        amount: widget.amount,
        paymentDetails: {
          'property_title': widget.propertyTitle,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _paymentResult = result;
        _isProcessing = false;
      });

      if (result['success'] == true) {
        // Send notification to host
        try {
          await NotificationsService().sendNotification(
            userId: widget.bookingId, // Replace with actual host ID
            title: 'حجز جديد',
            message: 'تم استلام دفعة جديدة لحجز ${widget.propertyTitle}',
            type: 'payment_received',
            data: {
              'booking_id': widget.bookingId,
              'amount': widget.amount.toString(),
            },
          );
        } catch (e) {
          // Log error but don't interrupt payment flow
          debugPrint('Failed to send notification: $e');
        }

        // Show success message
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            'تم الدفع بنجاح!',
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            result['message'] ?? 'حدث خطأ في الدفع',
          );
        }
      }
    } catch (e) {
      setState(() {
        _paymentResult = {
          'success': false,
          'message': 'حدث خطأ غير متوقع: $e',
        };
        _isProcessing = false;
      });

      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'حدث خطأ في معالجة الدفع',
        );
      }
    }
  }
}
