import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/widgets/bouncy_tap.dart';

class AnimatedBottomNavItem {
  final Widget icon;
  final String label;
  const AnimatedBottomNavItem({required this.icon, required this.label});
}

class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AnimatedBottomNavItem> items;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  }) : assert(items.length >= 2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ??
              theme.bottomNavigationBarTheme.backgroundColor ??
              cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha((0.4 * 255).toInt())
                  : cs.shadow.withAlpha((0.10 * 255).toInt()),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < items.length; i++)
              _NavItem(
                index: i,
                isSelected: i == currentIndex,
                item: items[i],
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final AnimatedBottomNavItem item;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.isSelected,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final activeGradient =
        isDark ? [cs.secondary, cs.tertiary] : [cs.primary, cs.secondary];

    return Expanded(
      child: BouncyTap(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: AppTokens.dMedium,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: AppTokens.r16,
            gradient: isSelected
                ? LinearGradient(
                    colors: activeGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: isSelected ? 1 : 0),
                duration: AppTokens.dMedium,
                curve: Curves.easeOutBack,
                builder: (context, t, _) {
                  final double scale = 0.96 + t * 0.12; // pop
                  final Color iconColor = isSelected
                      ? Colors.white
                      : theme.bottomNavigationBarTheme.unselectedItemColor ??
                          cs.onSurfaceVariant;
                  return Transform.scale(
                    scale: scale,
                    child: IconTheme(
                      data: IconThemeData(
                        size: isSelected ? 22 : 18,
                        color: iconColor,
                      ),
                      child: item.icon,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: AppTokens.dMedium,
                  curve: Curves.easeOut,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.bottomNavigationBarTheme.unselectedItemColor ??
                            cs.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: isSelected ? 10 : 9,
                  ),
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
