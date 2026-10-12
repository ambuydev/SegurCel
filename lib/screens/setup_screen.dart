import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/localization_service.dart';
import '../services/vault_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final VaultService vaultService;

  const SetupScreen({super.key, required this.vaultService});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _loc = LocalizationService();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  String? _generatedRecoveryCode;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createVault() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length != 4) {
      setState(() => _errorMessage = _loc.text('pin_error'));
      return;
    }

    if (pin != confirm) {
      setState(() => _errorMessage = _loc.text('pin_error'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recoveryCode = await widget.vaultService.setupVault(pin, []);
      setState(() {
        _generatedRecoveryCode = recoveryCode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _finishSetup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _RecoveryConfirmationDialog(
        vaultService: widget.vaultService,
        loc: _loc,
        parentContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_loc.text('welcome')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _generatedRecoveryCode != null
              ? _buildRecoveryCodeView()
              : _buildPinCreationForm(),
        ),
      ),
    );
  }

  Widget _buildPinCreationForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Color(0xFF6C63FF)),
          const SizedBox(height: 20),
          Text(
            _loc.text('welcome'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            _loc.text('setup_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 30),

          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: _loc.text('new_pin'),
              labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
              filled: true,
              fillColor: const Color(0xFF1E2538),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: _loc.text('confirm_new_pin'),
              labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
              filled: true,
              fillColor: const Color(0xFF1E2538),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ],

          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _createVault,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _loc.text('create_vault'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCodeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.amber),
        const SizedBox(height: 16),
        Text(
          _loc.text('save_recovery_code_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          _loc.text('save_recovery_code_subtitle'),
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
                  _generatedRecoveryCode!,
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
                  Clipboard.setData(ClipboardData(text: _generatedRecoveryCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_loc.text('copied_toast'))),
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
          onPressed: _finishSetup,
          child: Text(
            _loc.text('enter_segurcel'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _RecoveryConfirmationDialog extends StatefulWidget {
  final VaultService vaultService;
  final LocalizationService loc;
  final BuildContext parentContext;

  const _RecoveryConfirmationDialog({
    required this.vaultService,
    required this.loc,
    required this.parentContext,
  });

  @override
  State<_RecoveryConfirmationDialog> createState() => _RecoveryConfirmationDialogState();
}

class _RecoveryConfirmationDialogState extends State<_RecoveryConfirmationDialog> {
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
