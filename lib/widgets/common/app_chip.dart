import 'package:flutter/material.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/theme/app_text_styles.dart';

/// شريحة موحدة للتطبيق - تصميم نظيف يشبه Airbnb
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onDeleted,
    this.avatar,
    this.deleteIcon,
    this.backgroundColor,
    this.selectedColor,
    this.labelColor,
    this.deleteIconColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final Widget? avatar;
  final Widget? deleteIcon;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? labelColor;
  final Color? deleteIconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bgColor = isSelected
        ? selectedColor ?? const Color(0xFFFF3A44).withAlpha((0.12 * 255).round())
        : backgroundColor ?? colorScheme.surface;

    final Color textColor = isSelected
        ? labelColor ?? const Color(0xFFFF3A44)
        : labelColor ?? colorScheme.onSurfaceVariant;

    final Color deleteColor = deleteIconColor ?? colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: AppDimensions.chipPadding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppDimensions.chipBorderRadius,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF3A44)
                : colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              avatar!,
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.chipLabel.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDeleted,
                child: deleteIcon ??
                    Icon(
                      Icons.close,
                      size: 16,
                      color: deleteColor,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// مجموعة شرائح قابلة للاختيار - تصميم يشبه Airbnb
class AppChipGroup extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.chips,
    required this.selectedChips,
    required this.onSelectionChanged,
    this.multiSelect = true,
    this.spacing,
    this.runSpacing,
  });

  final List<String> chips;
  final Set<String> selectedChips;
  final ValueChanged<Set<String>> onSelectionChanged;
  final bool multiSelect;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing ?? AppDimensions.space8,
      runSpacing: runSpacing ?? AppDimensions.space8,
      children: chips.map((chip) {
        final isSelected = selectedChips.contains(chip);

        return AppChip(
          label: chip,
          isSelected: isSelected,
          onTap: () {
            final newSelection = Set<String>.from(selectedChips);

            if (multiSelect) {
              if (isSelected) {
                newSelection.remove(chip);
              } else {
                newSelection.add(chip);
              }
            } else {
              newSelection.clear();
              if (!isSelected) {
                newSelection.add(chip);
              }
            }

            onSelectionChanged(newSelection);
          },
        );
      }).toList(),
    );
  }
}
