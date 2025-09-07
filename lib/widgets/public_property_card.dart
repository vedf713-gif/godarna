import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/models/public_property.dart';
import 'package:godarna/widgets/app_image.dart';
import 'package:godarna/constants/app_icons.dart';

class PublicPropertyCard extends StatelessWidget {
  final PublicProperty item;
  final VoidCallback? onTap;
  const PublicPropertyCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppTokens.r16,
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 12, // متناسق مع شبكة العرض
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.photo != null && item.photo!.isNotEmpty
                          ? AppImage(url: item.photo!, fit: BoxFit.cover)
                          : Container(
                              color: cs.onSurfaceVariant,
                              child: Icon(
                                AppIcons.imageOff,
                                color: cs.onSurfaceVariant,
                                size: 48,
                              ),
                            ),
                    ),
                    // تدرّج خفيف أسفل الصورة لتحسين قابلية القراءة للباجات
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 68,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(140),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // شارة السعر أسفل اليسار
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.surface.withAlpha(235),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(
                          item.displayPrice,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    // تقييم في الأعلى يمين
                    if (item.rating != null && item.rating! > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.surface.withAlpha(235),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.star,
                                  size: 16, color: Theme.of(context).colorScheme.tertiary),
                              const SizedBox(width: 4),
                              Text(
                                item.rating!.toStringAsFixed(1),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // المسافة أسفل اليمين إن توفرت
                    if (item.distanceKm != null)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.surface.withAlpha(235),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Text(
                            '${item.distanceKm!.toStringAsFixed(1)} كم',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(AppIcons.location,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.city,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.displayPrice,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
