import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:godarna/constants/app_icons.dart';

/// A unified network image widget with shimmer placeholder and error fallback.
/// Keeps API simple: just pass url and it will handle caching and placeholders.
class AppImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    Widget child;
    if (!hasUrl) {
      child = _buildError();
    } else {
      child = LayoutBuilder(
        builder: (context, constraints) {
          // Provide cacheWidth to reduce memory when possible
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final cacheWidth = constraints.maxWidth.isFinite
              ? (constraints.maxWidth * dpr).round()
              : null;
          return CachedNetworkImage(
            imageUrl: url!,
            fit: fit,
            alignment: alignment,
            width: width,
            height: height,
            memCacheWidth: cacheWidth,
            placeholder: (context, _) => _buildShimmer(constraints),
            errorWidget: (context, _, __) => _buildError(),
          );
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildShimmer(BoxConstraints constraints) {
    return Builder(
      builder: (context) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          width: width ?? constraints.maxWidth,
          height: height ?? constraints.maxHeight,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          AppIcons.imageOff,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 48,
        ),
      ),
    );
  }
}
