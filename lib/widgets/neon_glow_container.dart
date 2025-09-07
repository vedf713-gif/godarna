import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';

/// NeonGlowContainer: إطار حاوٍ يضيف توهج نيون لطيف في الوضع الداكن
/// مع ظل خفيف في الوضع الفاتح. لا يغير أي منطق، للاستخدام التجميلي فقط.
class NeonGlowContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? lightShadowColor;

  const NeonGlowContainer({
    super.key,
    required this.child,
    this.borderRadius = AppTokens.r16,
    this.padding,
    this.margin,
    this.lightShadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: borderRadius,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? cs.primary.withAlpha(71)
                : (lightShadowColor ?? cs.shadow.withAlpha(15)),
            blurRadius: isDark ? 22 : 10,
            spreadRadius: isDark ? 1 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
