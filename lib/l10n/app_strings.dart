import 'package:flutter/material.dart';
import 'app_strings_data.dart';

/// Lookup over the string tables ported from Android strings.xml
/// (values, values-ru, values-hy). Falls back to English, then to the key.
class AppStrings {
  static const supportedLanguageCodes = ['en', 'ru', 'hy'];

  static String lookup(String languageCode, String key,
      [List<Object?> args = const []]) {
    final table = kAppStrings[languageCode] ?? kAppStrings['en']!;
    var text = table[key] ?? kAppStrings['en']![key] ?? key;
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{${i + 1}}', '${args[i]}');
    }
    return text;
  }

  static String languageName(String code) {
    switch (code) {
      case 'hy':
        return 'Հայերեն';
      case 'ru':
        return 'Русский';
      default:
        return 'English';
    }
  }
}

extension AppStringsContext on BuildContext {
  /// Translate an Android string key, e.g. context.tr('profile_updated').
  /// Positional args replace {1}, {2}, ... (Android %1$s, %2$s, ...).
  String tr(String key, [List<Object?> args = const []]) {
    final code = Localizations.localeOf(this).languageCode;
    return AppStrings.lookup(code, key, args);
  }
}
