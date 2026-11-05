import 'package:flutter/material.dart';
import '../utils/secure_storage_helper.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _storageKey = 'segurcel_app_theme';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  Future<void> initTheme() async {
    try {
      final savedTheme = await SecureStorageHelper.safeRead(_storageKey);
      if (savedTheme != null) {
        if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else if (savedTheme == 'system') {
          _themeMode = ThemeMode.system;
        } else {
          _themeMode = ThemeMode.dark;
        }
      }
    } catch (_) {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    String val = 'dark';
    if (mode == ThemeMode.light) {
      val = 'light';
    } else if (mode == ThemeMode.system) {
      val = 'system';
    }
    await SecureStorageHelper.safeWrite(_storageKey, val);
  }
}
