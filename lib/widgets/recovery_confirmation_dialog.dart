import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../services/localization_service.dart';
import '../services/vault_service.dart';

class RecoveryConfirmationDialog extends StatefulWidget {
  final VaultService vaultService;
  final LocalizationService loc;
  final BuildContext parentContext;

  const RecoveryConfirmationDialog({
    super.key,
    required this.vaultService,
    required this.loc,
    required this.parentContext,
  });

  @override
  State<RecoveryConfirmationDialog> createState() => _RecoveryConfirmationDialogState();
}

class _RecoveryConfirmationDialogState extends State<RecoveryConfirmationDialog> {
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTimerDone = _secondsLeft == 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2538),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.loc.text('confirm_recovery_title'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          widget.loc.text('confirm_recovery_desc'),
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          child: Text(
            widget.loc.text('confirm_recovery_back'),
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isTimerDone ? const Color(0xFF6C63FF) : Colors.white12,
            foregroundColor: isTimerDone ? Colors.white : Colors.white38,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: isTimerDone
              ? () {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                  if (widget.parentContext.mounted) {
                    Navigator.of(widget.parentContext).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(vaultService: widget.vaultService),
                      ),
                    );
                  }
                }
              : null,
          child: Text(
            isTimerDone
                ? widget.loc.text('confirm_recovery_yes')
                : widget.loc.text('understood_timer').replaceAll('{seconds}', _secondsLeft.toString()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isTimerDone ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ],
    );
  }
}
