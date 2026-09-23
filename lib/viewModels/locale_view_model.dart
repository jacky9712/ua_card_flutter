import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 啟動時在 main() 先讀出上次選的語言再 override 進來，
// 避免 App 先用系統語言畫一次、讀完偏好後又整頁跳成另一種語言。
final savedLocaleProvider = Provider<Locale?>((ref) => null);

final localeViewModelProvider = NotifierProvider<LocaleViewModel, Locale?>(LocaleViewModel.new);

/// null = 跟隨系統語言
class LocaleViewModel extends Notifier<Locale?> {
  static const String _prefsKey = 'app_locale';

  @override
  Locale? build() => ref.read(savedLocaleProvider);

  static Future<Locale?> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      return code == null ? null : Locale(code);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
