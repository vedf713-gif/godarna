import 'package:flutter/material.dart';

/// كارت موحد للتطبيق - تصميم نظيف يشبه Airbnb
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget cardWidget = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        clipBehavior: clipBehavior,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          color: Colors.transparent,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha((0.04 * 255).toInt()),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(2),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}

/// كارت خاص بالعقارات - يشبه بطاقة Airbnb
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.child,
    this.onTap,
    this.imageHeight = 180,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? imageHeight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageHeight != null)
            SizedBox(
              height: imageHeight,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  'https://via.placeholder.com/300x180',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// كارت صغير للمعلومات - تصميم بسيط
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 32,
              color: const Color(0xFFFF3A44), // Airbnb Red
            ),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
