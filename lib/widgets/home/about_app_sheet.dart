import 'package:flutter/material.dart';
import '../../services/localization_service.dart';
import '../../utils/file_helper.dart';
import 'package:flutter/services.dart';

class AboutAppSheet extends StatelessWidget {
  final LocalizationService loc;

  const AboutAppSheet({super.key, required this.loc});

  static void show(BuildContext context, LocalizationService loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AboutAppSheet(loc: loc),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ${loc.text("copied_toast")}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSpecBullet(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4A5568), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final buttonBg = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.text('about_app'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icon/app_icon.png',
                      height: 64,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.security, size: 60, color: Color(0xFF6C63FF)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.text('app_title'),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.text('app_version'),
                      style: TextStyle(color: textSubColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Desarrollado por Alejandro Martínez Briao',
                      style: TextStyle(color: isDark ? Colors.amberAccent : const Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '© 2026 SegurCel. Todos los derechos reservados.',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                loc.text('about_desc'),
                style: TextStyle(color: textSubColor, fontSize: 13, height: 1.4),
              ),

              const SizedBox(height: 20),

              Text(
                loc.text('tech_specs'),
                style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildSpecBullet(context, Icons.lock_outline, loc.text('spec_1')),
              _buildSpecBullet(context, Icons.fingerprint, loc.text('spec_2')),
              _buildSpecBullet(context, Icons.local_fire_department, loc.text('spec_3')),
              _buildSpecBullet(context, Icons.cloud_done_outlined, loc.text('spec_4')),
              _buildSpecBullet(context, Icons.verified_user_outlined, loc.text('spec_5')),

              const SizedBox(height: 20),

              // Botones de acción (Sitio Web, Privacidad, Soporte)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBg,
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.language, color: Color(0xFF6C63FF), size: 18),
                      label: Text(
                        'Sitio Web',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        FileHelper.openUrl('https://segurcel.app');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBg,
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6C63FF), size: 18),
                      label: Text(
                        loc.text('privacy_policy'),
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        try {
                          FileHelper.openUrl('https://segurcel.app/privacy.html');
                        } catch (_) {
                          _copyToClipboard(context, 'https://segurcel.app/privacy.html', loc.text('privacy_policy'));
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBg,
                  side: BorderSide(color: isDark ? Colors.amberAccent : const Color(0xFFD97706)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.mail_outline, color: isDark ? Colors.amberAccent : const Color(0xFFD97706), size: 18),
                label: Text(
                  'Soporte Oficial (soporte@segurcel.app)',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () {
                  try {
                    FileHelper.openUrl('mailto:soporte@segurcel.app');
                  } catch (_) {
                    _copyToClipboard(context, 'soporte@segurcel.app', 'Soporte Oficial');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
