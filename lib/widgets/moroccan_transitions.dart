import 'package:flutter/material.dart';

/// انتقالات مغربية مخصصة للصفحات
class MoroccanPageTransition extends PageRouteBuilder {
  final Widget child;
  final TransitionType type;
  
  MoroccanPageTransition({
    required this.child,
    this.type = TransitionType.slideFromRight,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(child, animation, type);
          },
        );
  
  static Widget _buildTransition(Widget child, Animation<double> animation, TransitionType type) {
    switch (type) {
      case TransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      case TransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      case TransitionType.fadeScale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      case TransitionType.moroccanPattern:
        return _MoroccanPatternTransition(animation: animation, child: child);
    }
  }
}

enum TransitionType {
  slideFromRight,
  slideFromBottom,
  fadeScale,
  moroccanPattern,
}

/// انتقال بنمط مغربي مخصص
class _MoroccanPatternTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  
  const _MoroccanPatternTransition({
    required this.animation,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ClipPath(
          clipper: _MoroccanClipper(animation.value),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

class _MoroccanClipper extends CustomClipper<Path> {
  final double progress;
  
  _MoroccanClipper(this.progress);
  
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final animatedWidth = width * progress;
    final animatedHeight = height * progress;
    
    if (progress == 0) return path;
    
    // إنشاء شكل مغربي متدرج
    path.moveTo(0, height / 2);
    path.quadraticBezierTo(
      animatedWidth * 0.2, height / 2 - animatedHeight * 0.3,
      animatedWidth * 0.5, height / 2,
    );
    path.quadraticBezierTo(
      animatedWidth * 0.8, height / 2 + animatedHeight * 0.3,
      animatedWidth, height / 2,
    );
    path.lineTo(animatedWidth, height);
    path.lineTo(0, height);
    path.close();
    
    return path;
  }
  
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// مكون للانتقالات التفاعلية
class MoroccanInteractiveTransition extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  
  const MoroccanInteractiveTransition({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 200),
  });
  
  @override
  State<MoroccanInteractiveTransition> createState() => _MoroccanInteractiveTransitionState();
}

class _MoroccanInteractiveTransitionState extends State<MoroccanInteractiveTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
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
  
  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }
  
  void _handleTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(51),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// مكون للحركة المتدرجة للقوائم
class MoroccanStaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  
  const MoroccanStaggeredList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });
  
  @override
  State<MoroccanStaggeredList> createState() => _MoroccanStaggeredListState();
}

class _MoroccanStaggeredListState extends State<MoroccanStaggeredList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<Animation<Offset>> _slideAnimations;
  
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();
    
    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: widget.curve));
    }).toList();
    
    _startAnimations();
  }
  
  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(widget.delay);
      if (mounted) {
        _controllers[i].forward();
      }
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
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return FadeTransition(
              opacity: _animations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: widget.children[index],
              ),
            );
          },
        );
      }),
    );
  }
}

/// مكون لتأثير الموجة المغربية
class MoroccanRippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;
  
  const MoroccanRippleEffect({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor = const Color(0xFFAE392C),
  });
  
  @override
  State<MoroccanRippleEffect> createState() => _MoroccanRippleEffectState();
}

class _MoroccanRippleEffectState extends State<MoroccanRippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset? _tapPosition;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward().then((_) {
      _controller.reset();
      widget.onTap?.call();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: CustomPaint(
        painter: _tapPosition != null
            ? _RipplePainter(
                animation: _animation,
                center: _tapPosition!,
                color: widget.rippleColor,
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset center;
  final Color color;
  
  _RipplePainter({
    required this.animation,
    required this.center,
    required this.color,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha((77 * (1 - animation.value)).round())
      ..style = PaintingStyle.fill;
    
    final radius = size.width * animation.value;
    canvas.drawCircle(center, radius, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
