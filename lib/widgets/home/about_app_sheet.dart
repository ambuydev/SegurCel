import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/localization_service.dart';
import '../../utils/file_helper.dart';
import 'onboarding_sheet.dart';

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

  Widget _buildListOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: textSubColor, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white38 : Colors.black38, size: 14),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

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
              const SizedBox(height: 12),

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
                      loc.text('developed_by'),
                      style: TextStyle(color: isDark ? Colors.amberAccent : const Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.text('all_rights_reserved'),
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
              Divider(color: dividerColor),

              // Opciones de Soporte y Contacto Oficial
              _buildListOptionTile(
                context,
                icon: Icons.language,
                iconColor: Colors.cyan,
                title: loc.text('official_website'),
                subtitle: 'https://segurcel.app',
                onTap: () => FileHelper.openUrl('https://segurcel.app'),
              ),
              Divider(color: dividerColor, height: 1),

              _buildListOptionTile(
                context,
                icon: Icons.email_outlined,
                iconColor: Colors.amber,
                title: loc.text('support_email'),
                subtitle: 'support.segurcel@gmail.com',
                onTap: () {
                  try {
                    FileHelper.openUrl('mailto:support.segurcel@gmail.com');
                  } catch (_) {
                    _copyToClipboard(context, 'support.segurcel@gmail.com', loc.text('support_email'));
                  }
                },
              ),
              Divider(color: dividerColor, height: 1),

              _buildListOptionTile(
                context,
                icon: Icons.star_rate_rounded,
                iconColor: Colors.amberAccent,
                title: loc.text('rate_app'),
                subtitle: loc.text('rate_app_sub'),
                onTap: () {
                  if (defaultTargetPlatform == TargetPlatform.iOS) {
                    FileHelper.openUrl('https://apps.apple.com/app/segurcel/id1793766361');
                  } else {
                    FileHelper.openUrl('https://play.google.com/store/apps/details?id=com.segurcel.segurcel');
                  }
                },
              ),
              Divider(color: dividerColor, height: 1),

              _buildListOptionTile(
                context,
                icon: Icons.auto_awesome,
                iconColor: const Color(0xFF6C63FF),
                title: loc.text('view_welcome_guide'),
                subtitle: loc.text('welcome_guide_sub'),
                onTap: () {
                  Navigator.of(context).pop();
                  OnboardingSheet.show(context, loc);
                },
              ),
              Divider(color: dividerColor, height: 1),

              _buildListOptionTile(
                context,
                icon: Icons.share_outlined,
                iconColor: Colors.lightBlueAccent,
                title: loc.text('share_app'),
                subtitle: loc.text('share_app_sub'),
                onTap: () {
                  Share.share(
                    loc.text('share_app_msg'),
                  );
                },
              ),
              Divider(color: dividerColor, height: 1),

              _buildListOptionTile(
                context,
                icon: Icons.menu_book_outlined,
                iconColor: Colors.tealAccent,
                title: loc.text('user_guide'),
                subtitle: 'https://segurcel.app/guide.html',
                onTap: () => FileHelper.openUrl('https://segurcel.app/guide.html'),
              ),
              Divider(color: dividerColor, height: 1),

              _buildListOptionTile(
                context,
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.purpleAccent,
                title: loc.text('privacy_policy'),
                subtitle: 'https://segurcel.app/privacy.html',
                onTap: () => FileHelper.openUrl('https://segurcel.app/privacy.html'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
