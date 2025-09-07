import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/theme/moroccan_decorations.dart';

/// Moroccan-style elevated card that uses the global CardTheme.
class MoroccanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double? elevation;

  const MoroccanCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;

    return Card(
      margin: margin ?? cardTheme.margin,
      color: color ?? cardTheme.color,
      elevation: elevation ?? cardTheme.elevation,
      shape: cardTheme.shape,
      clipBehavior: cardTheme.clipBehavior ?? Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: (cardTheme.shape as RoundedRectangleBorder?)?.borderRadius.resolve(Directionality.of(context)),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppTokens.s16), // Default padding
          child: child,
        ),
      ),
    );
  }
}

/// Moroccan-style button with gradient and glow effects
class MoroccanButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const MoroccanButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = isSecondary
        ? theme.outlinedButtonTheme.style
        : theme.elevatedButtonTheme.style;

    final foregroundColor =
        buttonStyle?.foregroundColor?.resolve({}) ?? theme.colorScheme.onPrimary;
    final backgroundColor = isSecondary
        ? Colors.transparent
        : buttonStyle?.backgroundColor?.resolve({}) ?? theme.colorScheme.primary;

    return SizedBox(
      width: width,
      child: Opacity(
        opacity: (onPressed == null || isLoading) ? 0.65 : 1.0,
        child: Material(
          color: backgroundColor,
          shape: buttonStyle?.shape?.resolve({}),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            customBorder: buttonStyle?.shape?.resolve({}),
            child: Container(
              padding: padding ??
                  buttonStyle?.padding?.resolve({}) ??
                  const EdgeInsets.symmetric(
                    horizontal: AppTokens.s24,
                    vertical: AppTokens.s16,
                  ),
              decoration: isSecondary ? BoxDecoration(
                border: Border.all(color: foregroundColor, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, color: foregroundColor, size: 20),
                  if (isLoading || icon != null)
                    const SizedBox(width: AppTokens.s12),
                  Flexible(
                    child: Text(
                      text,
                      style: theme.textTheme.labelLarge?.copyWith(color: foregroundColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Moroccan-style header with decorative elements
class MoroccanHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showPattern;
  final Color? backgroundColor;

  const MoroccanHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showPattern = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: BoxDecoration(
        gradient: MoroccanDecorations.saharaGradient(cs),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTokens.s24),
          bottomRight: Radius.circular(AppTokens.s24),
        ),
      ),
      child: Stack(
        children: [
          if (showPattern)
            Positioned(
              top: -20,
              right: -20,
              child: MoroccanPattern(
                size: 120,
                color: cs.onPrimary,
                opacity: 0.1,
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppTokens.s4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: cs.onPrimary.withAlpha(230),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) 
                    Flexible(child: trailing!),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Moroccan-style input field with decorative border
class MoroccanTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;

  const MoroccanTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: AppTokens.s4, bottom: AppTokens.s8),
            child: Text(
              label!,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon)
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon),
                    onPressed: onSuffixTap,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Moroccan-style loading indicator
class MoroccanLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const MoroccanLoader({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  State<MoroccanLoader> createState() => _MoroccanLoaderState();
}

class _MoroccanLoaderState extends State<MoroccanLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: MoroccanPattern(
            size: widget.size,
            color: widget.color ?? cs.primary,
            opacity: 0.8,
          ),
        );
      },
    );
  }
}

/// Moroccan-style chip with decorative styling
class MoroccanChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const MoroccanChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final chipTheme = Theme.of(context).chipTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine the correct text style based on selection
    final effectiveLabelStyle = isSelected
        ? chipTheme.secondaryLabelStyle
        : chipTheme.labelStyle;

    // Determine icon color based on selection
    final Color? iconColor = isSelected 
        ? chipTheme.secondarySelectedColor 
        : (isDark ? Colors.white70 : Colors.black87);


    return ChoiceChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 18, color: iconColor) : null,
      onSelected: onTap != null ? (bool selected) => onTap!() : null,
      selected: isSelected,
      backgroundColor: chipTheme.backgroundColor,
      selectedColor: chipTheme.selectedColor,
      disabledColor: chipTheme.disabledColor,
      labelStyle: effectiveLabelStyle,
      shape: chipTheme.shape,
      side: chipTheme.side,
      padding: chipTheme.padding,
      showCheckmark: chipTheme.checkmarkColor != null,
      checkmarkColor: chipTheme.checkmarkColor,
    );
  }
}
