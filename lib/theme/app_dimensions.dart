import 'package:flutter/material.dart';

/// نظام موحد للمسافات والأبعاد في التطبيق
/// جميع القيم مأخوذة من هذا الملف فقط - لا توجد قيم مكتوبة مباشرة
class AppDimensions {
  AppDimensions._();

  // === SPACING SYSTEM ===
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;
  static const double space72 = 72.0;
  static const double space80 = 80.0;
  static const double space96 = 96.0;

  // === BORDER RADIUS ===
  static const double radiusXSmall = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusCircular = 50.0;

  // === BORDER RADIUS OBJECTS ===
  static const BorderRadius borderRadiusXSmall =
      BorderRadius.all(Radius.circular(radiusXSmall));
  static const BorderRadius borderRadiusSmall =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge =
      BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge =
      BorderRadius.all(Radius.circular(radiusXLarge));
  static const BorderRadius borderRadiusXXLarge =
      BorderRadius.all(Radius.circular(radiusXXLarge));
  static const BorderRadius borderRadiusCircular =
      BorderRadius.all(Radius.circular(radiusCircular));

  // === ELEVATION ===
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 12.0;
  static const double elevationXXLarge = 16.0;

  // === ICON SIZES ===
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  static const double iconXXLarge = 48.0;
  static const double iconHuge = 64.0;

  // === BUTTON DIMENSIONS ===
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightXLarge = 64.0;

  // === CARD DIMENSIONS ===
  static const double cardPadding = space16;
  static const double cardMargin = space8;
  static const BorderRadius cardBorderRadius = borderRadiusLarge;

  // === APP BAR DIMENSIONS ===
  static const double appBarHeight = 96.0;
  static const double appBarElevation = elevationNone;
  static const double appBarScrolledElevation = elevationSmall;

  // === BOTTOM NAV DIMENSIONS ===
  static const double bottomNavHeight = 60.0;
  static const double bottomNavElevation = elevationLarge;

