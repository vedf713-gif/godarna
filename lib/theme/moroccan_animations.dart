import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Moroccan-inspired animations and transitions
class MoroccanAnimations {
  // === DURATION CONSTANTS ===
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // === CURVES ===
  static const Curve moroccanEase = Curves.easeOutCubic;
  static const Curve moroccanBounce = Curves.elasticOut;
  static const Curve moroccanSlide = Curves.easeInOutQuart;

  // === PAGE TRANSITIONS ===

  /// Slide transition from right (Arabic-friendly)
  static PageRouteBuilder<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: moroccanSlide),
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Fade and scale transition
  static PageRouteBuilder<T> fadeScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: moroccanEase),
        );
        final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: moroccanEase),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Moroccan-style reveal transition
  static PageRouteBuilder<T> moroccanReveal<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: slow,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return ClipPath(
              clipper: MoroccanRevealClipper(animation.value),
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }
}

/// Custom clipper for Moroccan-style reveal animation
class MoroccanRevealClipper extends CustomClipper<Path> {
  final double progress;

  MoroccanRevealClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width > size.height ? size.width : size.height;
    final radius = maxRadius * progress;

    // Create expanding circle reveal
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Animated Moroccan pattern widget
class AnimatedMoroccanPattern extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final bool autoPlay;

  const AnimatedMoroccanPattern({
    super.key,
    this.size = 100,
    required this.color,
    this.duration = const Duration(seconds: 3),
    this.autoPlay = true,
  });

  @override
  State<AnimatedMoroccanPattern> createState() =>
      _AnimatedMoroccanPatternState();
}

class _AnimatedMoroccanPatternState extends State<AnimatedMoroccanPattern>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    if (widget.autoPlay) {
      _rotationController.repeat();
      _scaleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: AnimatedMoroccanPatternPainter(color: widget.color),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for animated Moroccan patterns
class AnimatedMoroccanPatternPainter extends CustomPainter {
  final Color color;

  AnimatedMoroccanPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Color.fromARGB(
          (0.3 * 255).round(), 
          (color.r * 255.0).round() & 0xff, 
          (color.g * 255.0).round() & 0xff, 
          (color.b * 255.0).round() & 0xff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw outer decorative ring
    canvas.drawCircle(center, radius * 1.2, strokePaint);

    // Draw main pattern elements
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final x = center.dx + radius * 0.7 * _cos(angle);
      final y = center.dy + radius * 0.7 * _sin(angle);

      // Draw petal-like shapes
      final path = Path();
      path.addOval(Rect.fromCenter(
        center: Offset(x, y),
        width: radius / 3,
        height: radius / 6,
      ));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + 3.14159 / 2);
      canvas.translate(-x, -y);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    // Draw center element
    canvas.drawCircle(center, radius / 4, paint);
    canvas.drawCircle(center, radius / 6, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  double _cos(double angle) => math.cos(angle);
  double _sin(double angle) => math.sin(angle);
}

/// Staggered animation for list items
class StaggeredListAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + (delay * index),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Moroccan-style loading shimmer effect
class MoroccanShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const MoroccanShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<MoroccanShimmer> createState() => _MoroccanShimmerState();
}

class _MoroccanShimmerState extends State<MoroccanShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: -2, end: 2).animate(
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
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.colorScheme.surface;
    final highlightColor = widget.highlightColor ??
        theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt());

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
