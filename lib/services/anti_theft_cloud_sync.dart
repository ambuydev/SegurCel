import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'anti_theft_service.dart';
import 'auth_service.dart';

class AntiTheftCloudSync {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<DocumentSnapshot>? _deviceSubscription;

  /// Inicia la escucha activa de comandos remotos y configura FCM
  static void startDeviceCloudListener() {
    if (kIsWeb) return;

    _authSubscription?.cancel();
    _authSubscription = AuthService().authStateChanges.listen((user) async {
      if (user == null) {
        _deviceSubscription?.cancel();
        return;
      }

      // 1. Solicita permiso de notificaciones Push en Android 13/14 y guarda Token FCM
      try {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        final token = await _messaging.getToken();
        if (token != null) {
          final userDocRef = _firestore.collection('users').doc(user.uid);
          await userDocRef.set({
            'fcmToken': token,
            'fcmUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}

      // 2. Escucha de Firestore en vivo
      _deviceSubscription?.cancel();
      final userDocRef = _firestore.collection('users').doc(user.uid);

      _deviceSubscription = userDocRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        final cmd = data?['pendingCommand'] as String?;

        if (cmd == 'start_alarm') {
          await userDocRef.set({'pendingCommand': 'none'}, SetOptions(merge: true));
          await AntiTheftService.startAlarm();
        } else if (cmd == 'stop_alarm') {
          await userDocRef.set({'pendingCommand': 'none'}, SetOptions(merge: true));
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

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);

      await userDocRef.set({
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
