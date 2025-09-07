import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';

/// BouncyTap: يضيف تأثير قفزة لطيف عند الضغط دون تغيير منطق onTap.
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = AppTokens.dTap,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _pressed = false;

  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
