import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);
    final appBarBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final buttonBg = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final accentAmber = isDark ? Colors.amberAccent : const Color(0xFFD97706);
    final accentGreen = isDark ? Colors.greenAccent : const Color(0xFF137333);
    final accentCyan = isDark ? Colors.cyanAccent : const Color(0xFF00796B);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        title: Text(
          _loc.text('my_devices_title'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
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
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentAmber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: accentAmber, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loc.text('emergency_tracking_center'),
                            style: TextStyle(color: accentAmber, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Email: ${user?.email ?? "Sin Sesión (Modo Local)"}', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('UID: ${user?.uid ?? "N/A"}', style: TextStyle(color: textSubColor, fontSize: 11)),
                  ],
                ),
              ),

              // Tarjeta 1: Google Encontrar mi Dispositivo (Android)
              Card(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accentGreen, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.android, color: accentGreen, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _loc.text('google_find_device'),
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  _loc.text('google_find_sub'),
                                  style: TextStyle(color: accentGreen, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 24),
                      Text(
                        _loc.text('google_find_desc'),
                        style: TextStyle(color: textSubColor, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBg,
                            side: BorderSide(color: accentGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(Icons.open_in_new, color: accentGreen, size: 20),
                          label: Text(
                            _loc.text('open_google_find'),
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () {
                            FileHelper.openUrl('https://google.com/android/find');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tarjeta 2: Apple Buscar mi iPhone (iOS / iCloud)
              Card(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accentCyan, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.apple, color: accentCyan, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _loc.text('apple_find_device'),
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  _loc.text('apple_find_sub'),
                                  style: TextStyle(color: accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 24),
                      Text(
                        _loc.text('apple_find_desc'),
                        style: TextStyle(color: textSubColor, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBg,
                            side: BorderSide(color: accentCyan),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(Icons.open_in_new, color: accentCyan, size: 20),
                          label: Text(
                            _loc.text('open_apple_find'),
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () {
                            FileHelper.openUrl('https://icloud.com/find');
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
