import 'package:flutter/material.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/widgets/common/app_button.dart';

class PermissionRationaleTexts {
  static String locationTitle(BuildContext context) =>
      AppStrings.getString('locationPermissionTitle', context);
  static String locationBody(BuildContext context) =>
      AppStrings.getString('locationPermissionBody', context);

  static String notificationsTitle(BuildContext context) =>
      AppStrings.getString('notificationsPermissionTitle', context);
  static String notificationsBody(BuildContext context) =>
      AppStrings.getString('notificationsPermissionBody', context);

  static String photosTitle(BuildContext context) =>
      AppStrings.getString('photosPermissionTitle', context);
  static String photosBody(BuildContext context) =>
      AppStrings.getString('photosPermissionBody', context);
      
  static String cameraTitle(BuildContext context) =>
      AppStrings.getString('cameraPermissionTitle', context);
      
  static String cameraBody(BuildContext context) =>
      AppStrings.getString('cameraPermissionBody', context);

  static String permanentlyDeniedTitle(BuildContext context) =>
      AppStrings.getString('permissionDeniedTitle', context);
  static String permanentlyDeniedBody(BuildContext context) =>
      AppStrings.getString('permissionDeniedBody', context);
}

Future<bool> showPermissionRationale(
  BuildContext context, {
  required String title,
  required String message,
  String? proceedText,
  String? cancelText,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            cancelText ?? AppStrings.getString('later', context),
          ),
        ),
        AppButton(
          text: proceedText ?? AppStrings.getString('continue', context),
          onPressed: () => Navigator.of(ctx).pop(true),
          type: AppButtonType.primary,
        ),
      ],
    ),
  );
  return result ?? false;
}
