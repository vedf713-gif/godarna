import 'package:flutter/material.dart';

/// نظام ألوان متقدم يُحاكي Airbnb مع لمسة مغربية أصيلة
/// - يستخدم ألوانًا ديناميكية حسب الثيم
/// - يدعم Material 3
/// - يعتمد على `colorScheme` بدل الألوان الثابتة
class AppColors {
  // ========================================================================
  // === 1. الألوان الأساسية (Brand Colors) - مثل Airbnb
  // ========================================================================

  /// الأحمر الحيوي - لون العلامة التجارية (مثل دم الحناء)
  static const Color primaryRed = Color(0xFFD62F26);

  /// الأحمر الفاتح - للتنبيهات والتأكيد
  static const Color primaryRedLight = Color(0xFFFF5C52);

  /// الأحمر الداكن - للأزرار والنصوص
  static const Color primaryRedDark = Color(0xFFB31E18);

  // ========================================================================
  // === 2. ألوان فرعية مستوحاة من المغرب
  // ========================================================================

  /// الذهب الصحراوي - للعناصر المميزة
  static const Color saharaGold = Color(0xFFF5C518);

  /// الأزرق الأطلسي - للعناصر الجوية
  static const Color atlasBlue = Color(0xFF1E90FF);
  static const Color atlasBlueDark = Color(0xFF0066CC);
  static const Color atlasBlueLight = Color(0xFF66B2FF);

  /// الأخضر النعناعي - للنجاح والطبيعة
  static const Color mintGreen = Color(0xFF00D1B2);

  /// البرتقالي الحار - للتنبيهات والطاقة
  static const Color spiceOrange = Color(0xFFFF6B35);

  /// البنفسجي الملكي - للرفاهية
  static const Color royalPurple = Color(0xFF9B59B6);

  // ========================================================================
  // === 3. درجات الرمادي (Neutrals) - داعمة للوضع الغامق
  // ========================================================================

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // رمادي دقيق (للمحتوى والحدود)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ========================================================================
  // === 4. ألوان الخلفية (Backgrounds)
  // ========================================================================

  // الخلفية الأساسية
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundPrimaryDark = Color(0xFF0F0F0F);

  // الخلفية الثانوية (البطاقات، الأقسام)
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color backgroundSecondaryDark = Color(0xFF1A1A1A);

  // الخلفية البديلة (للتمييز)
  static const Color backgroundTertiary = Color(0xFFFFFFFF);
  static const Color backgroundTertiaryDark = Color(0xFF252525);

  // الخلفية الخاصة بالبطاقات
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundCardDark = Color(0xFF1A1A1A);

  // شفاف جزئي للـ Overlay
  static const Color backgroundOverlay = Color(0x80000000);

  // ========================================================================
  // === 5. حدود (Borders)
  // ========================================================================

  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF9E9E9E);
  static const Color borderFocus = Color(0xFFD62F26);

  // دارك مود
  static const Color borderLightDark = Color(0xFF2C2C2C);
  static const Color borderMediumDark = Color(0xFF424242);

  // ========================================================================
  // === 6. ألوان النص (Text)
  // ========================================================================

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1A1A1A);

  // دارك مود
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);
  static const Color textTertiaryDark = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ========================================================================
  // === 7. ألوان الحالة (Status Colors)
  // ========================================================================

  static const Color success = Color(0xFF00D1B2);
  static const Color successLight = Color(0xFF48E5C2);
  static const Color successSoft = Color(0xFFE0F7FA);

  static const Color warning = Color(0xFFFF6B35);
  static const Color warningLight = Color(0xFFFF9A6A);
  static const Color warningSoft = Color(0xFFFFF3E0);

  static const Color error = Color(0xFFFF3860);
  static const Color errorLight = Color(0xFFFF6B8A);
  static const Color errorSoft = Color(0xFFFFEBEE);

  static const Color info = Color(0xFF1E90FF);
  static const Color infoLight = Color(0xFF66B2FF);
  static const Color infoSoft = Color(0xFFE3F2FD);

  // ========================================================================
  // === 8. ألوان أنواع العقارات
  // ========================================================================

  static const Color apartment = Color(0xFF1E90FF);
  static const Color villa = Color(0xFF00D1B2);
  static const Color riad = Color(0xFFFF6B35);
  static const Color studio = Color(0xFF9B59B6);
  static const Color hotel = Color(0xFFF5C518);
  static const Color guesthouse = Color(0xFFD62F26);

  // ========================================================================
  // === 9. التدرجات (Gradients) - تشبه Airbnb
  // ========================================================================

  /// تدرج الأحمر الأساسي (مثل زر Airbnb)
  static const List<Color> primaryGradient = [
    Color(0xFFD62F26),
    Color(0xFFFF5C52),
  ];

  /// تدرج الذهب الصحراوي
  static const List<Color> goldGradient = [
    Color(0xFFF5C518),
    Color(0xFFFFDB58),
  ];

  /// تدرج الأزرق الأطلسي
  static const List<Color> blueGradient = [
    Color(0xFF1E90FF),
    Color(0xFF66B2FF),
  ];

  /// تدرج الشمس (Sunset) - من الأحمر إلى الذهبي
  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B35),
    Color(0xFFF5C518),
    Color(0xFFFFDB58),
  ];

  /// تدرج الزليج - ألوان الموزاييك المغربية
  static const List<Color> zelligeGradient = [
    Color(0xFF00D1B2),
    Color(0xFF1E90FF),
    Color(0xFF9B59B6),
  ];

  // ========================================================================
  // === 10. الظلال (Shadows)
  // ========================================================================

  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowDark = Color(0x1F000000);
  static const Color shadowColored = Color(0x33D62F26);

  // ========================================================================
  // === 11. تقييم (Rating)
  // ========================================================================

  static const Color ratingStar = Color(0xFFFFC107);
  static const Color ratingEmpty = Color(0xFFE2E8F0);

  // ========================================================================
  // === 12. دعم قديم (للتوافق)
  // ========================================================================

  static const Color secondaryOrange = spiceOrange;
  static const Color secondaryTurquoise = mintGreen;
  static const Color secondaryYellow = saharaGold;
  static const Color azureBlue = atlasBlue;
  static const Color fuchsia = royalPurple;
  static const Color grey = grey500;
  static const Color lightGrey = grey200;
  static const Color darkGrey = grey700;
  static const Color borderGrey = borderLight;
  static const Color borderLightGrey = grey100;
  static const Color backgroundGrey = backgroundSecondary;
  static const Color backgroundLightGrey = backgroundTertiary;
  static const Color backgroundSoft = backgroundSecondary;
  static const Color textLight = textTertiary;

  // تدرجات كلاسيكية
  static const List<Color> gradSunset = [primaryRed, secondaryOrange];
  static const List<Color> gradOasis = [secondaryTurquoise, azureBlue];
  static const List<Color> gradNeon = [fuchsia, secondaryTurquoise];

  // إضاءات نيون للوضع الداكن
  static const Color neonPrimary = Color(0xFFD62F26);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color neonTurquoise = Color(0xFF00D1B2);
  static const Color neonBlue = Color(0xFF1E90FF);
  static const Color neonPink = Color(0xFF9B59B6);
  static const Color neonGlowGreen = Color(0x4400D1B2); // شفاف
  static const Color neonGlowBlue = Color(0x441E90FF); // شفاف
}
