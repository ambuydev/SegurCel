import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class PinCreationForm extends StatefulWidget {
  final Function(String pin) onSubmitPin;
  final bool isLoading;
  final String? errorMessage;
  final LocalizationService loc;

  const PinCreationForm({
    super.key,
    required this.onSubmitPin,
    required this.isLoading,
    required this.errorMessage,
    required this.loc,
  });

  @override
  State<PinCreationForm> createState() => _PinCreationFormState();
}

class _PinCreationFormState extends State<PinCreationForm> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length != 4 || pin != confirm) {
      setState(() {
        _localError = widget.loc.text('pin_error');
      });
      return;
    }

    setState(() {
      _localError = null;
    });

    widget.onSubmitPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    final displayError = widget.errorMessage ?? _localError;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Color(0xFF6C63FF)),
          const SizedBox(height: 20),
          Text(
            widget.loc.text('welcome'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            widget.loc.text('setup_subtitle'),
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
              labelText: widget.loc.text('new_pin'),
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
              labelText: widget.loc.text('confirm_new_pin'),
              labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
              filled: true,
              fillColor: const Color(0xFF1E2538),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          if (displayError != null) ...[
            const SizedBox(height: 12),
            Text(
              displayError,
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
            onPressed: widget.isLoading ? null : _submit,
            child: widget.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.loc.text('create_vault'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
