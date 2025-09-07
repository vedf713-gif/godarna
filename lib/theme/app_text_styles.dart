import 'package:flutter/material.dart';

/// نظام موحد لأنماط النصوص في التطبيق
/// جميع أنماط النصوص مأخوذة من هذا الملف فقط
class AppTextStyles {
  AppTextStyles._();

  // === FONT WEIGHTS ===
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // === FONT SIZES ===
  static const double fontSize10 = 10.0;
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize13 = 13.0;
  static const double fontSize14 = 14.0;
  static const double fontSize15 = 15.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize22 = 22.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;
  static const double fontSize36 = 36.0;
  static const double fontSize40 = 40.0;
  static const double fontSize48 = 48.0;

  // === LINE HEIGHTS ===
  static const double lineHeight1_2 = 1.2;
  static const double lineHeight1_3 = 1.3;
  static const double lineHeight1_4 = 1.4;
  static const double lineHeight1_5 = 1.5;
  static const double lineHeight1_6 = 1.6;

  // === LETTER SPACING ===
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingXWide = 1.0;

  // === BASE TEXT STYLES ===
  
  // Display Styles (للعناوين الكبيرة)
  static const TextStyle displayLarge = TextStyle(
    fontSize: fontSize48,
    fontWeight: bold,
    height: lineHeight1_2,
    letterSpacing: letterSpacingTight,
    fontFamily: 'Cairo',
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: fontSize40,
    fontWeight: bold,
    height: lineHeight1_2,
    letterSpacing: letterSpacingTight,
    fontFamily: 'Cairo',
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: fontSize32,
    fontWeight: bold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  // Headline Styles (للعناوين المتوسطة)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: fontSize28,
    fontWeight: semiBold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: fontSize24,
    fontWeight: semiBold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: fontSize22,
    fontWeight: semiBold,
    height: lineHeight1_4,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  // Title Styles (للعناوين الصغيرة)
  static const TextStyle titleLarge = TextStyle(
    fontSize: fontSize20,
    fontWeight: semiBold,
    height: lineHeight1_4,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: fontSize18,
    fontWeight: medium,
    height: lineHeight1_4,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: fontSize16,
    fontWeight: medium,
    height: lineHeight1_4,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  // Body Styles (للنصوص العادية)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: fontSize16,
    fontWeight: regular,
    height: lineHeight1_5,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: fontSize14,
    fontWeight: regular,
    height: lineHeight1_5,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSize12,
    fontWeight: regular,
    height: lineHeight1_4,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  // Label Styles (للتسميات والأزرار)
  static const TextStyle labelLarge = TextStyle(
    fontSize: fontSize16,
    fontWeight: semiBold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: fontSize14,
    fontWeight: medium,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: fontSize12,
    fontWeight: medium,
    height: lineHeight1_3,
    letterSpacing: letterSpacingWide,
    fontFamily: 'Cairo',
  );

  // === SPECIALIZED STYLES ===

  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: fontSize16,
    fontWeight: semiBold,
    height: lineHeight1_2,
    letterSpacing: letterSpacingWide,
    fontFamily: 'Cairo',
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: fontSize14,
    fontWeight: semiBold,
    height: lineHeight1_2,
    letterSpacing: letterSpacingWide,
    fontFamily: 'Cairo',
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: fontSize12,
    fontWeight: semiBold,
    height: lineHeight1_2,
    letterSpacing: letterSpacingWide,
    fontFamily: 'Cairo',
  );

  // Caption Styles
  static const TextStyle caption = TextStyle(
    fontSize: fontSize11,
    fontWeight: regular,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: fontSize11,
    fontWeight: semiBold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  // Overline Style
  static const TextStyle overline = TextStyle(
    fontSize: fontSize10,
    fontWeight: medium,
    height: lineHeight1_3,
    letterSpacing: letterSpacingXWide,
    fontFamily: 'Cairo',
  );

  // === PROPERTY SPECIFIC STYLES ===
  static const TextStyle propertyTitle = titleLarge;
  static const TextStyle propertyPrice = TextStyle(
    fontSize: fontSize20,
    fontWeight: bold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );
  static const TextStyle propertyLocation = bodyMedium;
  static const TextStyle propertyDescription = bodyMedium;

  // === CARD STYLES ===
  static const TextStyle cardTitle = titleMedium;
  static const TextStyle cardSubtitle = bodySmall;
  static const TextStyle cardContent = bodyMedium;

  // === APP BAR STYLES ===
  static const TextStyle appBarTitle = titleLarge;
  static const TextStyle appBarSubtitle = bodyMedium;

  // === NAVIGATION STYLES ===
  static const TextStyle navLabel = labelSmall;
  static const TextStyle navLabelSelected = TextStyle(
    fontSize: fontSize12,
    fontWeight: semiBold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingWide,
    fontFamily: 'Cairo',
  );

  // === FORM STYLES ===
  static const TextStyle inputLabel = labelMedium;
  static const TextStyle inputText = bodyMedium;
  static const TextStyle inputHint = TextStyle(
    fontSize: fontSize14,
    fontWeight: regular,
    height: lineHeight1_5,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );
  static const TextStyle inputError = TextStyle(
    fontSize: fontSize12,
    fontWeight: regular,
    height: lineHeight1_3,
    letterSpacing: letterSpacingNormal,
    fontFamily: 'Cairo',
  );

  // === CHIP STYLES ===
  static const TextStyle chipLabel = labelSmall;
  static const TextStyle chipLabelSelected = TextStyle(
    fontSize: fontSize12,
    fontWeight: semiBold,
    height: lineHeight1_3,
    letterSpacing: letterSpacingWide,
    fontFamily: 'Cairo',
  );

  // === HELPER METHODS ===
  
  /// إنشاء TextTheme موحد للتطبيق
  static TextTheme createTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: colorScheme.onSurface),
      displayMedium: displayMedium.copyWith(color: colorScheme.onSurface),
      displaySmall: displaySmall.copyWith(color: colorScheme.onSurface),
      
      headlineLarge: headlineLarge.copyWith(color: colorScheme.onSurface),
      headlineMedium: headlineMedium.copyWith(color: colorScheme.onSurface),
      headlineSmall: headlineSmall.copyWith(color: colorScheme.onSurface),
      
      titleLarge: titleLarge.copyWith(color: colorScheme.onSurface),
      titleMedium: titleMedium.copyWith(color: colorScheme.onSurface),
      titleSmall: titleSmall.copyWith(color: colorScheme.onSurface),
      
      bodyLarge: bodyLarge.copyWith(color: colorScheme.onSurface),
      bodyMedium: bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      bodySmall: bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
      
      labelLarge: labelLarge.copyWith(color: colorScheme.onSurface),
      labelMedium: labelMedium.copyWith(color: colorScheme.onSurface),
      labelSmall: labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}
