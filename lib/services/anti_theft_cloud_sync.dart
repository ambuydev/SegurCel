import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'anti_theft_service.dart';
import 'auth_service.dart';

class AntiTheftCloudSync {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<DocumentSnapshot>? _deviceSubscription;

  /// Inicia la escucha activa de comandos remotos en el dispositivo móvil Android vinculada a authStateChanges
  static void startDeviceCloudListener() {
    if (kIsWeb) return;

    _authSubscription?.cancel();
    _authSubscription = AuthService().authStateChanges.listen((user) {
      if (user == null) {
        _deviceSubscription?.cancel();
        return;
      }

      final deviceId = 'android_phone';
      _deviceSubscription?.cancel();

      final deviceDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId);

      _deviceSubscription = deviceDocRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        final cmd = data?['pendingCommand'] as String?;

        if (cmd == 'start_alarm') {
          await deviceDocRef.set({'pendingCommand': 'none'}, SetOptions(merge: true));
          await AntiTheftService.startAlarm();
        } else if (cmd == 'stop_alarm') {
          await deviceDocRef.set({'pendingCommand': 'none'}, SetOptions(merge: true));
          await AntiTheftService.stopAlarm();
        }
      });
    });
  }

  /// Envía un comando remoto instantáneo desde la Web Vault o la App
  static Future<bool> sendRemoteCommand(String command) async {
    final user = AuthService().currentUser;
    if (user == null) {
      return false;
    }

    final deviceId = 'android_phone';

    try {
      final deviceDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId);

      await deviceDocRef.set({
        'pendingCommand': command,
        'commandTimestamp': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Detiene la escucha de comandos al cerrar sesión
  static void stopDeviceCloudListener() {
    _authSubscription?.cancel();
    _deviceSubscription?.cancel();
  }
}
