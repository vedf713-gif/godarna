import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// شريط التنقل السفلي الموحد للتطبيق - تصميم نظيف يشبه Airbnb
class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: AppDimensions.bottomNavHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(26),  // ~10% opacity
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;

            return Expanded(
              child: _AnimatedNavItem(
                index: index,
                item: item,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(index);
                },
                colorScheme: colorScheme,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// عنصر في شريط التنقل السفلي
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

/// شريط تنقل سفلي متحرك مخصص (نسخة محسّنة)
class AnimatedAppBottomNav extends StatelessWidget {
  const AnimatedAppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: AppDimensions.bottomNavHeight + 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(20),  // ~8% opacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return Expanded(
            child: _AnimatedNavItem(
              index: index,
              item: item,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap(index);
              },
              colorScheme: colorScheme,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget لعنصر تنقل متحرك
class _AnimatedNavItem extends StatefulWidget {
  const _AnimatedNavItem({
    required this.index,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  final int index;
  final AppBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  __AnimatedNavItemState createState() => __AnimatedNavItemState();
}

class __AnimatedNavItemState extends State<_AnimatedNavItem>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryRed.withAlpha(26)  // ~10% opacity
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.isSelected ? 32 : 28,
                height: widget.isSelected ? 32 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? AppColors.primaryRed
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.primaryRed
                        : widget.colorScheme.onSurfaceVariant,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.isSelected
                        ? (widget.item.activeIcon ?? widget.item.icon)
                        : widget.item.icon,
                    size: 20,
                    color: widget.isSelected
                        ? Colors.white
                        : widget.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected
                      ? AppColors.primaryRed
                      : widget.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
