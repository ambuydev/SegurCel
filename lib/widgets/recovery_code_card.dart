import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/localization_service.dart';

class RecoveryCodeCard extends StatelessWidget {
  final String recoveryCode;
  final VoidCallback onFinishSetup;
  final LocalizationService loc;

  const RecoveryCodeCard({
    super.key,
    required this.recoveryCode,
    required this.onFinishSetup,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final cardBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final accentAmber = isDark ? Colors.amberAccent : const Color(0xFFD97706);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.warning_amber_rounded, size: 80, color: accentAmber),
        const SizedBox(height: 16),
        Text(
          loc.text('save_recovery_code_title'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        Text(
          loc.text('save_recovery_code_subtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(color: textSubColor, fontSize: 14),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentAmber),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  recoveryCode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: accentAmber,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: isDark ? Colors.white70 : Colors.black54),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: recoveryCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.text('copied_toast'))),
                  );
                },
              ),
            ],
          ),
        ),

        const Spacer(),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onFinishSetup,
          child: Text(
            loc.text('enter_segurcel'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
