import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/anti_theft_cloud_sync.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../utils/file_helper.dart';

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
                          'Control Remoto Nube SegurCel',
                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        if (kIsWeb)
                          // Botón Sirena Remota (Solo visible en la Web)
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
                                final targetCommand = _isAlarmActive ? 'stop_alarm' : 'start_alarm';
                                final success = await AntiTheftCloudSync.sendRemoteCommand(targetCommand);

                                if (success) {
                                  if (mounted) setState(() => _isAlarmActive = !_isAlarmActive);
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(_isAlarmActive
                                            ? '🔊 Comando enviado: ¡Sirena y Flash activados!'
                                            : '🔇 Comando enviado: Sirena detenida.'),
                                        backgroundColor: Colors.amber,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('⚠️ No se pudo conectar con la Nube. Verifica la sesión.'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          )
                        else
                          // Mensaje orientativo en el celular
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10141D),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.cyanAccent, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'El disparo remoto de sirena se ejecuta desde la Web oficial https://segurcel.app cuando tu teléfono está extraviado.',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Enlace Oficial a Google Find My Device
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10141D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.greenAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: Colors.greenAccent, size: 24),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Google Encontrar mi Dispositivo (Oficial)',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Servicio oficial de Google con privilegios de sistema para rastrear GPS, sonar o formatear tu teléfono.',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new, color: Colors.greenAccent, size: 20),
                                onPressed: () {
                                  FileHelper.openUrl('https://google.com/android/find');
                                },
                              ),
                            ],
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
