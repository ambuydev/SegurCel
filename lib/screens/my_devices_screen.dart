import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/anti_theft_cloud_sync.dart';
import '../services/anti_theft_service.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';

class MyDevicesScreen extends StatefulWidget {
  const MyDevicesScreen({super.key});

  @override
  State<MyDevicesScreen> createState() => _MyDevicesScreenState();
}

class _MyDevicesScreenState extends State<MyDevicesScreen> {
  final _loc = LocalizationService();
  bool _isAlarmActive = false;

  @override
  void initState() {
    super.initState();
    AntiTheftCloudSync.startDeviceCloudListener();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2538),
        title: Text(
          _loc.text('my_devices_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de Diagnóstico de Cuenta Firebase
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2538),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent.withAlpha(150)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Panel de Control Remoto de la Nube',
                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Email: ${user?.email ?? "Sin Sesión (Modo Local)"}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('UID: ${user?.uid ?? "N/A"}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),

              if (user == null)
                Card(
                  color: const Color(0xFF1E2538),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _loc.text('local_mode_banner'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.amberAccent),
                    ),
                  ),
                )
              else
                Card(
                  color: const Color(0xFF1E2538),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_android, color: Colors.greenAccent, size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Android Phone (SegurCel Protect)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.greenAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _loc.text('device_online'),
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Divider(color: Colors.white12, height: 24),

                        // Comandos Remotos
                        const Text(
                          'Comandos Remotos en Tiempo Real',
                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        // Botón Sirena Remota
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAlarmActive ? Colors.redAccent : const Color(0xFF10141D),
                              side: BorderSide(color: _isAlarmActive ? Colors.redAccent : Colors.amberAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(
                              _isAlarmActive ? Icons.volume_off : Icons.volume_up,
                              color: _isAlarmActive ? Colors.white : Colors.amberAccent,
                              size: 22,
                            ),
                            label: Text(
                              _isAlarmActive ? '🔇 Detener Sirena Remota' : '🔊 Disparar Sirena y Flash Strobe Remoto',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);

                              if (_isAlarmActive) {
                                await AntiTheftCloudSync.sendRemoteCommand('stop_alarm');
                                if (!kIsWeb) await AntiTheftService.stopAlarm();
                                if (mounted) setState(() => _isAlarmActive = false);
                              } else {
                                await AntiTheftCloudSync.sendRemoteCommand('start_alarm');
                                if (!kIsWeb) await AntiTheftService.startAlarm();
                                if (mounted) setState(() => _isAlarmActive = true);
                              }

                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(_loc.text('cmd_sent_toast')),
                                    backgroundColor: Colors.amber,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
