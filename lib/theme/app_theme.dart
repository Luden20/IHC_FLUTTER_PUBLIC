import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

enum AppThemeMode { dark, light }

class AppTheme {
  static ThemeData resolve(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return LightAppTheme.data;
      case AppThemeMode.dark:
      default:
        return DarkAppTheme.data;
    }
  }
}

class AppThemeController extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored == null) return;
    final parsed = AppThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => AppThemeMode.dark,
    );
    _mode = parsed;
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  Future<void> toggle() {
    final nextMode = _mode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    return setMode(nextMode);
  }
}
