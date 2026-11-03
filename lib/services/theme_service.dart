import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _storageKey = 'segurcel_app_theme';
  final _secureStorage = const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  Future<void> initTheme() async {
    try {
      final savedTheme = await _secureStorage.read(key: _storageKey);
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
    await _secureStorage.write(key: _storageKey, value: val);
  }
}
