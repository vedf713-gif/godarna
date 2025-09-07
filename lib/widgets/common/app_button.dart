import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// زر موحد للتطبيق - تصميم نظيف يشبه Airbnb
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;

  @override
  AppButtonState createState() => AppButtonState();
}

class AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // تحديد الارتفاع حسب الحجم
    final double height = switch (widget.size) {
      AppButtonSize.small => AppDimensions.buttonHeightSmall,
      AppButtonSize.medium => AppDimensions.buttonHeightMedium,
      AppButtonSize.large => AppDimensions.buttonHeightLarge,
      AppButtonSize.xLarge => AppDimensions.buttonHeightXLarge,
    };

    // تحديد نمط النص حسب الحجم
    final TextStyle textStyle = switch (widget.size) {
      AppButtonSize.small =>
        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      AppButtonSize.medium =>
        GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      AppButtonSize.large =>
        GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
      AppButtonSize.xLarge =>
        GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
    };

    // تحديد الـ padding حسب الحجم
    final EdgeInsets padding = switch (widget.size) {
      AppButtonSize.small => AppDimensions.paddingHorizontal12,
      AppButtonSize.medium => AppDimensions.paddingHorizontal16,
      AppButtonSize.large => AppDimensions.paddingHorizontal24,
      AppButtonSize.xLarge => AppDimensions.paddingHorizontal24,
    };

    final Widget child = _buildButtonContent(textStyle, cs);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.isEnabled && !widget.isLoading && widget.onPressed != null) {
          HapticFeedback.lightImpact();
          widget.onPressed!();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width,
          height: height,
          child: switch (widget.type) {
            AppButtonType.primary => _buildPrimaryButton(child, cs, padding),
            AppButtonType.secondary =>
              _buildSecondaryButton(child, cs, padding),
            AppButtonType.text => _buildTextButton(child, cs, padding),
          },
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(Widget child, ColorScheme cs, EdgeInsets padding) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.isEnabled
            ? AppColors.primaryRed
            : cs.onSurface.withAlpha(77),  // ~30% opacity
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.isEnabled
                ? AppColors.primaryRed.withAlpha(51)  // ~20% opacity
                : Colors.transparent,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
          child: Padding(
            padding: padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
      Widget child, ColorScheme cs, EdgeInsets padding) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isEnabled
              ? AppColors.primaryRed
              : cs.onSurface.withAlpha(77),  // ~30% opacity
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
          child: Padding(
            padding: padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(Widget child, ColorScheme cs, EdgeInsets padding) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
        child: Padding(
          padding: padding,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildButtonContent(TextStyle textStyle, ColorScheme cs) {
    if (widget.isLoading) {
      return SizedBox(
        width: AppDimensions.iconMedium,
        height: AppDimensions.iconMedium,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.type == AppButtonType.primary
              ? Colors.white
              : AppColors.primaryRed,
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: switch (widget.size) {
              AppButtonSize.small => AppDimensions.iconSmall,
              AppButtonSize.medium => AppDimensions.iconMedium,
              AppButtonSize.large => AppDimensions.iconLarge,
              AppButtonSize.xLarge => AppDimensions.iconXLarge,
            },
            color: widget.type == AppButtonType.primary
                ? Colors.white
                : AppColors.primaryRed,
          ),
          const SizedBox(width: AppDimensions.space8),
          Text(
            widget.text,
            style: textStyle.copyWith(
              color: widget.type == AppButtonType.primary
                  ? Colors.white
                  : AppColors.primaryRed,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: textStyle.copyWith(
        color: widget.type == AppButtonType.primary
            ? Colors.white
            : AppColors.primaryRed,
      ),
    );
  }
}

/// أنواع الأزرار المتاحة
enum AppButtonType {
  primary,
  secondary,
  text,
}

/// أحجام الأزرار المتاحة
enum AppButtonSize {
  small,
  medium,
  large,
  xLarge,
}
