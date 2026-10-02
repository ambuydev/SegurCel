import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'anti_theft_service.dart';
import 'auth_service.dart';

class AntiTheftCloudSync {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _commandSubscription;

  /// Inicia la escucha activa de comandos remotos en el dispositivo móvil Android
  static void startDeviceCloudListener() {
    if (kIsWeb) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    final deviceId = 'android_phone';
    _commandSubscription?.cancel();

    final commandsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(deviceId)
        .collection('commands');

    _commandSubscription = commandsRef
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final cmd = data['command'] as String?;
        if (cmd == null) continue;

        await doc.reference.update({'status': 'processing'});

        if (cmd == 'start_alarm') {
          await AntiTheftService.startAlarm();
        } else if (cmd == 'stop_alarm') {
          await AntiTheftService.stopAlarm();
        }

        await doc.reference.update({
          'status': 'executed',
          'executedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Envía un comando remoto desde la Web Vault o la App
  static Future<void> sendRemoteCommand(String command) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final deviceId = 'android_phone';

    final commandsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(deviceId)
        .collection('commands');

    await commandsRef.add({
      'command': command,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Detiene la escucha de comandos al cerrar sesión
  static void stopDeviceCloudListener() {
    _commandSubscription?.cancel();
  }
}
