import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  PermissionsHelper._();

  // Request location permission (when-in-use)
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) return true;

    // If permanently denied, guide user to settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  // Request storage/media permission (for picking images)
  // Enhanced for Android 13+ compatibility and Web support
  static Future<bool> requestMediaPermission() async {
    // Web doesn't need permissions for file picker
    if (kIsWeb) {
      return true;
    }

    if (Platform.isIOS) {
      // On iOS, photo library access
      final photos = await Permission.photos.request();
      if (photos.isGranted) return true;
      if (photos.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }

    // Android: Handle different API levels intelligently
    if (Platform.isAndroid) {
      try {
        // Try modern permissions first (Android 13+)
        final photos = await Permission.photos.request();
        if (photos.isGranted) return true;
        
        // Try storage permission for older versions
        final storage = await Permission.storage.request();
        if (storage.isGranted) return true;
        
        // Try media permissions as fallback
        final manageStorage = await Permission.manageExternalStorage.request();
        if (manageStorage.isGranted) return true;
        
        // Check if any permission is permanently denied
        final photoStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;
        
        if (photoStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
        
        return false;
      } catch (e) {
        // Fallback to basic storage permission if modern permissions fail
        try {
          final storage = await Permission.storage.request();
          if (storage.isGranted) return true;
          
          if (storage.isPermanentlyDenied) {
            await openAppSettings();
          }
          return false;
        } catch (_) {
          return false;
        }
      }
    }
    
    return false;
  }

  // Enhanced media permission check with detailed status
  static Future<Map<String, dynamic>> checkMediaPermissionStatus() async {
    if (Platform.isIOS) {
      final photos = await Permission.photos.status;
      return {
        'granted': photos.isGranted,
        'denied': photos.isDenied,
        'permanentlyDenied': photos.isPermanentlyDenied,
        'restricted': photos.isRestricted,
        'platform': 'iOS',
        'permissions': {'photos': photos.toString()}
      };
    }

    if (Platform.isAndroid) {
      final photos = await Permission.photos.status;
      final storage = await Permission.storage.status;
      
      return {
        'granted': photos.isGranted || storage.isGranted,
        'denied': photos.isDenied && storage.isDenied,
        'permanentlyDenied': photos.isPermanentlyDenied || storage.isPermanentlyDenied,
        'platform': 'Android',
        'permissions': {
          'photos': photos.toString(),
          'storage': storage.toString()
        }
      };
    }

    return {
      'granted': false,
      'denied': true,
      'permanentlyDenied': false,
      'platform': 'Unknown'
    };
  }

  // Request notification permission (Android 13+ and iOS)
  static Future<bool> requestNotificationPermission(
    FlutterLocalNotificationsPlugin fln,
  ) async {
    bool granted = true;

    // Android 13+ requires runtime notifications permission
    if (Platform.isAndroid) {
      final notif = await Permission.notification.request();
      granted = notif.isGranted;
    }

    // iOS: request authorization flags
    if (Platform.isIOS) {
      final ios = fln.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = (result ?? false);
    }

    if (!granted) {
      final p = await Permission.notification.status;
      if (p.isPermanentlyDenied) {
        await openAppSettings();
      }
    }

    return granted;
  }

  // Enhanced permission request with better error handling and Web support
  static Future<bool> requestMediaPermissionWithFallback() async {
    // Web doesn't need permissions for file picker
    if (kIsWeb) {
      return true;
    }

    try {
      // First attempt with enhanced method
      final result = await requestMediaPermission();
      if (result) return true;
      
      // Second attempt with basic permissions
      if (Platform.isAndroid) {
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
      
      return false;
    } catch (e) {
      // Final fallback - try basic storage only
      if (Platform.isAndroid) {
        try {
          final storage = await Permission.storage.request();
          return storage.isGranted;
        } catch (_) {
          return false;
        }
      }
      return false;
    }
  }

  // Convenience: request a set of commonly used permissions
  static Future<Map<String, bool>> requestCommonPermissions({
    required FlutterLocalNotificationsPlugin fln,
    bool location = false,
    bool camera = false,
    bool media = false,
    bool notifications = false,
  }) async {
    final results = <String, bool>{};

    if (location) {
      results['location'] = await requestLocationPermission();
    }
    if (camera) {
      results['camera'] = await requestCameraPermission();
    }
    if (media) {
      results['media'] = await requestMediaPermissionWithFallback();
    }
    if (notifications) {
      results['notifications'] = await requestNotificationPermission(fln);
    }

    return results;
  }

  // Diagnostic function to help troubleshoot permission issues
  static Future<String> diagnoseMediaPermissionIssues() async {
    final buffer = StringBuffer();
    buffer.writeln('🔍 تشخيص صلاحيات الوصول للصور:');
    buffer.writeln('');

    try {
      final status = await checkMediaPermissionStatus();
      buffer.writeln('📱 النظام: ${status['platform']}');
      buffer.writeln('✅ مسموح: ${status['granted'] ? 'نعم' : 'لا'}');
      buffer.writeln('❌ مرفوض: ${status['denied'] ? 'نعم' : 'لا'}');
      buffer.writeln('🔒 مرفوض نهائياً: ${status['permanentlyDenied'] ? 'نعم' : 'لا'}');
      
      if (status['permissions'] != null) {
        buffer.writeln('');
        buffer.writeln('📋 تفاصيل الصلاحيات:');
        final permissions = status['permissions'] as Map<String, dynamic>;
        permissions.forEach((key, value) {
          buffer.writeln('  • $key: $value');
        });
      }

      buffer.writeln('');
      if (status['granted'] == true) {
        buffer.writeln('✅ الصلاحيات مفعلة بشكل صحيح');
      } else if (status['permanentlyDenied'] == true) {
        buffer.writeln('⚠️ تم رفض الصلاحيات نهائياً');
        buffer.writeln('💡 الحل: اذهب إلى الإعدادات > التطبيقات > GoDarna > الصلاحيات');
      } else {
        buffer.writeln('⚠️ الصلاحيات غير مفعلة');
        buffer.writeln('💡 الحل: اضغط على "أضف صورة" واسمح بالوصول للصور');
      }

    } catch (e) {
      buffer.writeln('❌ خطأ في التشخيص: $e');
    }

    return buffer.toString();
  }

  // Quick permission fix attempt
  static Future<bool> attemptPermissionFix() async {
    try {
      // Try multiple permission request strategies
      final strategies = [
        () => requestMediaPermissionWithFallback(),
        () => requestMediaPermission(),
        () async {
          if (Platform.isAndroid) {
            return (await Permission.storage.request()).isGranted;
          }
          return false;
        },
      ];

      for (final strategy in strategies) {
        try {
          final result = await strategy();
          if (result) return true;
        } catch (_) {
          continue;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
