import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';

enum BadgeTier { bronze, silver, gold, neon }

class UserBadge extends StatelessWidget {
  final BadgeTier tier;
  final String label;
  final IconData icon;

  const UserBadge({super.key, required this.tier, required this.label, required this.icon});

  List<Color> _colors(bool dark, BuildContext context) {
    switch (tier) {
      case BadgeTier.bronze:
        return const [Color(0xFFCD7F32), Color(0xFF8C5A2B)];
      case BadgeTier.silver:
        return const [Color(0xFFC0C0C0), Color(0xFF8E9AAE)];
      case BadgeTier.gold:
        return const [Color(0xFFFFD700), Color(0xFFE6A400)];
      case BadgeTier.neon:
        return dark
            ? [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.onSurfaceVariant]
            : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.surface];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = _colors(isDark, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: AppTokens.r16,
        boxShadow: [
          if (tier == BadgeTier.neon)
            BoxShadow(color: theme.colorScheme.primary.withAlpha(77), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
