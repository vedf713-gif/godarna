import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godarna/constants/app_colors.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/theme/app_text_styles.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color? success;
  final Color? warning;
  final Color? info;

  @override
  CustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      info: Color.lerp(info, other.info, t),
    );
  }
}

class AppTheme {
  AppTheme._();

  // === LIGHT THEME ===
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      // Primary colors
      primary: AppColors.primaryRed,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryRedLight,
      onPrimaryContainer: AppColors.primaryRedDark,

      // Secondary colors
      secondary: AppColors.atlasBlue,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.atlasBlueDark,
      onSecondaryContainer: AppColors.atlasBlueLight,

      // Tertiary colors
      tertiary: AppColors.atlasBlue,
      onTertiary: AppColors.textOnPrimary,
      tertiaryContainer: AppColors.atlasBlueDark,
      onTertiaryContainer: AppColors.atlasBlueLight,

      // Surface colors
      surface: AppColors.backgroundPrimary,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,

      // Error colors
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.error,

      // Outline colors
      outline: AppColors.borderMedium,
      outlineVariant: AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Cairo',
      textTheme: AppTextStyles.createTextTheme(colorScheme),

      // === APP BAR THEME ===
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppDimensions.elevationNone,
        scrolledUnderElevation: AppDimensions.elevationSmall,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // === BOTTOM APP BAR THEME ===
      bottomAppBarTheme: const BottomAppBarTheme(
        color: AppColors.backgroundPrimary,
      ),

