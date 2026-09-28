import 'package:flutter/material.dart';
import '../services/vault_service.dart';
import 'home_screen.dart';

class RecoveryScreen extends StatefulWidget {
  final VaultService vaultService;

  const RecoveryScreen({super.key, required this.vaultService});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _codeController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _recoverVault() async {
    final code = _codeController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Ingresa el código de recuperación.');
      return;
    }

    if (newPin.length != 4) {
      setState(() => _errorMessage = 'El nuevo PIN debe tener exactamente 4 dígitos.');
      return;
    }

    if (newPin != confirm) {
      setState(() => _errorMessage = 'Los PINs no coinciden.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.vaultService.unlockWithRecoveryCode(code, newPin);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bóveda recuperada con éxito! Se actualizó tu PIN.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(vaultService: widget.vaultService),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recuperar Acceso'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.key_outlined, size: 70, color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              const Text(
                'Olvidé mi PIN',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu Código de Recuperación de 24 caracteres para desbloquear la bóveda y definir un nuevo PIN.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 28),

              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Código de Recuperación',
                  hintText: 'ABCD-1234-EFGH-5678-...',
                  hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 0),
                  labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
                  filled: true,
                  fillColor: const Color(0xFF1E2538),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Nuevo PIN (4 dígitos)',
                  labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
                  filled: true,
                  fillColor: const Color(0xFF1E2538),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nuevo PIN',
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

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _recoverVault,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Restablecer y Desbloquear',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
