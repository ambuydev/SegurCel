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
}
