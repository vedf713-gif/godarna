import 'package:flutter/material.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/theme/app_text_styles.dart';

/// حقل إدخال موحد للتطبيق - تصميم نظيف يشبه Airbnb
class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autofocus: autofocus,
      style: AppTextStyles.inputText.copyWith(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
        ),
        helperStyle: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.inputError.copyWith(
          color: colorScheme.error,
        ),
        // إزالة الحشوة الخلفية (filled)
        filled: false,
        fillColor: Colors.transparent,
        // إزالة الحدود الجانبية، فقط خط سفلي
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.outline.withAlpha((0.4 * 255).round()),
            width: 1.0,
          ),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.outline.withAlpha((0.4 * 255).round()),
            width: 1.0,
          ),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFFF3A44), // Airbnb Red
            width: 2.0,
          ),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.0,
          ),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.0,
          ),
          borderRadius: BorderRadius.zero,
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.outline.withAlpha(51), // 0.2 * 255 = 51
            width: 1.0,
          ),
          borderRadius: BorderRadius.zero,
        ),
        // تقليل الحشوة الداخلية قليلاً
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      ),
    );
  }
}

/// حقل بحث موحد - تصميم نظيف بدون حدود جانبية
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppInputField(
      controller: controller,
      hintText: hintText ?? 'البحث...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      prefixIcon: Icon(
        Icons.search,
        size: AppDimensions.iconMedium,
        color: colorScheme.onSurfaceVariant,
      ),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
              icon: Icon(
                Icons.clear,
                size: AppDimensions.iconMedium,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
    );
  }
}
