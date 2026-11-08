import 'package:segurcel/i18n/ar.dart';
import 'package:segurcel/i18n/de.dart';
import 'package:segurcel/i18n/en.dart';
import 'package:segurcel/i18n/es.dart';
import 'package:segurcel/i18n/fr.dart';
import 'package:segurcel/i18n/hi.dart';
import 'package:segurcel/i18n/id.dart';
import 'package:segurcel/i18n/it.dart';
import 'package:segurcel/i18n/ja.dart';
import 'package:segurcel/i18n/ko.dart';
import 'package:segurcel/i18n/pt.dart';
import 'package:segurcel/i18n/ru.dart';
import 'package:segurcel/i18n/zh.dart';
import 'package:segurcel/i18n/zh_hk.dart';

void main() {
  final Map<String, Map<String, String>> translations = {
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

  print('=== AUDITING ALL 175 LOCALIZATION KEYS ACROSS ALL 14 LANGUAGES ===');

  final esKeys = esTranslation.keys.toSet();
  int totalMissing = 0;

  for (final lang in translations.keys) {
    if (lang == 'es') continue;
    final map = translations[lang]!;
    final missing = esKeys.difference(map.keys.toSet());

    if (missing.isNotEmpty) {
      print('\n❌ LANGUAGE [$lang] IS MISSING ${missing.length} KEYS:');
      for (final k in missing) {
        print('   - $k');
      }
      totalMissing += missing.length;
    } else {
      print('✅ [$lang] Has ALL ${esKeys.length} keys!');
    }
  }

  print('\n----------------------------------------');
  if (totalMissing == 0) {
    print('🎉 PERFECT! 100% OF LOCALIZATION KEYS ARE PRESENT ACROSS ALL 14 LANGUAGES!');
  } else {
    print('⚠️ TOTAL MISSING KEYS ACROSS ALL LANGUAGES: $totalMissing');
  }
}
