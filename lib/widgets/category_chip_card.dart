import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/widgets/bouncy_tap.dart';

class CategoryChipCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color>? gradient;
  final VoidCallback? onTap;

  const CategoryChipCard({
    super.key,
    required this.title,
    required this.icon,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = gradient ??
        (isDark
            ? [theme.colorScheme.primary, theme.colorScheme.secondary]
            : [theme.colorScheme.primary, theme.colorScheme.tertiary]);

    return SizedBox(
      width: 84,
      height: 84,
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTokens.r16,
            boxShadow: [
              if (isDark)
                BoxShadow(
                    color: theme.colorScheme.primary
                        .withAlpha((0.3 * 255).toInt()),
                    blurRadius: 18,
                    spreadRadius: 1)
              else
                BoxShadow(
                    color: Colors.black.withAlpha((0.6 * 255).toInt()),
                    blurRadius: 12,
                    offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
