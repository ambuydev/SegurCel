import 'package:segurcel/services/localization_service.dart';

void main() {
  final loc = LocalizationService();
  final languages = ['es', 'en', 'pt', 'zh', 'fr', 'hi', 'de', 'ja', 'ko', 'ru'];
  
  // Get all keys from 'es'
  loc.changeLanguage('es');
  
  print('=== CHECKING ALL LOCALIZATION KEYS ACROSS 10 LANGUAGES ===');
  
  int missingCount = 0;
  
  // Test a comprehensive list of keys
  final sampleKeys = [
    'app_title', 'welcome', 'setup_subtitle', 'save_recovery_code_title',
    'save_recovery_code_subtitle', 'confirm_recovery_title', 'confirm_recovery_desc',
    'confirm_recovery_yes', 'confirm_recovery_back', 'understood_timer',
    'enter_segurcel', 'free_limits', 'about_app', 'app_version', 'tech_specs',
    'privacy_policy', 'delete_password', 'delete_confirm', 'cancel', 'delete'
  ];

  for (final lang in languages) {
    loc.changeLanguage(lang);
    for (final key in sampleKeys) {
      final val = loc.text(key);
      if (val == key) {
        print('MISSING KEY! Lang: $lang | Key: $key');
        missingCount++;
      }
    }
  }

  if (missingCount == 0) {
    print('ALL CHECKED KEYS ARE PRESENT IN ALL 10 LANGUAGES!');
  } else {
    print('FOUND $missingCount MISSING KEYS!');
  }
}
