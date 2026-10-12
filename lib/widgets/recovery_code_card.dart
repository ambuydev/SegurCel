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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.amber),
        const SizedBox(height: 16),
        Text(
          loc.text('save_recovery_code_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          loc.text('save_recovery_code_subtitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2538),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withAlpha(128)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  recoveryCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white70),
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
