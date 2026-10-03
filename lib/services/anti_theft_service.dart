import 'package:flutter/services.dart';

class AntiTheftService {
  static const MethodChannel _channel = MethodChannel('com.segurcel.protect/anti_theft');

  /// Inicia la sirena de alarma a máximo volumen y parpadeo de linterna LED
  static Future<bool> startAlarm() async {
    try {
      final bool? result = await _channel.invokeMethod('startAlarm');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Detiene la sirena de alarma y el parpadeo de linterna LED
  static Future<bool> stopAlarm() async {
    try {
      final bool? result = await _channel.invokeMethod('stopAlarm');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre la pantalla nativa de permisos del sistema (Xiaomi/Samsung)
  static Future<bool> openAppSettings() async {
    try {
      final bool? result = await _channel.invokeMethod('openAppSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Arranca el servicio nativo persistente en primer plano (estilo Samsung Health)
  static Future<bool> startForegroundService() async {
    try {
      final bool? result = await _channel.invokeMethod('startForegroundService');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
