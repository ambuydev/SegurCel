import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/vault_service.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VaultService vaultService;

  const SettingsScreen({super.key, required this.vaultService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();

  // Formulario Cambio de PIN
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isChangingPin = false;
  String? _pinErrorMessage;

  // Formulario Cambio de Contraseña de Cuenta
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  String? _passwordErrorMessage;

  Future<void> _changePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      setState(() => _pinErrorMessage = 'Por favor completa todos los campos del PIN.');
      return;
    }

    if (newPin.length != 4) {
      setState(() => _pinErrorMessage = 'El nuevo PIN debe tener exactamente 4 dígitos.');
      return;
    }

    if (newPin != confirmPin) {
      setState(() => _pinErrorMessage = 'Los nuevos PINs no coinciden.');
      return;
    }

    setState(() {
      _isChangingPin = true;
      _pinErrorMessage = null;
    });

    try {
      await widget.vaultService.changePin(currentPin, newPin);
      if (mounted) {
        _currentPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡El PIN de tu bóveda ha sido actualizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pinErrorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isChangingPin = false);
    }
  }

  Future<void> _changeAccountPassword() async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _passwordErrorMessage = 'Completa todos los campos de contraseña de cuenta.');
      return;
    }

    if (newPass.length < 6) {
      setState(() => _passwordErrorMessage = 'La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _passwordErrorMessage = 'Las nuevas contraseñas no coinciden.');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordErrorMessage = null;
    });

    try {
      await _authService.changeAccountPassword(currentPass, newPass);
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Contraseña de cuenta actualizada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _passwordErrorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2538),
        title: const Text('Ajustes y Seguridad', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección 1: Cambiar PIN de la Bóveda
              _buildSectionCard(
                title: 'Seguridad de la Bóveda',
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF6C63FF),
                child: Column(
                  children: [
                    const Text(
                      'Cambia el PIN con el que descifras tus contraseñas en esta app.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currentPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, letterSpacing: 6),
                      decoration: const InputDecoration(
                        labelText: 'PIN Actual',
                        labelStyle: TextStyle(color: Colors.white70, letterSpacing: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, letterSpacing: 6),
                      decoration: const InputDecoration(
                        labelText: 'Nuevo PIN (4 dígitos)',
                        labelStyle: TextStyle(color: Colors.white70, letterSpacing: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, letterSpacing: 6),
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Nuevo PIN',
                        labelStyle: TextStyle(color: Colors.white70, letterSpacing: 0),
                      ),
                    ),
                    if (_pinErrorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _pinErrorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isChangingPin ? null : _changePin,
                        child: _isChangingPin
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Actualizar PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sección 2: Cambiar Contraseña de la Cuenta Cloud
              if (currentUser != null)
                _buildSectionCard(
                  title: 'Cuenta Cloud',
                  icon: Icons.cloud_done_outlined,
                  iconColor: Colors.greenAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuario conectado: ${currentUser.email}',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Contraseña Actual de Cuenta',
                          labelStyle: const TextStyle(color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña de Cuenta',
                          labelStyle: const TextStyle(color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureNewPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                      ),
                      if (_passwordErrorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _passwordErrorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2538),
                            side: const BorderSide(color: Color(0xFF6C63FF)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isChangingPassword ? null : _changeAccountPassword,
                          child: _isChangingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Actualizar Contraseña de Cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Sección 3: Suscripción PRO
              _buildSectionCard(
                title: 'Suscripción SegurCel PRO',
                icon: Icons.stars_outlined,
                iconColor: const Color(0xFF6C63FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Desbloquea sincronización permanente, respaldo de emergencia e historial completo.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaywallScreen(vaultService: widget.vaultService),
                            ),
                          );
                        },
                        child: const Text('Ver Planes PRO / Suscribirse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      color: const Color(0xFF1E2538),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
