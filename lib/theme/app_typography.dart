import 'package:flutter/material.dart';

class AppTypography {
  // === FONT CONFIGURATION ===
  static const _primaryFont = 'Cairo';
  static const List<String> _fallbackFonts = ['Poppins', 'Roboto', 'Arial'];

  // === FONT WEIGHTS ===
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // === LETTER SPACING ===
  static const double tightSpacing = -0.5;
  static const double normalSpacing = 0.0;
  static const double wideSpacing = 0.5;
  static const double extraWideSpacing = 1.0;

  static TextTheme textTheme(ColorScheme scheme) {
    return TextTheme(
      // === DISPLAY STYLES (Hero text, large headings) ===
      displayLarge: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 64,
        fontWeight: extraBold,
        height: 1.0,
        letterSpacing: tightSpacing,
        color: scheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 52,
        fontWeight: bold,
        height: 1.1,
        letterSpacing: tightSpacing,
        color: scheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 40,
        fontWeight: bold,
        height: 1.15,
        letterSpacing: normalSpacing,
        color: scheme.onSurface,
      ),

      // === HEADLINE STYLES (Section headings) ===
      headlineLarge: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 36,
        fontWeight: bold,
        height: 1.2,
        letterSpacing: normalSpacing,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 32,
        fontWeight: bold,
        height: 1.25,
        letterSpacing: normalSpacing,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 28,
        fontWeight: semiBold,
        height: 1.3,
        letterSpacing: normalSpacing,
        color: scheme.onSurface,
      ),

      // === TITLE STYLES (Card titles, form labels) ===
      titleLarge: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 24,
        fontWeight: semiBold,
        height: 1.35,
        letterSpacing: normalSpacing,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 18,
        fontWeight: semiBold,
        height: 1.4,
        letterSpacing: wideSpacing,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 16,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: wideSpacing,
        color: scheme.onSurface,
      ),

      // === BODY STYLES (Main content text) ===
      bodyLarge: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 18,
        fontWeight: regular,
        height: 1.6,
        letterSpacing: normalSpacing,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 16,
        fontWeight: regular,
        height: 1.6,
        letterSpacing: normalSpacing,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 14,
        fontWeight: regular,
        height: 1.5,
        letterSpacing: normalSpacing,
        color: scheme.onSurface.withAlpha((0.8 * 255).toInt()),
      ),

      // === LABEL STYLES (Buttons, chips, badges) ===
      labelLarge: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 16,
        fontWeight: semiBold,
        height: 1.2,
        letterSpacing: wideSpacing,
        color: scheme.onPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 14,
        fontWeight: semiBold,
        height: 1.2,
        letterSpacing: wideSpacing,
        color: scheme.onPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 12,
        fontWeight: medium,
        height: 1.2,
        letterSpacing: extraWideSpacing,
        color: scheme.onPrimary,
      ),
    );
  }

  // === CUSTOM TEXT STYLES ===
  static TextStyle heroTitle(ColorScheme scheme) => TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 48,
        fontWeight: extraBold,
        height: 1.1,
        letterSpacing: tightSpacing,
        color: scheme.onSurface,
      );

  static TextStyle propertyPrice(ColorScheme scheme) => TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 20,
        fontWeight: bold,
        height: 1.2,
        letterSpacing: normalSpacing,
        color: scheme.primary,
      );

  static TextStyle caption(ColorScheme scheme) => TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 12,
        fontWeight: regular,
        height: 1.4,
        letterSpacing: wideSpacing,
        color: scheme.onSurface.withAlpha((0.6 * 255).toInt()),
      );

  static TextStyle overline(ColorScheme scheme) => TextStyle(
        fontFamily: _primaryFont,
        fontFamilyFallback: _fallbackFonts,
        fontSize: 10,
        fontWeight: medium,
        height: 1.6,
        letterSpacing: extraWideSpacing,
        color: scheme.onSurface.withAlpha((0.6 * 255).toInt()),
      );
}
