import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/constants/app_strings.dart';

class PropertyTypeTabs extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onSelected;
  final EdgeInsetsGeometry padding;

  const PropertyTypeTabs({
    super.key,
    required this.selectedType,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <_TypeTabItem>[
      _TypeTabItem(
          null, '•', AppStrings.getString('allPropertyTypes', context)),
      _TypeTabItem(
          'apartment', '🏢', AppStrings.getString('typeApartment', context)),
      _TypeTabItem('riad', '🏡', AppStrings.getString('typeRiad', context)),
      _TypeTabItem('desert_camp', '🏕️',
          AppStrings.getString('typeDesertCamp', context)),
      _TypeTabItem(
          'resort', '🏖️', AppStrings.getString('typeResort', context)),
      _TypeTabItem('hotel', '🏨', AppStrings.getString('typeHotel', context)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final item in items) ...[
            _buildChip(context, item, cs),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, _TypeTabItem item, ColorScheme cs) {
    final bool isSelected = item.value == selectedType ||
        (item.value == null && selectedType == null);
    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTokens.r16,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(item.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              borderRadius: AppTokens.r16,
              border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withAlpha(46),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.emoji,
                  style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                  child: Text(item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeTabItem {
  final String? value;
  final String emoji;
  final String label;
  _TypeTabItem(this.value, this.emoji, this.label);
}
