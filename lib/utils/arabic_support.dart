import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// مساعدات دعم اللغة العربية والثقافة المحلية المغربية
class ArabicSupport {
  
  /// تحويل الأرقام الإنجليزية إلى عربية
  static String convertToArabicNumbers(String input) {
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    String result = input;
    for (int i = 0; i < englishNumbers.length; i++) {
      result = result.replaceAll(englishNumbers[i], arabicNumbers[i]);
    }
    return result;
  }
  
  /// تنسيق العملة المغربية
  static String formatMoroccanCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ar_MA',
      symbol: 'د.م.',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
  
  /// تنسيق التاريخ بالعربية
  static String formatArabicDate(DateTime date) {
    final formatter = DateFormat('EEEE، d MMMM yyyy', 'ar');
    return formatter.format(date);
  }
  
  /// تنسيق الوقت بالعربية
  static String formatArabicTime(DateTime time) {
    final formatter = DateFormat('h:mm a', 'ar');
    return formatter.format(time);
  }
  
  /// تحديد اتجاه النص (RTL للعربية)
  static TextDirection getTextDirection(String text) {
    if (text.isEmpty) {
      return TextDirection.ltr;
    }
    
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) {
      return TextDirection.rtl;
    } else {
      return TextDirection.ltr;
    }
  }
  
  /// تنسيق أرقام المسافة
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} متر';
    } else {
      return '${distanceKm.toStringAsFixed(1)} كم';
    }
  }
  
  /// تنسيق عدد الضيوف
  static String formatGuestCount(int count) {
    if (count == 1) return 'ضيف واحد';
    if (count == 2) return 'ضيفان';
    if (count <= 10) return '$count ضيوف';
    return '$count ضيف';
  }
  
  /// تنسيق عدد الغرف
  static String formatRoomCount(int count) {
    if (count == 1) return 'غرفة واحدة';
    if (count == 2) return 'غرفتان';
    if (count <= 10) return '$count غرف';
    return '$count غرفة';
  }
  
  /// تنسيق التقييم
  static String formatRating(double rating) {
    return '${rating.toStringAsFixed(1)} ⭐';
  }
  
  /// تحويل نوع العقار إلى العربية
  static String translatePropertyType(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return 'شقة';
      case 'villa':
        return 'فيلا';
      case 'riad':
        return 'رياض';
      case 'studio':
        return 'استوديو';
      case 'house':
        return 'منزل';
      case 'room':
        return 'غرفة';
      default:
        return type;
    }
  }
  
  /// تحويل حالة الحجز إلى العربية
  static String translateBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'في الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغي';
      case 'completed':
        return 'مكتمل';
      case 'active':
        return 'نشط';
      default:
        return status;
    }
  }
  
  /// تحويل أيام الأسبوع إلى العربية
  static String translateWeekday(int weekday) {
    const weekdays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    return weekdays[weekday - 1];
  }
  
  /// تحويل الشهور إلى العربية
  static String translateMonth(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل',
      'مايو', 'يونيو', 'يوليو', 'أغسطس',
      'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }
  
  /// تنسيق المدة (عدد الأيام/الليالي)
  static String formatDuration(int nights) {
    if (nights == 1) return 'ليلة واحدة';
    if (nights == 2) return 'ليلتان';
    if (nights <= 10) return '$nights ليالي';
    return '$nights ليلة';
  }
  
  /// تحقق من صحة النص العربي
  static bool isArabicText(String text) {
    final arabicRegex = RegExp(r'^[\u0600-\u06FF\s\d\.,!?؟]+$');
    return arabicRegex.hasMatch(text);
  }
  
  /// تنظيف النص العربي
  static String cleanArabicText(String text) {
    // إزالة الأحرف غير المرغوب فيها
    return text
        .replaceAll(RegExp(r'[^\u0600-\u06FF\s\d\.,!?؟]'), '')
        .trim();
  }
  
  /// تحويل النص إلى تنسيق مناسب للبحث
  static String normalizeForSearch(String text) {
    return text
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }
}

/// مكون لدعم النص العربي مع التنسيق التلقائي
class ArabicText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool convertNumbers;
  
  const ArabicText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.convertNumbers = false,
  });
  
  @override
  Widget build(BuildContext context) {
    String displayText = text;
    if (convertNumbers) {
      displayText = ArabicSupport.convertToArabicNumbers(text);
    }
    
    return Text(
      displayText,
      style: style,
      textAlign: textAlign ?? TextAlign.right,
      textDirection: ArabicSupport.getTextDirection(displayText),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// مكون للنص المختلط (عربي وإنجليزي)
class MixedText extends StatelessWidget {
  final String text;
  final TextStyle? arabicStyle;
  final TextStyle? englishStyle;
  final TextAlign? textAlign;
  
  const MixedText(
    this.text, {
    super.key,
    this.arabicStyle,
    this.englishStyle,
    this.textAlign,
  });
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ArabicSupport.getTextDirection(text) == TextDirection.rtl
          ? arabicStyle
          : englishStyle,
      textAlign: textAlign,
      textDirection: ArabicSupport.getTextDirection(text),
    );
  }
}
