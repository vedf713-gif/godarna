import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/constants/app_colors.dart';

/// Moroccan-inspired decorative elements and patterns
class MoroccanDecorations {
  // === GRADIENTS ===

  /// Warm sunset gradient inspired by Sahara desert (uses theme colors)
  static LinearGradient saharaGradient(ColorScheme cs) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.gradSunset,
        stops: [0.0, 1.0],
      );

  /// Atlas mountain gradient with cool hues based on tertiary
  static LinearGradient atlasGradient(ColorScheme cs) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cs.tertiary,
          cs.tertiaryContainer,
          cs.secondaryContainer,
        ],
        stops: const [0.0, 0.6, 1.0],
      );

  /// Moroccan tile pattern gradient based on primary
  static LinearGradient tileGradient(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.primaryContainer,
          cs.primary,
          cs.secondary,
        ],
        stops: const [0.0, 0.4, 1.0],
      );

  /// Soft background gradient for cards from surface containers
  static LinearGradient cardGradient(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.surfaceContainer,
          cs.onSurfaceVariant,
        ],
        stops: const [0.0, 1.0],
      );

  // === SHADOWS ===

  /// Moroccan-style elevated shadow
  static List<BoxShadow> moroccanShadow(ColorScheme cs) => [
        BoxShadow(
          color: cs.shadow.withAlpha(31),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: cs.shadow.withAlpha(15),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  /// Soft glow effect for interactive elements
  static List<BoxShadow> glowShadow(Color base) => [
        BoxShadow(
          color: base.withAlpha(64),
          blurRadius: 16,
          offset: const Offset(0, 0),
          spreadRadius: 0,
        ),
      ];

  /// Card elevation shadow
  static List<BoxShadow> cardShadow(ColorScheme cs) => [
        BoxShadow(
          color: cs.shadow.withAlpha(20),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  // === BORDERS ===

  /// Moroccan-style border with rounded corners
  static BorderRadius get moroccanBorder =>
      BorderRadius.circular(AppTokens.s20);

  /// Tile-inspired border radius
  static BorderRadius get tileBorder => BorderRadius.circular(AppTokens.s16);

  /// Soft rounded border
  static BorderRadius get softBorder => BorderRadius.circular(AppTokens.s12);

  /// Circular border for avatars and icons
  static BorderRadius get circularBorder => BorderRadius.circular(50);

  // === DECORATIVE SHAPES ===

  /// Creates a Moroccan arch shape
  static ShapeBorder get archShape => const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.s24),
          topRight: Radius.circular(AppTokens.s24),
          bottomLeft: Radius.circular(AppTokens.s8),
          bottomRight: Radius.circular(AppTokens.s8),
        ),
      );

  /// Creates a tile-like shape
  static ShapeBorder get tileShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.s16),
      );

  /// Creates a lantern-like shape for cards
  static ShapeBorder get lanternShape => const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.s20),
          topRight: Radius.circular(AppTokens.s4),
          bottomLeft: Radius.circular(AppTokens.s4),
          bottomRight: Radius.circular(AppTokens.s20),
        ),
      );

  // === DECORATIVE CONTAINERS ===

  /// Creates a Moroccan-style container decoration
  static BoxDecoration moroccanContainer({
    required ColorScheme cs,
    Color? color,
    Gradient? gradient,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? cs.surfaceContainer,
      gradient: gradient ?? cardGradient(cs),
      borderRadius: moroccanBorder,
      boxShadow: shadows ?? moroccanShadow(cs),
      border: Border.all(
        color: cs.outlineVariant,
        width: 1,
      ),
    );
  }

  /// Creates a glowing accent container
  static BoxDecoration glowContainer({
    required ColorScheme cs,
    Color? color,
    double? glowIntensity,
  }) {
    final base = color ?? cs.primary;
    return BoxDecoration(
      color: base,
      borderRadius: tileBorder,
      boxShadow: [
        BoxShadow(
          color: base.withAlpha((glowIntensity != null ? glowIntensity * 255 : 77).round()),
          blurRadius: 20,
          offset: const Offset(0, 0),
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Creates a subtle background pattern container
  static BoxDecoration patternContainer(ColorScheme cs) {
    return BoxDecoration(
      gradient: cardGradient(cs),
      borderRadius: softBorder,
      boxShadow: cardShadow(cs),
    );
  }
}

/// Moroccan-inspired clipper for custom shapes
class MoroccanClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 20.0;

    // Create a Moroccan arch-like shape
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius * 2);
    path.quadraticBezierTo(size.width, size.height - radius,
        size.width - radius, size.height - radius);
    path.lineTo(size.width * 0.6, size.height - radius);
    path.quadraticBezierTo(
        size.width * 0.5, size.height, size.width * 0.4, size.height - radius);
    path.lineTo(radius, size.height - radius);
    path.quadraticBezierTo(
        0, size.height - radius, 0, size.height - radius * 2);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Widget for creating Moroccan-style decorative elements
class MoroccanPattern extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;

  const MoroccanPattern({
    super.key,
    this.size = 100,
    this.color,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size(size, size),
      painter: MoroccanPatternPainter(
        color: Color.fromARGB(
          (opacity * 255).round(),
          ((color ?? cs.primary).r * 255.0).round() & 0xff,
          ((color ?? cs.primary).g * 255.0).round() & 0xff,
          ((color ?? cs.primary).b * 255.0).round() & 0xff,
        ),
      ),
    );
  }
}

/// Custom painter for Moroccan geometric patterns
class MoroccanPatternPainter extends CustomPainter {
  final Color color;

  MoroccanPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw geometric pattern inspired by Moroccan tiles
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final x = center.dx + radius * 0.7 * cos(angle);
      final y = center.dy + radius * 0.7 * sin(angle);

      canvas.drawCircle(Offset(x, y), radius / 6, paint);
    }

    // Central element
    canvas.drawCircle(center, radius / 4, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Helper functions for trigonometry
double cos(double angle) => math.cos(angle);
double sin(double angle) => math.sin(angle);