      // === ELEVATED BUTTON THEME ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.textOnPrimary,
          elevation: AppDimensions.elevationSmall,
          shadowColor: AppColors.shadowColored,
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLarge,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          minimumSize: const Size.fromHeight(56),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // === OUTLINED BUTTON THEME ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          side: const BorderSide(
            color: AppColors.primaryRed,
            width: AppDimensions.borderWidthThin,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLarge,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          minimumSize: const Size.fromHeight(56),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryRed,
          ),
        ),
      ),

      // === TEXT BUTTON THEME ===
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLarge,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          minimumSize: const Size.fromHeight(56),
          textStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryRed,
          ),
        ),
      ),

      // === FLOATING ACTION BUTTON THEME ===
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppDimensions.elevationMedium,
        shape: CircleBorder(),
      ),

      // === CARD THEME ===
      cardTheme: const CardThemeData(
        color: AppColors.backgroundSecondary,
        shadowColor: AppColors.shadowLight,
        elevation: AppDimensions.elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
        ),
        margin: AppDimensions.paddingAll8,
      ),

      // === CHIP THEME ===
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedColor: AppColors.primaryRed,
        disabledColor: AppColors.backgroundSecondary,
        deleteIconColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
        padding: AppDimensions.chipPadding,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.chipBorderRadius,
        ),
        side: const BorderSide(color: AppColors.borderLight),
        secondarySelectedColor: AppColors.primaryRed,
        checkmarkColor: AppColors.textOnPrimary,
      ),

      // === INPUT DECORATION THEME ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        border: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(
            color: AppColors.primaryRed,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        contentPadding: AppDimensions.inputFieldPadding,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),

      // === ICON THEME ===
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppDimensions.iconMedium,
      ),

      // === BOTTOM NAVIGATION BAR THEME ===
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundPrimary,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationLarge,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // === CHECKBOX THEME ===
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryRed;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(
          color: AppColors.borderMedium,
          width: AppDimensions.borderWidthThick,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXSmall,
        ),
      ),

      // === RADIO THEME ===
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryRed;
          }
          return AppColors.borderMedium;
        }),
      ),

      // === EXTENSIONS ===
      extensions: const <ThemeExtension<dynamic>>[
        CustomColors(
          success: AppColors.success,
          warning: AppColors.warning,
          info: AppColors.atlasBlue,
        ),
      ],
    );
  }

  // === DARK THEME ===
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      // Primary colors
      primary: AppColors.primaryRed,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryRedDark,
      onPrimaryContainer: AppColors.primaryRedLight,

      // Secondary colors
      secondary: AppColors.atlasBlue,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.atlasBlueDark,
      onSecondaryContainer: AppColors.atlasBlueLight,

      // Tertiary colors
      tertiary: AppColors.atlasBlue,
      onTertiary: AppColors.textOnPrimary,
      tertiaryContainer: AppColors.atlasBlueDark,
      onTertiaryContainer: AppColors.atlasBlueLight,

      // Surface colors
      surface: AppColors.backgroundPrimaryDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,

      // Error colors
      error: AppColors.errorLight,
      onError: AppColors.black,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.errorSoft,

      // Outline colors
      outline: AppColors.borderMediumDark,
      outlineVariant: AppColors.borderLightDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Cairo',
      textTheme: AppTextStyles.createTextTheme(colorScheme).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),

      // === APP BAR THEME ===
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryRedDark,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppDimensions.elevationNone,
        scrolledUnderElevation: AppDimensions.elevationSmall,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // === ELEVATED BUTTON THEME ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.textOnPrimary,
          elevation: AppDimensions.elevationSmall,
          shadowColor: AppColors.shadowColored,
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLarge,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          minimumSize: const Size.fromHeight(56),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // === OUTLINED BUTTON THEME ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRedLight,
          side: const BorderSide(
            color: AppColors.primaryRedLight,
            width: AppDimensions.borderWidthMedium,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLarge,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          minimumSize: const Size.fromHeight(56),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryRedLight,
          ),
        ),
      ),

      // === TEXT BUTTON THEME ===
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryRedLight,
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLarge,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          minimumSize: const Size.fromHeight(56),
          textStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryRedLight,
          ),
        ),
      ),

      // === FLOATING ACTION BUTTON THEME ===
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppDimensions.elevationMedium,
        shape: CircleBorder(),
      ),

      // === CARD THEME ===
      cardTheme: const CardThemeData(
        color: AppColors.backgroundSecondaryDark,
        shadowColor: AppColors.shadowDark,
        elevation: AppDimensions.elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
        ),
        margin: AppDimensions.paddingAll8,
      ),

      // === CHIP THEME ===
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSecondaryDark,
        selectedColor: AppColors.primaryRed,
        disabledColor: AppColors.grey800,
        deleteIconColor: AppColors.textSecondaryDark,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
        padding: AppDimensions.chipPadding,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.chipBorderRadius,
        ),
        side: const BorderSide(color: AppColors.borderLightDark),
        secondarySelectedColor: AppColors.primaryRed,
        checkmarkColor: AppColors.textOnPrimary,
      ),

      // === INPUT DECORATION THEME ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondaryDark,
        border: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(
            color: AppColors.primaryRedLight,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(color: AppColors.errorLight),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          borderSide: BorderSide(
            color: AppColors.errorLight,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        contentPadding: AppDimensions.inputFieldPadding,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiaryDark,
        ),
      ),

      // === ICON THEME ===
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: AppDimensions.iconMedium,
      ),

      // === BOTTOM NAVIGATION BAR THEME ===
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundPrimaryDark,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationLarge,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // === CHECKBOX THEME ===
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryRed;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(
          color: AppColors.borderMediumDark,
          width: AppDimensions.borderWidthThick,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXSmall,
        ),
      ),

      // === RADIO THEME ===
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryRed;
          }
          return AppColors.borderMediumDark;
        }),
      ),

      // === EXTENSIONS ===
      extensions: const <ThemeExtension<dynamic>>[
        CustomColors(
          success: AppColors.success,
          warning: AppColors.warning,
          info: AppColors.atlasBlue,
        ),
      ],
    );
  }

  /// الثيم الفاتح
  static ThemeData get light => lightTheme;

  /// الثيم الداكن
  static ThemeData get dark => darkTheme;
}
