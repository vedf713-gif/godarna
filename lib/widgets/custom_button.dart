import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/widgets/bouncy_tap.dart';

/// أنواع الأزرار المخصصة
enum CustomButtonType {
  primary,
  secondary,
  outlined,
  text,
}

/// زر مخصص يُحاكي أزرار Airbnb من حيث التصميم والتفاعل
/// - لا يستخدم BackdropFilter أو ImageFilter.blur (يعمل على الويب)
/// - يدعم الوضع الداكن
/// - يعتمد على Theme.of(context).colorScheme
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final CustomButtonType type;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.padding,
    this.icon,
    this.type = CustomButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    switch (type) {
      case CustomButtonType.outlined:
        return _buildOutlinedButton(context, cs);
      case CustomButtonType.text:
        return _buildTextButton(context, cs);
      case CustomButtonType.secondary:
        return _buildSecondaryButton(context, cs);
      case CustomButtonType.primary:
        return _buildPrimaryButton(context, cs);
    }
  }

  Widget _buildPrimaryButton(BuildContext context, ColorScheme cs) {
    final buttonColor = backgroundColor ?? cs.primary;
    
    return SizedBox(
      width: width,
      height: height ?? 52,
      child: AbsorbPointer(
        absorbing: isLoading || onPressed == null,
        child: BouncyTap(
          onTap: onPressed ?? () {},
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [buttonColor, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withAlpha(31),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // طبقة لمعان خفيفة (Gloss)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(77),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // المحتوى المركزي
                Center(
                  child: Padding(
                    padding: padding ??
                        const EdgeInsets.symmetric(
                          horizontal: AppTokens.lg,
                          vertical: AppTokens.md,
                        ),
                    child: _buildButtonContent(textColor ?? cs.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, ColorScheme cs) {
    final buttonColor = backgroundColor ?? cs.secondary;
    
    return SizedBox(
      width: width,
      height: height ?? 52,
      child: AbsorbPointer(
        absorbing: isLoading || onPressed == null,
        child: BouncyTap(
          onTap: onPressed ?? () {},
          child: Container(
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withAlpha(20),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: padding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppTokens.lg,
                      vertical: AppTokens.md,
                    ),
                child: _buildButtonContent(textColor ?? cs.onSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, ColorScheme cs) {
    final buttonColor = backgroundColor ?? cs.primary;
    
    return SizedBox(
      width: width,
      height: height ?? 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: buttonColor, width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: AppTokens.lg,
                vertical: AppTokens.md,
              ),
          foregroundColor: buttonColor,
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: _buildButtonContent(textColor ?? buttonColor),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, ColorScheme cs) {
    final buttonColor = backgroundColor ?? cs.primary;
    
    return SizedBox(
      width: width,
      height: height ?? 52,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: AppTokens.lg,
                vertical: AppTokens.md,
              ),
          foregroundColor: buttonColor,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: _buildButtonContent(textColor ?? buttonColor),
      ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}
