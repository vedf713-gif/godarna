import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    final String langCode = locale.languageCode;
    final String path = 'assets/translations/$langCode.json';

    try {
      final String jsonString = await rootBundle.loadString(path);
      _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
      return true;
    } catch (_) {
      _localizedStrings = <String, dynamic>{};
      return false;
    }
  }

  String tr(String key, {String? fallback}) {
    final value = _localizedStrings[key];
    if (value is String) return value;
    return fallback ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
