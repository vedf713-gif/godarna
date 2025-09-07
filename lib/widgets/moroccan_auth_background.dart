import 'package:flutter/material.dart';

/// خلفية مغربية مخصصة لشاشات المصادقة
class MoroccanAuthBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  
  const MoroccanAuthBackground({
    super.key,
    required this.child,
    this.showPattern = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Stack(
        children: [
          // زخارف هندسية بسيطة
          if (showPattern) ...[
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(13),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(8),
                ),
              ),
            ),
          ],
          
          // المحتوى الرئيسي
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// بطاقة مغربية لنماذج المصادقة
class MoroccanAuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  
  const MoroccanAuthCard({
    super.key,
    required this.child,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(26),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withAlpha(51),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
