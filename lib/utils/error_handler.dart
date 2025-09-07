import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/widgets/common/app_button.dart';

class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              AppIcons.errorOutline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              AppIcons.checkCircleOutline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              AppIcons.warningOutline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              AppIcons.infoOutline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error.toString().contains('network')) {
      return 'خطأ في الاتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }

    if (error.toString().contains('auth')) {
      return 'خطأ في المصادقة. يرجى تسجيل الدخول مرة أخرى.';
    }

    if (error.toString().contains('permission')) {
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    }

    if (error.toString().contains('validation')) {
      return 'البيانات المدخلة غير صحيحة. يرجى التحقق والمحاولة مرة أخرى.';
    }

    if (error.toString().contains('not_found')) {
      return 'العنصر المطلوب غير موجود.';
    }

    if (error.toString().contains('already_exists')) {
      return 'العنصر موجود بالفعل.';
    }

    if (error.toString().contains('timeout')) {
      return 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';
    }

    if (error.toString().contains('server')) {
      return 'خطأ في الخادم. يرجى المحاولة لاحقاً.';
    }

    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }

  static String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid_email':
        return 'البريد الإلكتروني غير صحيح.';
      case 'user_not_found':
        return 'المستخدم غير موجود.';
      case 'wrong_password':
        return 'كلمة المرور غير صحيحة.';
      case 'email_already_in_use':
        return 'البريد الإلكتروني مستخدم بالفعل.';
      case 'weak_password':
        return 'كلمة المرور ضعيفة جداً.';
      case 'too_many_requests':
        return 'تم تجاوز الحد الأقصى للمحاولات. يرجى الانتظار قليلاً.';
      case 'network_request_failed':
        return 'فشل في الاتصال بالشبكة.';
      case 'user_disabled':
        return 'تم تعطيل الحساب.';
      case 'operation_not_allowed':
        return 'العملية غير مسموح بها.';
      case 'invalid_verification_code':
        return 'رمز التحقق غير صحيح.';
      case 'invalid_verification_id':
        return 'معرف التحقق غير صحيح.';
      default:
        return 'حدث خطأ في المصادقة.';
    }
  }

  static String getPropertyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'property_not_found':
        return 'العقار غير موجود.';
      case 'property_not_available':
        return 'العقار غير متاح للحجز.';
      case 'property_already_booked':
        return 'العقار محجوز بالفعل في هذه التواريخ.';
      case 'invalid_dates':
        return 'التواريخ المحددة غير صحيحة.';
      case 'dates_in_past':
        return 'لا يمكن حجز تواريخ في الماضي.';
      case 'minimum_stay_not_met':
        return 'مدة الإقامة أقل من الحد الأدنى المطلوب.';
      case 'maximum_stay_exceeded':
        return 'مدة الإقامة تتجاوز الحد الأقصى المسموح.';
      default:
        return 'حدث خطأ في العقار.';
    }
  }

  static String getBookingErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'booking_not_found':
        return 'الحجز غير موجود.';
      case 'booking_already_cancelled':
        return 'الحجز ملغي بالفعل.';
      case 'booking_already_completed':
        return 'الحجز مكتمل بالفعل.';
      case 'cancellation_not_allowed':
        return 'لا يمكن إلغاء الحجز في هذه المرحلة.';
      case 'refund_not_available':
        return 'استرداد المال غير متاح.';
      case 'payment_failed':
        return 'فشل في الدفع.';
      case 'payment_pending':
        return 'الدفع قيد المعالجة.';
      default:
        return 'حدث خطأ في الحجز.';
    }
  }

  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              AppIcons.errorOutline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          AppButton(
            text: 'إلغاء',
            onPressed: () => context.pop(),
            type: AppButtonType.text,
            size: AppButtonSize.medium,
          ),
          if (confirmText != null)
            AppButton(
              text: confirmText,
              onPressed: () {
                context.pop();
                onConfirm?.call();
              },
              type: AppButtonType.secondary,
              size: AppButtonSize.medium,
            ),
        ],
      ),
    );
  }

  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required VoidCallback onConfirm,
    Color? confirmColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton(
            text: cancelText,
            onPressed: () => context.pop(),
            type: AppButtonType.text,
            size: AppButtonSize.medium,
          ),
          AppButton(
            text: confirmText,
            onPressed: () {
              context.pop();
              onConfirm();
            },
            type: AppButtonType.secondary,
            size: AppButtonSize.medium,
          ),
        ],
      ),
    );
  }

  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  static void showRetryDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton(
            text: 'إلغاء',
            onPressed: () => context.pop(),
            type: AppButtonType.text,
            size: AppButtonSize.medium,
          ),
          AppButton(
            text: 'إعادة المحاولة',
            onPressed: () {
              context.pop();
              onRetry();
            },
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
          ),
        ],
      ),
    );
  }
}