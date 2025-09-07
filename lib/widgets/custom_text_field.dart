import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLength;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Focus(
      child: Builder(
        builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: AppTokens.r16,
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: cs.primary.withAlpha(46),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              enabled: enabled,
              maxLength: maxLength,
              validator: validator,
              maxLines: maxLines,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                border: const OutlineInputBorder(
                  borderRadius: AppTokens.r16,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTokens.r16,
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTokens.r16,
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: AppTokens.r16,
                  borderSide: BorderSide(color: cs.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: AppTokens.r16,
                  borderSide: BorderSide(color: cs.error, width: 2),
                ),
                filled: true,
                fillColor: enabled ? cs.surface : cs.onSurfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16, vertical: AppTokens.s14),
                labelStyle: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 14),
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withAlpha(230),
                    fontSize: 14),
              ),
            ),
          );
        },
      ),
    );
  }
}
