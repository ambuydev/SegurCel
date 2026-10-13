import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/localization_service.dart';
import '../../utils/file_helper.dart';

class AboutAppSheet extends StatelessWidget {
  final LocalizationService loc;

  const AboutAppSheet({super.key, required this.loc});

  static void show(BuildContext context, LocalizationService loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2538),
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

  Widget _buildSpecBullet(IconData icon, String text) {
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
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  loc.text('app_version'),
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            loc.text('tech_specs'),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildSpecBullet(Icons.lock_outline, loc.text('spec_1')),
          _buildSpecBullet(Icons.fingerprint, loc.text('spec_2')),
          _buildSpecBullet(Icons.local_fire_department, loc.text('spec_3')),
          _buildSpecBullet(Icons.cloud_done_outlined, loc.text('spec_4')),
          _buildSpecBullet(Icons.verified_user_outlined, loc.text('spec_5')),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10141D),
              side: const BorderSide(color: Color(0xFF6C63FF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6C63FF)),
            label: Text(
              loc.text('privacy_policy'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              try {
                FileHelper.openUrl('https://segurcel.app/privacy');
              } catch (_) {
                _copyToClipboard(context, 'https://segurcel.app/privacy', loc.text('privacy_policy'));
              }
            },
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.code, color: Colors.amberAccent),
            label: const Text(
              '⭐ GitHub - Código Auditable',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              try {
                FileHelper.openUrl('https://github.com/ambuydev/SegurCel');
              } catch (_) {
                _copyToClipboard(context, 'https://github.com/ambuydev/SegurCel', 'GitHub');
              }
            },
          ),
        ],
      ),
    );
  }
}
