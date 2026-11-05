import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../i18n/ar.dart';
import '../i18n/de.dart';
import '../i18n/en.dart';
import '../i18n/es.dart';
import '../i18n/fr.dart';
import '../i18n/hi.dart';
import '../i18n/id.dart';
import '../i18n/it.dart';
import '../i18n/ja.dart';
import '../i18n/ko.dart';
import '../i18n/pt.dart';
import '../i18n/ru.dart';
import '../i18n/zh.dart';
import '../i18n/zh_hk.dart';
import '../utils/secure_storage_helper.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _storageKey = 'segurcel_app_language';

  String _currentLanguage = 'es'; // 'es', 'en', 'pt', 'zh', 'fr', 'hi', 'de', 'ja', 'ko', 'ru', 'it', 'ar', 'id', 'zh_HK'

  String get currentLanguage => _currentLanguage;
  bool get isRtl => _currentLanguage == 'ar';

  Future<void> initLanguage() async {
    try {
      if (kIsWeb) {
        final queryLang = Uri.base.queryParameters['lang'];
        if (queryLang != null && _translations.containsKey(queryLang)) {
          _currentLanguage = queryLang;
          await SecureStorageHelper.safeWrite(_storageKey, queryLang);
          notifyListeners();
          return;
        }
      }

      final savedLang = await SecureStorageHelper.safeRead(_storageKey);
      if (savedLang != null && _translations.containsKey(savedLang)) {
        _currentLanguage = savedLang;
      } else {
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        if (_translations.containsKey(systemLocale)) {
          _currentLanguage = systemLocale;
        } else {
          _currentLanguage = 'es';
        }
      }
    } catch (_) {
      _currentLanguage = 'es';
    }
    notifyListeners();
  }

  Future<void> changeLanguage(String langCode) async {
    if (_translations.containsKey(langCode)) {
      _currentLanguage = langCode;
      await SecureStorageHelper.safeWrite(_storageKey, langCode);
      notifyListeners();
    }
  }

  String text(String key) {
    final langMap = _translations[_currentLanguage] ?? _translations['es']!;
    return langMap[key] ?? _translations['es']![key] ?? key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'es': esTranslation,
    'en': enTranslation,
    'pt': ptTranslation,
    'zh': zhTranslation,
    'zh_HK': zhHkTranslation,
    'fr': frTranslation,
    'hi': hiTranslation,
    'de': deTranslation,
    'ja': jaTranslation,
    'ko': koTranslation,
    'ru': ruTranslation,
    'it': itTranslation,
    'ar': arTranslation,
    'id': idTranslation,
  };
}