  // === INPUT FIELD DIMENSIONS ===
  static const double inputFieldHeight = buttonHeightLarge;
  static const EdgeInsets inputFieldPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space16,
  );
  static const BorderRadius inputFieldBorderRadius = borderRadiusLarge;

  // === CONTAINER PADDING ===
  static const EdgeInsets paddingAll8 = EdgeInsets.all(space8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(space12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(space16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(space20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(space24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(space32);

  static const EdgeInsets paddingHorizontal8 =
      EdgeInsets.symmetric(horizontal: space8);
  static const EdgeInsets paddingHorizontal12 =
      EdgeInsets.symmetric(horizontal: space12);
  static const EdgeInsets paddingHorizontal16 =
      EdgeInsets.symmetric(horizontal: space16);
  static const EdgeInsets paddingHorizontal20 =
      EdgeInsets.symmetric(horizontal: space20);
  static const EdgeInsets paddingHorizontal24 =
      EdgeInsets.symmetric(horizontal: space24);
  static const EdgeInsets paddingHorizontal32 =
      EdgeInsets.symmetric(horizontal: space32);

  // === PADDING ALIASES ===
  static const EdgeInsets paddingSmall = paddingAll8;
  static const EdgeInsets paddingMedium = paddingAll12;
  static const EdgeInsets paddingLarge = paddingAll16;
  static const EdgeInsets paddingXLarge = paddingAll20;

  // === HORIZONTAL PADDING ALIASES ===
  static const EdgeInsets paddingHorizontalSmall = paddingHorizontal8;
  static const EdgeInsets paddingHorizontalMedium = paddingHorizontal12;
  static const EdgeInsets paddingHorizontalLarge = paddingHorizontal16;
  static const EdgeInsets paddingHorizontalXLarge = paddingHorizontal20;

  // === SPACING ALIASES ===
  static const double spacingSmall = space8;
  static const double spacingMedium = space12;
  static const double spacingLarge = space16;
  static const double spacingXLarge = space20;

  static const EdgeInsets paddingVertical8 =
      EdgeInsets.symmetric(vertical: space8);
  static const EdgeInsets paddingVertical12 =
      EdgeInsets.symmetric(vertical: space12);
  static const EdgeInsets paddingVertical16 =
      EdgeInsets.symmetric(vertical: space16);
  static const EdgeInsets paddingVertical20 =
      EdgeInsets.symmetric(vertical: space20);
  static const EdgeInsets paddingVertical24 =
      EdgeInsets.symmetric(vertical: space24);

  // === SCREEN PADDING ===
  static const EdgeInsets screenPadding = EdgeInsets.all(space20);
  static const EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: space20);
  static const EdgeInsets screenPaddingVertical =
      EdgeInsets.symmetric(vertical: space20);

  // === LIST ITEM DIMENSIONS ===
  static const double listItemHeight = 72.0;
  static const double listItemMinHeight = 56.0;
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space12,
  );

  // === DIVIDER DIMENSIONS ===
  static const double dividerThickness = 1.0;
  static const double dividerIndent = space16;

  // === PROPERTY CARD DIMENSIONS ===
  static const double propertyCardImageHeight = 200.0;
  static const double propertyCardMinHeight = 280.0;
  static const EdgeInsets propertyCardPadding = paddingAll16;
  static const BorderRadius propertyCardBorderRadius = borderRadiusLarge;

  // === AVATAR SIZES ===
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarXLarge = 96.0;

  // === CHIP DIMENSIONS ===
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: space12,
    vertical: space8,
  );
  static const BorderRadius chipBorderRadius =
      BorderRadius.all(Radius.circular(radiusXLarge));

  // === DIALOG DIMENSIONS ===
  static const EdgeInsets dialogPadding = paddingAll24;
  static const BorderRadius dialogBorderRadius = borderRadiusXLarge;
  static const double dialogElevation = elevationXLarge;

  // === BOTTOM SHEET DIMENSIONS ===
  static const BorderRadius bottomSheetBorderRadius = BorderRadius.vertical(
    top: Radius.circular(radiusXXLarge),
  );
  static const EdgeInsets bottomSheetPadding = paddingAll20;
  static const double bottomSheetElevation = elevationLarge;

  // === SNACKBAR DIMENSIONS ===
  static const EdgeInsets snackbarPadding = paddingAll16;
  static const BorderRadius snackbarBorderRadius = borderRadiusMedium;
  static const double snackbarElevation = elevationMedium;

  // === FLOATING ACTION BUTTON ===
  static const double fabSize = 56.0;
  static const double fabMiniSize = 40.0;
  static const BorderRadius fabBorderRadius = borderRadiusLarge;
  static const double fabElevation = elevationMedium;

  // === ADDITIONAL PADDING VALUES ===
  static const EdgeInsets paddingBottom12 = EdgeInsets.only(bottom: space12);
  static const EdgeInsets paddingBottom16 = EdgeInsets.only(bottom: space16);
  static const EdgeInsets paddingSymmetric12x6 =
      EdgeInsets.symmetric(horizontal: space12, vertical: space6);
  static const EdgeInsets paddingSymmetric4x0 =
      EdgeInsets.symmetric(horizontal: space4, vertical: 0);
  static const EdgeInsets paddingSymmetric16x8 =
      EdgeInsets.symmetric(horizontal: space16, vertical: space8);
  static const EdgeInsets paddingSymmetric16x12 =
      EdgeInsets.symmetric(horizontal: space16, vertical: space12);
  static const EdgeInsets paddingSymmetric8x6 =
      EdgeInsets.symmetric(horizontal: space8, vertical: space6);
  static const EdgeInsets paddingSymmetric8x0 =
      EdgeInsets.symmetric(horizontal: space8, vertical: 0);
  static const EdgeInsets paddingSymmetric6x2 =
      EdgeInsets.symmetric(horizontal: space6, vertical: space2);
  static const EdgeInsets paddingRight20 = EdgeInsets.only(right: space20);
  static const EdgeInsets paddingAll4 = EdgeInsets.all(space4);
  static const EdgeInsets paddingHorizontal4 =
      EdgeInsets.symmetric(horizontal: space4);
  static const EdgeInsets paddingVertical14 =
      EdgeInsets.symmetric(vertical: 14.0);
  static const EdgeInsets paddingVertical6 =
      EdgeInsets.symmetric(vertical: space6);
  static const EdgeInsets paddingSymmetric16x10 =
      EdgeInsets.symmetric(horizontal: space16, vertical: 10.0);
  static const EdgeInsets paddingSymmetric12x16 =
      EdgeInsets.symmetric(horizontal: space12, vertical: space16);
  static const EdgeInsets paddingSymmetric12x10 =
      EdgeInsets.symmetric(horizontal: space12, vertical: 10.0);
  static const EdgeInsets paddingSymmetric16x16 =
      EdgeInsets.symmetric(horizontal: space16, vertical: space16);
  static const EdgeInsets paddingFromLTRB12x10x12x12 =
      EdgeInsets.fromLTRB(space12, 10.0, space12, space12);
  static const EdgeInsets marginBottom12 = EdgeInsets.only(bottom: space12);
  static const EdgeInsets paddingSymmetric20x24 =
      EdgeInsets.symmetric(horizontal: space20, vertical: space24);

  // Additional space values
  static const double space14 = 14.0;
  static const double space1 = 1.0;

  // Additional padding values
  static const EdgeInsets paddingAll10 = EdgeInsets.all(10.0);
  static const EdgeInsets paddingAll2 = EdgeInsets.all(space2);
  static const EdgeInsets paddingSymmetric10x8 =
      EdgeInsets.symmetric(horizontal: 10.0, vertical: space8);
  static const EdgeInsets paddingVertical10 =
      EdgeInsets.symmetric(vertical: 10.0);
  static const EdgeInsets paddingSymmetric8x4 =
      EdgeInsets.symmetric(horizontal: space8, vertical: space4);
  static const EdgeInsets paddingSymmetric16x14 =
      EdgeInsets.symmetric(horizontal: space16, vertical: 14.0);
  static const EdgeInsets paddingSymmetric12x8 =
      EdgeInsets.symmetric(horizontal: space12, vertical: space8);
  static const EdgeInsets paddingBottom10 = EdgeInsets.only(bottom: 10.0);
  static const EdgeInsets paddingAll40 = EdgeInsets.all(space40);
  static const EdgeInsets paddingSymmetric20x8 =
      EdgeInsets.symmetric(horizontal: space20, vertical: space8);

  // Additional space values
  static const double space28 = 28.0;
  static const double space10 = 10.0;

  // === ADDITIONAL BORDER RADIUS VALUES ===
  static const BorderRadius borderRadiusBottomLarge =
      BorderRadius.vertical(bottom: Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusTopXLarge =
      BorderRadius.vertical(top: Radius.circular(radiusXLarge));

  // === BORDER WIDTH ===
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;

  // === ANIMATION DURATIONS ===
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationXSlow = Duration(milliseconds: 800);
}
