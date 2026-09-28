import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vault_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final VaultService vaultService;

  const SetupScreen({super.key, required this.vaultService});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  String? _generatedRecoveryCode;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createVault() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length != 4) {
      setState(() => _errorMessage = 'El PIN debe tener exactamente 4 dígitos.');
      return;
    }

    if (pin != confirm) {
      setState(() => _errorMessage = 'Los PINs no coinciden.');
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
        _errorMessage = 'Error al crear la bóveda: $e';
        _isLoading = false;
      });
    }
  }

  void _finishSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(vaultService: widget.vaultService),
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
        title: const Text('Configuración Inicial'),
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
          const Text(
            'Bienvenido a SegurCel',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Crea un PIN seguro para proteger tus contraseñas cifradas en tu dispositivo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
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
              labelText: 'Nuevo PIN (4 dígitos)',
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
              labelText: 'Confirmar PIN',
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
                : const Text(
                    'Crear Bóveda Cifrada',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
        const Text(
          '¡Guarda tu Código de Recuperación!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          'Si olvidas tu PIN, esta clave es el ÚNICO medio para recuperar tu bóveda. Anótala o guárdala en un lugar seguro fuera de tu teléfono.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
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
                    const SnackBar(content: Text('Código de recuperación copiado al portapapeles.')),
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
          child: const Text(
            'Entrar a SegurCel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
