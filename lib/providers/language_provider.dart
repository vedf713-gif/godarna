import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('ar', 'MA'); // Default to Arabic
  bool _isLoading = false;

  // Getters
  Locale get currentLocale => _currentLocale;
  bool get isLoading => _isLoading;
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isFrench => _currentLocale.languageCode == 'fr';

  // Initialize language from preferences
  Future<void> initialize() async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        _currentLocale = Locale(languageCode, 'MA');
      } else {
        // Default to Arabic
        _currentLocale = const Locale('ar', 'MA');
        await _saveLanguage('ar');
      }
    } catch (e) {
      // Fallback to Arabic on error
      _currentLocale = const Locale('ar', 'MA');
    } finally {
      _setLoading(false);
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    try {
      _setLoading(true);
      
      if (languageCode == 'ar' || languageCode == 'fr') {
        _currentLocale = Locale(languageCode, 'MA');
        await _saveLanguage(languageCode);
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    } finally {
      _setLoading(false);
    }
  }

  // Toggle between Arabic and French
  Future<void> toggleLanguage() async {
    final newLanguage = isArabic ? 'fr' : 'ar';
    await changeLanguage(newLanguage);
  }

  // Get language name in current language
  String getLanguageName(String languageCode) {
    if (languageCode == 'ar') {
      return isArabic ? 'العربية' : 'Arabe';
    } else if (languageCode == 'fr') {
      return isArabic ? 'الفرنسية' : 'Français';
    }
    return languageCode;
  }

  // Get current language name
  String get currentLanguageName {
    return getLanguageName(_currentLocale.languageCode);
  }

  // Get available languages
  List<Map<String, String>> get availableLanguages {
    return [
      {
        'code': 'ar',
        'name': getLanguageName('ar'),
        'flag': '🇲🇦',
      },
      {
        'code': 'fr',
        'name': getLanguageName('fr'),
        'flag': '🇫🇷',
      },
    ];
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      // Handle error silently
    }
  }

  // Get text direction
  TextDirection get textDirection {
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  // Get alignment
  Alignment get textAlignment {
    return isArabic ? Alignment.centerRight : Alignment.centerLeft;
  }

  // Get cross alignment
  CrossAxisAlignment get crossAxisAlignment {
    return isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }

  // Get main alignment
  MainAxisAlignment get mainAxisAlignment {
    return isArabic ? MainAxisAlignment.end : MainAxisAlignment.start;
  }
}