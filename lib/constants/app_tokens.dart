import 'package:flutter/material.dart';

/// نظام التصميم (Design Tokens) لتطبيق GoDarna
/// مستوحى من Airbnb - بسيط، نظيف، وقابل للتوسع
/// يدعم Material 3 ويدمج مع AppColors وAppDimensions
class AppTokens {
  // ========================================================================
  // === 1. المسافات (Spacing Scale)
  // ========================================================================
  // مبنية على مضاعفات 4 (مبدأ 8pt grid)
  static const double zero = 0;
  static const double xs = 4; // Extra Small (for tight spaces)
  static const double sm = 8; // Small
  static const double md = 12; // Medium
  static const double lg = 16; // Large
  static const double xl = 20; // Extra Large
  static const double xxl = 24; // Double Extra Large
  static const double xxxl = 32; // Triple Extra Large
  static const double huge = 40; // For big sections
  static const double massive = 48; // For maximum spacing
  
  // اختصارات للمسافات
  static const double s4 = xs;
  static const double s6 = 6;
  static const double s8 = sm;
  static const double s12 = md;
  static const double s14 = 14;
  static const double s16 = lg;
  static const double s20 = xl;
  static const double s24 = xxl;
  static const double s32 = xxxl;

  // ========================================================================
  // === 2. الزوايا (Border Radius)
  // ========================================================================
  // أنواع الزوايا المستخدمة في Airbnb
  static const BorderRadius cornerTiny = BorderRadius.all(Radius.circular(4));
  static const BorderRadius cornerSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius cornerMedium =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius cornerLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius cornerXLarge =
      BorderRadius.all(Radius.circular(20));
  static const BorderRadius cornerXXLarge =
      BorderRadius.all(Radius.circular(24));
  static const BorderRadius cornerFull = BorderRadius.all(Radius.circular(999));

  // اختصارات شائعة
  static const BorderRadius r4 = cornerTiny;
  static const BorderRadius r8 = cornerSmall;
  static const BorderRadius r12 = cornerMedium;
  static const BorderRadius r16 = cornerLarge;
  static const BorderRadius r20 = cornerXLarge;
  static const BorderRadius r24 = cornerXXLarge;
  static const BorderRadius r100 = cornerFull;

  // ========================================================================
  // === 3. الارتفاعات (Elevation / Shadow)
  // ========================================================================
  // يستخدم Airbnb ظلالًا خفيفة جدًا
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 2;
  static const double elevationHigh = 4;
  static const double elevationCard = 8;
  static const double elevationModal = 12;

  // دالة مساعدة لإنشاء ظل يشبه Airbnb
  static BoxShadow shadowLow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDark ? Colors.black.withAlpha(15) : Colors.grey.withAlpha(15),
      blurRadius: 4,
      offset: const Offset(0, 2),
    );
  }

  static BoxShadow shadowMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDark ? Colors.black.withAlpha(20) : Colors.grey.withAlpha(20),
      blurRadius: 8,
      offset: const Offset(0, 4),
    );
  }

  static BoxShadow shadowHigh(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDark ? Colors.black.withAlpha(26) : Colors.grey.withAlpha(26),
      blurRadius: 12,
      offset: const Offset(0, 6),
    );
  }

  static BoxShadow shadowCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDark ? Colors.black.withAlpha(31) : Colors.grey.withAlpha(31),
      blurRadius: 16,
      offset: const Offset(0, 8),
    );
  }

  // ========================================================================
  // === 4. المدة (Durations)
  // ========================================================================
  // لأنيميشن سريع وسلس مثل Airbnb
  static const Duration durationInstant = Duration(milliseconds: 50);
  static const Duration durationQuick = Duration(milliseconds: 100);
  static const Duration durationShort = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationLong = Duration(milliseconds: 400);
  static const Duration durationXL = Duration(milliseconds: 500);
  
  // اختصارات للمدة
  static const Duration dTap = durationQuick;
  static const Duration dMedium = durationMedium;
  static const Duration dLong = durationLong;

  // ========================================================================
  // === 5. الشفافية (Opacity)
  // ========================================================================
  // أنماط شفافية تستخدم في Airbnb
  static const double opacityDisabled = 0.4;
  static const double opacityInteractive = 0.7;
  static const double opacityOverlay = 0.6;
  static const double opacityDim = 0.2;

  // ========================================================================
  // === 6. الشبكة (Grid)
  // ========================================================================
  // لتصميم القوائم والبطاقات
  static const double gridGap = 16;
  static const double gridGapLarge = 24;
  static const double cardPadding = 16;
  static const double sectionPadding = 20;

  // ========================================================================
  // === 7. الحدود (Border)
  // ========================================================================
  static const double borderWidthThin = 1;
  static const double borderWidthThick = 2;

  // ========================================================================
  // === 8. المقاييس النصية (Typography Scale)
  // ========================================================================
  // مقاييس خطوط تشبه Airbnb (استخدمها مع TextTheme)
  static const double textXSmall = 12;
  static const double textSmall = 14;
  static const double textBase = 16;
  static const double textMedium = 18;
  static const double textLarge = 20;
  static const double textXLarge = 24;
  static const double textXXLarge = 32;
  static const double textHuge = 40;

  // ========================================================================
  // === 9. زوايا الدوائر (Circular Radius)
  // ========================================================================
  static const BorderRadius circle = BorderRadius.all(Radius.circular(50));

  // ========================================================================
  // === 10. دالة مساعدة: Padding من AppTokens
  // ========================================================================
  /// يُستخدم لتحويل القيم إلى Padding
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.fromLTRB(
      left ?? horizontal ?? all ?? 0,
      top ?? vertical ?? all ?? 0,
      right ?? horizontal ?? all ?? 0,
      bottom ?? vertical ?? all ?? 0,
    );
  }

  // ========================================================================
  // === 11. دالة مساعدة: Margin من AppTokens
  // ========================================================================
  static EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.fromLTRB(
      left ?? horizontal ?? all ?? 0,
      top ?? vertical ?? all ?? 0,
      right ?? horizontal ?? all ?? 0,
      bottom ?? vertical ?? all ?? 0,
    );
  }
}
