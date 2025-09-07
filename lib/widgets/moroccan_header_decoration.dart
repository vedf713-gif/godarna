import 'dart:math' as math;
import 'package:flutter/material.dart';
// Colors derive from Theme.colorScheme to harmonize with light/dark themes

/// A soft Moroccan-inspired decorative overlay for auth headers.
/// No assets used. Pure shapes with gradients and low opacity.
class MoroccanHeaderDecoration extends StatelessWidget {
  final double height;
  const MoroccanHeaderDecoration({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft radial glow from top center
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: height * 0.9,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.8),
                    radius: 0.9,
                    colors: [
                      cs.primary.withAlpha(26),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // Subtle circle on top-left
            Positioned(
              top: 8,
              left: -10,
              child: _circle(68, cs.secondary.withAlpha(31)),
            ),

            // Subtle circle on top-right
            Positioned(
              top: -6,
              right: -14,
              child: _circle(84, cs.tertiary.withAlpha(26)),
            ),

            // Diamond motif center-left
            Positioned(
              top: height * 0.32,
              left: 24,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: _diamond(26, cs.primary.withAlpha(26)),
              ),
            ),

            // Diamond motif center-right smaller
            Positioned(
              top: height * 0.22,
              right: 28,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: _diamond(18, cs.secondary.withAlpha(31)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }

  Widget _diamond(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}
