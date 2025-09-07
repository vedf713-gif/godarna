import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late AnimationController _textController;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // تحريك الشعار (تحجيم)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // تحريك النص (ظهور)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
    );

    // تشغيل التحريك
    _logoController.forward();
    _textController.forward();

    // تهيئة التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeApp();
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      // انتظر 2.5 ثانية كحد أدنى
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        if (authProvider.isAuthenticated) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44); // Airbnb Red

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // === 1. App Logo ===
            ScaleTransition(
              scale: _logoScale,
              child: const AppLogo(
                heroTag: 'app_logo',
                size: 100,
                backgroundColor: Colors.transparent,
                borderRadius: 20,
                withShadow: true,
                imagePath: 'assets/images/app_icon.png',
              ),
            ),

            const SizedBox(height: 24),

            // === 2. App Name ===
            FadeTransition(
              opacity: _textOpacity,
              child: const Text(
                'GoDarna',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // === 3. Tagline ===
            FadeTransition(
              opacity: _textOpacity,
              child: Text(
                'استكشف الإقامة المغربية الأصيلة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // === 4. Loading Indicator ===
            FadeTransition(
              opacity: _textOpacity,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: _LoadingSpinner(color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === بديل بسيط للـ Spinner ===
class _LoadingSpinner extends StatefulWidget {
  final Color color;
  const _LoadingSpinner({required this.color});

  @override
  State<_LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<_LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _SpinnerPainter(progress: _ctrl.value, color: widget.color),
          size: const Size(40, 40),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = color;

    final rect = Offset.zero & size;
    final start = progress * 2 * 3.14159;
    const sweep = 2 * 3.14159 * 0.7; // 70% of circle
    canvas.drawArc(rect.deflate(6), start, sweep, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
