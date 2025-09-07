import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:godarna/constants/app_tokens.dart';

class Skeleton extends StatelessWidget {
  const Skeleton.rect({super.key, this.width, this.height, this.radius = 12})
      : isCircle = false,
        size = null;

  const Skeleton.circle({super.key, this.size = 40})
      : isCircle = true,
        width = null,
        height = null,
        radius = 9999;

  final double? width;
  final double? height;
  final double? size;
  final double radius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(102);
    final highlightColor =
        Theme.of(context).colorScheme.onSurface.withAlpha(20);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: AppTokens.dLong,
      child: Container(
        width: isCircle ? size : width,
        height: isCircle ? size : height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 6, this.itemHeight = 80});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, __) => Skeleton.rect(height: itemHeight),
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s12),
      itemCount: itemCount,
    );
  }
}
