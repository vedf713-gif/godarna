import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/widgets/common/app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative soft radial background
            IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        cs.primary.withAlpha(20),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.s16),
                    decoration: BoxDecoration(
                      color: cs.surface.withAlpha(179),
                      borderRadius: AppTokens.r16,
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(icon, size: 40, color: cs.primary),
                  ),
                const SizedBox(height: AppTokens.s16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppTokens.s16),
                  AppButton(
                    text: actionLabel!,
                    onPressed: onAction,
                    type: AppButtonType.primary,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
