import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:godarna/constants/app_tokens.dart';

class PublicPropertyCardSkeleton extends StatelessWidget {
  const PublicPropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppTokens.r16,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _shimmerBox(context: context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerLine(context: context, width: 160, height: 16),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    _circle(context, 16),
                    const SizedBox(width: AppTokens.s6),
                    _shimmerLine(context: context, width: 100, height: 12),
                    const Spacer(),
                    _shimmerLine(context: context, width: 40, height: 12),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                _shimmerLine(context: context, width: 80, height: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _shimmerBox(
      {double? width, double? height, required BuildContext context}) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.onSurfaceVariant;
    final highlight = cs.surface;
    return Shimmer.fromColors(
      baseColor: base.withAlpha(102),
      highlightColor: highlight.withAlpha(179),
      child: Container(
        width: width,
        height: height,
        color: base,
      ),
    );
  }

  Widget _shimmerLine(
      {required BuildContext context,
      required double width,
      required double height}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
          width: width, height: height, child: _shimmerBox(context: context)),
    );
  }

  Widget _circle(BuildContext context, double size) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.onSurfaceVariant;
    final highlight = cs.surface;
    return Shimmer.fromColors(
      baseColor: base.withAlpha(102),
      highlightColor: highlight.withAlpha(179),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: base,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
