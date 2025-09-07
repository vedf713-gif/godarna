import 'package:flutter/material.dart';
import 'package:godarna/widgets/app_image.dart';
import 'package:godarna/widgets/bouncy_tap.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/models/property_model.dart';

class PropertyCardCompact extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;

  const PropertyCardCompact({
    super.key,
    required this.property,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BouncyTap(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        width: 200, // Increased width
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted horizontal margin
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppDimensions.borderRadiusLarge,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // black with 10% opacity
              blurRadius: 12,
              offset: Offset(0, 6),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Color(0x14000000), // black with 8% opacity
              blurRadius: 16,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
          ]
        ),
        child: ClipRRect(
          borderRadius: AppDimensions.borderRadiusLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- الصورة ---
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: property.photos.isNotEmpty
                        ? AppImage(
                            url: property.photos.first,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: const Color(0x1A000000), // Black with 10% opacity
                            child: Icon(AppIcons.imageOff,
                                size: 32, color: cs.onSurfaceVariant),
                          ),
                  ),

                  //سعر العقار
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5), // Slightly off-white
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cs.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        property.displayPrice,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  //شريط "موصّل"
                  if (property.isVerified)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E00), // اللون البرتقالي
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Recommandé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // --- المعلومات ---
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //العنوان
                    Text(
                      property.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Reduced from 16
                        color: cs.onSurface,
                        height: 1.2, // Reduced from 1.3
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    //الموقع
                    Row(
                      children: [
                        const Icon(AppIcons.location, size: 12, color: Color(0xFFFF3A44)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.city}, ${property.region}',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, 
                                fontSize: 13,
                                height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // الغرف والضيوف
                    Row(
                      children: [
                        const Icon(AppIcons.bed,
                            size: 14, color: Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Text('${property.bedrooms}ch.',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, 
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        const Icon(AppIcons.person,
                            size: 14, color: Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Text('${property.maxGuests}pers.',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, 
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),

                    const SizedBox(height: 6),

                    //التقييم مع تعديل المسافات
                    if (property.rating > 0)
                    const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(AppIcons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            property.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (property.reviewCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${property.reviewCount})',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 6),

                    //السعر
                    Row(
                      children: [
                        Text(
                          '${property.pricePerNight.toInt()} DH',
                          style: const TextStyle(
                            color: Color(0xFFE67E00),
                            fontSize: 18, // Increased font size
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('/ nuit',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, 
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),

                    // تمت إزالة صورة صاحب العقار
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
