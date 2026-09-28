import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../models/password_entry.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'crypto_service.dart';

class VaultService {
  static const int maxAttempts = 3;
  static const String _vaultFileName = 'segurcel_vault.json';
  static const String _biometricKeyStorageName = 'biometric_master_key';
  static const String _webVaultStorageKey = 'web_segurcel_vault_json';

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  int _failedAttempts = 0;
  bool _isInitialized = false;
  bool _isUnlocked = false;

  SecretKey? _currentMasterKey;
  List<PasswordEntry> _entries = [];
  String? _recoveryCode;
  String? lastSyncError;

  // Caché en memoria para entorno Web
  String? _webVaultCache;

  int get failedAttempts => _failedAttempts;
  int get remainingAttempts => maxAttempts - _failedAttempts;
  bool get isInitialized => _isInitialized;
  bool get isUnlocked => _isUnlocked;
  List<PasswordEntry> get entries => List.unmodifiable(_entries);
  String? get recoveryCode => _recoveryCode;

  /// Leer el JSON de la bóveda (Compatible con Web y Nativo)
  Future<String?> _readVaultJson() async {
    if (kIsWeb) {
      if (_webVaultCache != null) return _webVaultCache;
      _webVaultCache = await _secureStorage.read(key: _webVaultStorageKey);
      return _webVaultCache;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_vaultFileName');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    }
  }

  /// Escribir el JSON de la bóveda (Compatible con Web y Nativo)
  Future<void> _writeVaultJson(String jsonStr) async {
    if (kIsWeb) {
      _webVaultCache = jsonStr;
      await _secureStorage.write(key: _webVaultStorageKey, value: jsonStr);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_vaultFileName');
      await file.writeAsString(jsonStr);
    }
  }

  /// Comprueba si existe la bóveda localmente (Compatible con Web y Nativo)
  Future<bool> _hasLocalVault() async {
    final jsonStr = await _readVaultJson();
    return jsonStr != null && jsonStr.isNotEmpty;
  }

  /// Eliminar la bóveda localmente (Compatible con Web y Nativo)
  Future<void> _deleteLocalVault() async {
    if (kIsWeb) {
      _webVaultCache = null;
      await _secureStorage.delete(key: _webVaultStorageKey);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_vaultFileName');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Obtiene el perfil de usuario desde Firestore.
  Future<UserProfile?> fetchUserProfile() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserProfile.fromJson(doc.data()!);
        } else {
          final newProfile = UserProfile(uid: user.uid, email: user.email ?? '');
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(newProfile.toJson(), SetOptions(merge: true));
          return newProfile;
        }
      }
    } catch (e) {
      debugPrint("[SegurCel Profile Error] Error al obtener perfil: $e");
    }
    return null;
  }

  /// Comprueba si la bóveda ya existe localmente o en la nube Firebase (Prioridad Local)
  Future<bool> checkVaultExists() async {
    final hasLocal = await _hasLocalVault();

    if (hasLocal) {
      _isInitialized = true;
      final jsonContent = await _readVaultJson();
      if (jsonContent != null) {
        final map = jsonDecode(jsonContent);
        _failedAttempts = map['failedAttempts'] ?? 0;
      }
      _fetchFromCloudIfAvailable();
      return true;
    } else {
      return await _fetchFromCloudIfAvailable();
    }
  }

  /// Inicializa la bóveda por primera vez definiendo un PIN.
  Future<String> setupVault(String pin, List<PasswordEntry> initialEntries) async {
    final masterKey = await CryptoService.generateMasterKey();
    _currentMasterKey = masterKey;

    // Envolver clave maestra con el PIN
    final pinSalt = CryptoService.generateSalt();
    final pinDerivedKey = await CryptoService.deriveKeyFromPassword(pin, pinSalt);
    final masterKeyBytes = Uint8List.fromList(await masterKey.extractBytes());
    final wrappedMasterKeyByPin = await CryptoService.encrypt(masterKeyBytes, pinDerivedKey);

    // Envolver clave maestra con el Código de Recuperación
    final recoveryCode = CryptoService.generateRecoveryCode();
    _recoveryCode = recoveryCode;
    final recoverySalt = CryptoService.generateSalt();
    final recoveryDerivedKey = await CryptoService.deriveKeyFromPassword(recoveryCode, recoverySalt);
    final wrappedMasterKeyByRecovery = await CryptoService.encrypt(masterKeyBytes, recoveryDerivedKey);

    // Cifrar contenido inicial
    _entries = initialEntries;
    final jsonEntries = PasswordEntry.listToJson(initialEntries);
    final encryptedData = await CryptoService.encrypt(
      Uint8List.fromList(utf8.encode(jsonEntries)),
      masterKey,
    );

    // Guardar metadata
    final vaultData = {
      'version': 1,
      'pinSalt': base64Encode(pinSalt),
      'wrappedMasterKeyByPin': base64Encode(wrappedMasterKeyByPin),
      'recoverySalt': base64Encode(recoverySalt),
      'wrappedMasterKeyByRecovery': base64Encode(wrappedMasterKeyByRecovery),
      'encryptedPasswordsData': base64Encode(encryptedData),
      'failedAttempts': 0,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _writeVaultJson(jsonEncode(vaultData));

    // Guardar para biometría local si aplica
    if (!kIsWeb) {
      await _saveBiometricMasterKey(masterKeyBytes);
    }

    // Sincronizar en la nube Firebase en segundo plano
    _syncToCloud(vaultData);

    _failedAttempts = 0;
    _isInitialized = true;
    _isUnlocked = true;

    return recoveryCode;
  }

  /// Intenta desbloquear la bóveda usando el PIN (Prioridad Local Instantánea).
  Future<bool> unlockWithPin(String pin) async {
    var jsonContent = await _readVaultJson();

    if (jsonContent == null) {
      final fetched = await _fetchFromCloudIfAvailable();
      if (!fetched) {
        throw Exception('La bóveda no existe o fue eliminada.');
      }
      jsonContent = await _readVaultJson();
    }

    if (jsonContent == null) {
      throw Exception('Error al leer la bóveda.');
    }

    final map = jsonDecode(jsonContent);
    _failedAttempts = map['failedAttempts'] ?? 0;

    if (_failedAttempts >= maxAttempts) {
      await selfDestruct();
      throw Exception('La bóveda ha sido autodestruida por superar el límite de 3 intentos.');
    }

    try {
      final pinSalt = base64Decode(map['pinSalt']);
      final wrappedMasterKeyByPin = base64Decode(map['wrappedMasterKeyByPin']);
      final encryptedPasswordsData = base64Decode(map['encryptedPasswordsData']);

      final pinDerivedKey = await CryptoService.deriveKeyFromPassword(pin, pinSalt);
      final masterKeyBytes = await CryptoService.decrypt(wrappedMasterKeyByPin, pinDerivedKey);

      final masterKey = SecretKey(masterKeyBytes);
      final plainBytes = await CryptoService.decrypt(encryptedPasswordsData, masterKey);
      final jsonStr = utf8.decode(plainBytes);

      _currentMasterKey = masterKey;
      _entries = PasswordEntry.listFromJson(jsonStr);

      // Éxito: resetear intentos
      _failedAttempts = 0;
      map['failedAttempts'] = 0;
      await _writeVaultJson(jsonEncode(map));

      if (!kIsWeb) {
        await _saveBiometricMasterKey(masterKeyBytes);
      }

      _syncToCloud(map);

      _isUnlocked = true;
      return true;

    } catch (e) {
      _failedAttempts++;
      map['failedAttempts'] = _failedAttempts;
      await _writeVaultJson(jsonEncode(map));

      if (_failedAttempts >= maxAttempts) {
        await selfDestruct();
        throw Exception('PIN incorrecto. Límite de $maxAttempts intentos alcanzado. ¡BÓVEDA AUTODESTRUIDA!');
      } else {
        throw Exception('PIN incorrecto. Te quedan $remainingAttempts intento(s).');
      }
    }
  }

  /// Recupera el acceso usando el Código de Recuperación ("Olvidé mi PIN").
  Future<bool> unlockWithRecoveryCode(String recoveryCodeInput, String newPin) async {
    final jsonContent = await _readVaultJson();
    if (jsonContent == null) {
      throw Exception('La bóveda no existe.');
    }

    final map = jsonDecode(jsonContent);

    try {
      final recoveryCodeClean = recoveryCodeInput.trim().toUpperCase();
      final recoverySalt = base64Decode(map['recoverySalt']);
      final wrappedMasterKeyByRecovery = base64Decode(map['wrappedMasterKeyByRecovery']);
      final encryptedPasswordsData = base64Decode(map['encryptedPasswordsData']);

      final recoveryDerivedKey = await CryptoService.deriveKeyFromPassword(recoveryCodeClean, recoverySalt);
      final masterKeyBytes = await CryptoService.decrypt(wrappedMasterKeyByRecovery, recoveryDerivedKey);

      final masterKey = SecretKey(masterKeyBytes);

      // Re-envolver Clave Maestra con el NUEVO PIN
      final newPinSalt = CryptoService.generateSalt();
      final newPinDerivedKey = await CryptoService.deriveKeyFromPassword(newPin, newPinSalt);
      final newWrappedMasterKeyByPin = await CryptoService.encrypt(masterKeyBytes, newPinDerivedKey);

      // Actualizar metadatos
      map['pinSalt'] = base64Encode(newPinSalt);
      map['wrappedMasterKeyByPin'] = base64Encode(newWrappedMasterKeyByPin);
      map['failedAttempts'] = 0;
      map['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _writeVaultJson(jsonEncode(map));

      _syncToCloud(map);

      final plainBytes = await CryptoService.decrypt(encryptedPasswordsData, masterKey);
      _entries = PasswordEntry.listFromJson(utf8.decode(plainBytes));

      _currentMasterKey = masterKey;
      _failedAttempts = 0;

      if (!kIsWeb) {
        await _saveBiometricMasterKey(masterKeyBytes);
      }

      _isUnlocked = true;
      return true;

    } catch (e) {
      throw Exception('El Código de Recuperación ingresado es inválido.');
    }
  }

  /// Cambia el PIN de la bóveda re-envolviendo la Clave Maestra con el nuevo PIN.
  Future<bool> changePin(String currentPin, String newPin) async {
    if (_currentMasterKey == null) {
      throw Exception('La bóveda está bloqueada.');
    }

    final jsonContent = await _readVaultJson();
    if (jsonContent == null) {
      throw Exception('La bóveda no existe.');
    }

    final map = jsonDecode(jsonContent);

    try {
      final currentPinSalt = base64Decode(map['pinSalt']);
      final wrappedMasterKeyByPin = base64Decode(map['wrappedMasterKeyByPin']);
      final currentPinDerivedKey = await CryptoService.deriveKeyFromPassword(currentPin, currentPinSalt);
      final masterKeyBytes = await CryptoService.decrypt(wrappedMasterKeyByPin, currentPinDerivedKey);

      final newPinSalt = CryptoService.generateSalt();
      final newPinDerivedKey = await CryptoService.deriveKeyFromPassword(newPin, newPinSalt);
      final newWrappedMasterKeyByPin = await CryptoService.encrypt(masterKeyBytes, newPinDerivedKey);

      map['pinSalt'] = base64Encode(newPinSalt);
      map['wrappedMasterKeyByPin'] = base64Encode(newWrappedMasterKeyByPin);
      map['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _writeVaultJson(jsonEncode(map));

      _syncToCloud(map);

      if (!kIsWeb) {
        await _saveBiometricMasterKey(masterKeyBytes);
      }

      return true;
    } catch (e) {
      throw Exception('El PIN actual ingresado es incorrecto.');
    }
  }

  /// Comprueba si la autenticación biométrica está disponible.
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final hasSavedKey = await _secureStorage.containsKey(key: _biometricKeyStorageName);
      return (canCheck || isSupported) && hasSavedKey;
    } catch (_) {
      return false;
    }
  }

  /// Desbloquea la bóveda utilizando Huella Digital / Biometría.
  Future<bool> unlockWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentícate para desbloquear tu bóveda de SegurCel',
      );

      if (!authenticated) return false;

      final savedKeyBase64 = await _secureStorage.read(key: _biometricKeyStorageName);
      if (savedKeyBase64 == null) return false;

      final masterKeyBytes = base64Decode(savedKeyBase64);
      final jsonContent = await _readVaultJson();
      if (jsonContent == null) return false;

      final map = jsonDecode(jsonContent);
      final encryptedPasswordsData = base64Decode(map['encryptedPasswordsData']);

      final masterKey = SecretKey(masterKeyBytes);
      final plainBytes = await CryptoService.decrypt(encryptedPasswordsData, masterKey);

      _currentMasterKey = masterKey;
      _entries = PasswordEntry.listFromJson(utf8.decode(plainBytes));

      _failedAttempts = 0;
      map['failedAttempts'] = 0;
      await _writeVaultJson(jsonEncode(map));

      _isUnlocked = true;
      return true;
    } catch (e) {
      throw Exception('Falló la autenticación biométrica: $e');
    }
  }

  /// Guarda nuevas contraseñas o actualiza las existentes.
  Future<void> saveEntries(List<PasswordEntry> newEntries) async {
    if (_currentMasterKey == null) {
      throw Exception('La bóveda está bloqueada.');
    }

    _entries = newEntries;
    final jsonStr = PasswordEntry.listToJson(newEntries);
    final encryptedData = await CryptoService.encrypt(
      Uint8List.fromList(utf8.encode(jsonStr)),
      _currentMasterKey!,
    );

    final jsonContent = await _readVaultJson();
    final map = jsonContent != null ? jsonDecode(jsonContent) : <String, dynamic>{};

    map['encryptedPasswordsData'] = base64Encode(encryptedData);
    map['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _writeVaultJson(jsonEncode(map));

    _syncToCloud(map);
  }

  /// Bloquea la bóveda y elimina claves en memoria. En Web borra el caché local por seguridad en PCs compartidas.
  void lock() {
    _currentMasterKey = null;
    _entries = [];
    _isUnlocked = false;
    if (kIsWeb) {
      _deleteLocalVault();
    }
  }

  /// Elimina por completo los archivos y claves locales (Autodestrucción local y periodo de gracia 48h en la nube).
  Future<void> selfDestruct() async {
    await _deleteLocalVault();
    await _secureStorage.delete(key: _biometricKeyStorageName);

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final profile = await fetchUserProfile();
        if (profile != null && !profile.isPremium) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final expires = now + (48 * 3600 * 1000); // 48 horas en milisegundos

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'selfDestructedAt': now,
            'gracePeriodExpiresAt': expires,
          }, SetOptions(merge: true));
        }
      }
    } catch (_) {}

    _currentMasterKey = null;
    _entries = [];
    _failedAttempts = 0;
    _isInitialized = false;
    _isUnlocked = false;
  }

  Future<void> _saveBiometricMasterKey(Uint8List masterKeyBytes) async {
    try {
      await _secureStorage.write(
        key: _biometricKeyStorageName,
        value: base64Encode(masterKeyBytes),
      );
    } catch (_) {}
  }

  Future<void> _syncToCloud(Map<String, dynamic> vaultData) async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        vaultData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('vault')
            .doc('main')
            .set(vaultData, SetOptions(merge: true));
        debugPrint("[SegurCel Sync] Bóveda cifrada subida exitosamente a Firestore para UID: ${user.uid}");
      }
    } catch (e) {
      debugPrint("[SegurCel Sync Error] Modo offline o sin red: $e");
    }
  }

  Future<bool> _fetchFromCloudIfAvailable() async {
    lastSyncError = null;
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final profile = await fetchUserProfile();

        // Si el periodo de gracia de 48 horas expiró para un usuario Free, borrar el respaldo en la nube
        if (profile != null && profile.isGracePeriodExpired) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('vault')
              .doc('main');
          await docRef.delete();

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'selfDestructedAt': null,
            'gracePeriodExpiresAt': null,
          }, SetOptions(merge: true));

          debugPrint("[SegurCel Grace Expired] Respaldo en la nube eliminado tras 48hs.");
          return false;
        }

        debugPrint("[SegurCel Sync] Consultando Firestore para UID: ${user.uid}...");
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('vault')
            .doc('main');

        final doc = await docRef.get();
        final localJson = await _readVaultJson();
        final localFileExists = localJson != null && localJson.isNotEmpty;

        if (doc.exists && doc.data() != null) {
          final cloudData = doc.data()!;
          debugPrint("[SegurCel Sync] ¡Bóveda encontrada en Firestore!");

          if (localFileExists) {
            final localMap = jsonDecode(localJson);
            final localUpdatedAt = localMap['updatedAt'] ?? 0;
            final cloudUpdatedAt = cloudData['updatedAt'] ?? 0;

            if (cloudUpdatedAt > localUpdatedAt) {
              await _writeVaultJson(jsonEncode(cloudData));
              debugPrint("[SegurCel Sync] Se descargó la bóveda más reciente desde Firestore.");
            } else if (localUpdatedAt >= cloudUpdatedAt) {
              _syncToCloud(localMap);
            }
          } else {
            await _writeVaultJson(jsonEncode(cloudData));
            debugPrint("[SegurCel Sync] Bóveda descargada desde Firestore.");
          }

          _isInitialized = true;
          return true;
        } else {
          debugPrint("[SegurCel Sync] No existe aún documento en Firestore para el UID: ${user.uid}");
          if (localFileExists) {
            final localMap = jsonDecode(localJson);
            _syncToCloud(localMap);
            _isInitialized = true;
            return true;
          }
        }
      }
    } catch (e) {
      lastSyncError = e.toString();
      debugPrint("[SegurCel Sync Warning] Consulta a la nube no completada: $e");
    }
    return false;
  }
}
