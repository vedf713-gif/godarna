// 🔧 إعدادات التطبيق الأساسية
class AppConfig {
  // إعدادات التطبيق العامة
  static const String appName = 'GoDarna';
  static const String appVersion = '1.0.0';
  
  // إعدادات الشبكة
  static const int connectionTimeout = 30000; // 30 ثانية
  static const int receiveTimeout = 30000;
  
  // إعدادات الصفحات
  static const int itemsPerPage = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  
  // إعدادات الخريطة
  static const double defaultLatitude = 31.7917; // الرباط
  static const double defaultLongitude = -7.0926;
  static const double defaultZoom = 10.0;
  
  // إعدادات الدفع
  static const List<String> supportedCurrencies = ['MAD', 'USD', 'EUR'];
  static const String defaultCurrency = 'MAD';
  
  // إعدادات الملفات
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxImagesPerProperty = 10;
  
  // إعدادات الإشعارات
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableSMSNotifications = false;
  
  // إعدادات التخزين المؤقت
  static const int cacheExpirationHours = 24;
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
}
