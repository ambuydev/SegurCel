import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Leemos de forma 100% segura. Si el KeyStore de Android se corrompe durante una actualización,
  /// resetOnError repara la clave y retorna null de forma limpia sin detener la app.
  static Future<String?> safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[SecureStorage Read Warning for $key]: $e');
      try {
        await _storage.delete(key: key);
      } catch (_) {}
      return null;
    }
  }

  /// Escribimos de forma 100% segura.
  static Future<void> safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[SecureStorage Write Warning for $key]: $e');
      try {
        await _storage.deleteAll();
        await _storage.write(key: key, value: value);
      } catch (err) {
        debugPrint('[SecureStorage Retry Write Error]: $err');
      }
    }
  }

  /// Eliminamos de forma 100% segura.
  static Future<void> safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[SecureStorage Delete Warning for $key]: $e');
    }
  }

  /// Limpiamos todo de forma 100% segura.
  static Future<void> safeDeleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[SecureStorage DeleteAll Warning]: $e');
    }
  }
}
