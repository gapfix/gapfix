import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

const _kLanguageKey = 'app_language';

/// Port of Android LocaleHelper: the app language ("en", "ru" or "hy"),
/// persisted across launches. Null means "follow the device".
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  /// Call once before runApp to restore the saved language.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLanguageKey);
    if (code != null && AppStrings.supportedLanguageCodes.contains(code)) {
      state = Locale(code);
    }
  }

  Future<void> setLanguage(String code) async {
    if (!AppStrings.supportedLanguageCodes.contains(code)) return;
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, code);
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
