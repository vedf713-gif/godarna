import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// مساعدات الانتقالات والتأثيرات المتحركة المتقدمة
class AnimationUtils {
  
  /// انتقال سلس بين الصفحات مع تأثير Slide
  static PageRouteBuilder<T> createSlideRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));
        
        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  /// انتقال مع تأثير Fade + Scale (Airbnb style)
  static PageRouteBuilder<T> createFadeScaleRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    double scaleBegin = 0.95,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );
        
        final scaleAnimation = Tween<double>(
          begin: scaleBegin,
          end: 1.0,
        ).animate(fadeAnimation);
        
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

  /// انتقال Hero مخصص مع تأثيرات إضافية
  static Widget createHeroTransition({
    required String heroTag,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Hero(
      tag: heroTag,
      transitionOnUserGestures: true,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }

  /// تأثير Shimmer للتحميل
  static Widget createShimmerLoading({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return AnimatedContainer(
      duration: duration,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
        ),
      ),
      child: child,
    );
  }

  /// تأثير Bounce للأزرار
  static Widget createBounceButton({
    required Widget child,
    required VoidCallback onTap,
    Duration duration = const Duration(milliseconds: 150),
    double scale = 0.95,
  }) {
    return _BounceButton(
      onTap: onTap,
      duration: duration,
      scale: scale,
      child: child,
    );
  }

  /// تأثير Ripple مخصص
  static Widget createCustomRipple({
    required Widget child,
    required VoidCallback onTap,
    Color rippleColor = Colors.white24,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        splashColor: rippleColor,
        highlightColor: rippleColor.withAlpha((0.1 * 255).round()),
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  /// تأثير Pull-to-Refresh مخصص
  static Widget createCustomRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color color = const Color(0xFFD62F26),
    String refreshText = 'جاري التحديث...',
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color,
      backgroundColor: Colors.white,
      strokeWidth: 3.0,
      displacement: 60.0,
      child: child,
    );
  }

  /// تأثير Floating Action Button محسن
  static Widget createAnimatedFAB({
    required VoidCallback onPressed,
    required IconData icon,
    String? label,
    Color backgroundColor = const Color(0xFFD62F26),
    Color foregroundColor = Colors.white,
    bool isExtended = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        icon: Icon(icon),
        label: Text(label ?? ''),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 8.0,
        highlightElevation: 12.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  /// تأثير Loading مع نقاط متحركة
  static Widget createLoadingDots({
    Color color = const Color(0xFFD62F26),
    double size = 8.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return _LoadingDots(
      color: color,
      size: size,
      duration: duration,
    );
  }

  /// تأثير Slide-up للقوائم السفلية
  static void showAnimatedBottomSheet({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    Color backgroundColor = Colors.white,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withAlpha(76),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  /// تأثير Staggered Animation للقوائم
  static Widget createStaggeredList({
    required List<Widget> children,
    Duration delay = const Duration(milliseconds: 100),
    Axis direction = Axis.vertical,
  }) {
    return _StaggeredList(
      delay: delay,
      direction: direction,
      children: children,
    );
  }
}

/// زر Bounce مخصص
class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  final double scale;

  const _BounceButton({
    required this.child,
    required this.onTap,
    required this.duration,
    required this.scale,
  });

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Loading dots متحركة
class _LoadingDots extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const _LoadingDots({
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: widget.duration,
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // تشغيل النقاط بتأخير متدرج
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withAlpha(25 + (0.7 * _animations[index].value * 255).round()),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// قائمة Staggered متحركة
class _StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Axis direction;

  const _StaggeredList({
    required this.children,
    required this.delay,
    required this.direction,
  });

  @override
  State<_StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<_StaggeredList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.children.length, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      final offset = widget.direction == Axis.vertical
          ? const Offset(0.0, 0.3)
          : const Offset(0.3, 0.0);
      return Tween<Offset>(begin: offset, end: Offset.zero).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    // تشغيل الرسوم المتحركة بتأخير متدرج
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.delay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
            children: _buildAnimatedChildren(),
          )
        : Row(
            children: _buildAnimatedChildren(),
          );
  }

  List<Widget> _buildAnimatedChildren() {
    return List.generate(widget.children.length, (index) {
      return AnimatedBuilder(
        animation: _controllers[index],
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimations[index],
            child: SlideTransition(
              position: _slideAnimations[index],
              child: widget.children[index],
            ),
          );
        },
      );
    });
  }
}

/// توسيعات مفيدة للتحريك
extension AnimationExtensions on Widget {
  /// إضافة تأثير Fade In
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) {
    return _AnimatedFadeIn(
      duration: duration,
      delay: delay,
      child: this,
    );
  }

  /// إضافة تأثير Slide In
  Widget slideIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Offset begin = const Offset(0.0, 0.3),
  }) {
    return _AnimatedSlideIn(
      duration: duration,
      delay: delay,
      begin: begin,
      child: this,
    );
  }
}

class _AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const _AnimatedFadeIn({
    required this.child,
    required this.duration,
    required this.delay,
  });

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class _AnimatedSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;

  const _AnimatedSlideIn({
    required this.child,
    required this.duration,
    required this.delay,
    required this.begin,
  });

  @override
  State<_AnimatedSlideIn> createState() => _AnimatedSlideInState();
}

class _AnimatedSlideInState extends State<_AnimatedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<Offset>(begin: widget.begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}
