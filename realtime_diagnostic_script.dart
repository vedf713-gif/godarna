// 🔍 سكريبت تشخيص نظام Realtime في GoDarna
// يفحص جميع الشاشات والاشتراكات

import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  debugPrint('🔄 بدء فحص نظام Realtime في تطبيق GoDarna...\n');
  
  // قائمة الشاشات التي يجب أن تحتوي على RealtimeMixin
  final requiredScreens = [
    'lib/screens/main/home_screen.dart',
    'lib/screens/main/explore_screen.dart', 
    'lib/screens/main/search_screen.dart',
    'lib/screens/main/favorites_screen.dart',
    'lib/screens/main/bookings_screen.dart',
    'lib/screens/main/notifications_screen.dart',
    'lib/screens/main/profile_screen.dart',
    'lib/screens/property/property_details_screen.dart',
    'lib/screens/booking/booking_details_screen.dart',
    'lib/screens/booking/my_bookings_screen.dart',
    'lib/screens/booking/host_bookings_screen.dart',
    'lib/screens/payment/payment_screen.dart',
    'lib/screens/payment/payment_history_screen.dart',
  ];

  debugPrint('📋 فحص تطبيق RealtimeMixin في الشاشات:\n');
  
  int implementedScreens = 0;
  int totalScreens = requiredScreens.length;
  
  for (String screenPath in requiredScreens) {
    bool hasRealtimeMixin = checkRealtimeMixin(screenPath);
    bool hasSubscriptions = checkSubscriptions(screenPath);
    bool hasDispose = checkDispose(screenPath);
    
    String status = '';
    if (hasRealtimeMixin && hasSubscriptions && hasDispose) {
      status = '✅ مُطبق بالكامل';
      implementedScreens++;
    } else if (hasRealtimeMixin) {
      status = '⚠️  مُطبق جزئياً';
    } else {
      status = '❌ غير مُطبق';
    }
    
    String screenName = screenPath.split('/').last.replaceAll('.dart', '');
    debugPrint('  $screenName: $status');
    
    if (!hasRealtimeMixin) {
      debugPrint('    - مفقود: RealtimeMixin');
    }
    if (!hasSubscriptions) {
      debugPrint('    - مفقود: _setupRealtimeSubscriptions()');
    }
    if (!hasDispose) {
      debugPrint('    - مفقود: unsubscribeAll() في dispose');
    }
  }
  
  debugPrint('\n📊 ملخص النتائج:');
  debugPrint('  الشاشات المُطبقة: $implementedScreens/$totalScreens');
  debugPrint('  نسبة الإكمال: ${(implementedScreens/totalScreens*100).toStringAsFixed(1)}%');
  
  if (implementedScreens == totalScreens) {
    debugPrint('\n🎉 ممتاز! جميع الشاشات تحتوي على RealtimeMixin');
  } else {
    debugPrint('\n⚠️  يحتاج ${totalScreens - implementedScreens} شاشات لتطبيق RealtimeMixin');
  }
  
  debugPrint('\n🔧 فحص ملفات الإعداد:');
  checkConfigFiles();
  
  debugPrint('\n📱 اختبارات يدوية مطلوبة:');
  printManualTests();
}

bool checkRealtimeMixin(String filePath) {
  try {
    File file = File(filePath);
    if (!file.existsSync()) return false;
    
    String content = file.readAsStringSync();
    return content.contains('with RealtimeMixin') || 
           content.contains('extends') && content.contains('RealtimeMixin');
  } catch (e) {
    return false;
  }
}

bool checkSubscriptions(String filePath) {
  try {
    File file = File(filePath);
    if (!file.existsSync()) return false;
    
    String content = file.readAsStringSync();
    return content.contains('_setupRealtimeSubscriptions') ||
           content.contains('subscribeToTable');
  } catch (e) {
    return false;
  }
}

bool checkDispose(String filePath) {
  try {
    File file = File(filePath);
    if (!file.existsSync()) return false;
    
    String content = file.readAsStringSync();
    return content.contains('unsubscribeAll()') ||
           content.contains('super.dispose()');
  } catch (e) {
    return false;
  }
}

void checkConfigFiles() {
  // فحص RealtimeMixin
  File realtimeMixin = File('lib/mixins/realtime_mixin.dart');
  if (realtimeMixin.existsSync()) {
    debugPrint('  ✅ RealtimeMixin موجود');
  } else {
    debugPrint('  ❌ RealtimeMixin مفقود');
  }
  
  // فحص RealtimeService
  File realtimeService = File('lib/services/realtime_service.dart');
  if (realtimeService.existsSync()) {
    debugPrint('  ✅ RealtimeService موجود');
  } else {
    debugPrint('  ❌ RealtimeService مفقود');
  }
  
  // فحص Supabase config
  File supabaseConfig = File('lib/config/supabase_config.dart');
  if (supabaseConfig.existsSync()) {
    debugPrint('  ✅ Supabase Config موجود');
  } else {
    debugPrint('  ❌ Supabase Config مفقود');
  }
}

void printManualTests() {
  debugPrint('''
  1. 🔔 اختبار الإشعارات:
     - افتح التطبيق على جهازين
     - أرسل رسالة من جهاز
     - تحقق من وصول الإشعار للجهاز الآخر خلال 1-2 ثانية
  
  2. 📋 اختبار الحجوزات:
     - غيّر حالة حجز من Supabase Dashboard
     - تحقق من تحديث الحالة فوراً في التطبيق
  
  3. ❤️ اختبار المفضلة:
     - أضف عقار للمفضلة من جهاز
     - تحقق من ظهوره في المفضلة على جهاز آخر (نفس الحساب)
  
  4. 💬 اختبار الرسائل:
     - افتح محادثة حجز على جهازين
     - أرسل رسالة من جهاز
     - تحقق من وصولها فوراً للجهاز الآخر
  
  5. 🌐 فحص Network:
     - افتح Developer Tools > Network
     - ابحث عن WebSocket connections إلى Supabase
     - تأكد من وجود اتصالات realtime نشطة
  ''');
}
