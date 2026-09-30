import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/auth_service.dart';
import '../services/import_export_service.dart';
import '../services/localization_service.dart';
import '../services/vault_service.dart';
import '../utils/file_helper.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VaultService vaultService;

  const SettingsScreen({super.key, required this.vaultService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _loc = LocalizationService();

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

  Future<void> _importPasswords() async {
    try {
      final importedEntries = await ImportExportService.importFromFile();
      if (importedEntries.isEmpty) return;

      if (mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E2538),
            title: Text(_loc.text('import_preview_title'), style: const TextStyle(color: Colors.white)),
            content: Text('${_loc.text("import_found_count")} ${importedEntries.length}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(_loc.text('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(_loc.text('confirm_import'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final currentList = List<PasswordEntry>.from(widget.vaultService.entries)
            ..addAll(importedEntries);
          await widget.vaultService.saveEntries(currentList);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_loc.text("import_success_toast")} (${importedEntries.length})'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPasswords(String format) async {
    try {
      final entries = widget.vaultService.entries;
      if (entries.isEmpty) return;

      final String content;
      final String fileName;

      if (format == 'csv') {
        content = ImportExportService.exportToCsv(entries);
        fileName = 'segurcel_passwords.csv';
      } else {
        content = ImportExportService.exportToJson(entries);
        fileName = 'segurcel_passwords.json';
      }

      await FileHelper.saveFile(content, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_loc.text("copied_toast")}: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2538),
        title: Text(_loc.text('settings_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección Importar / Exportar Contraseñas
              _buildSectionCard(
                title: _loc.text('import_export'),
                icon: Icons.import_export,
                iconColor: Colors.lightBlueAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _loc.text('import_subtitle'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2538),
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF6C63FF)),
                      label: Text(_loc.text('import_passwords'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: _importPasswords,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loc.text('export_subtitle'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2538),
                              side: const BorderSide(color: Colors.amberAccent),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.file_download_outlined, color: Colors.amberAccent, size: 18),
                            label: Text(_loc.text('export_csv_btn'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            onPressed: () => _exportPasswords('csv'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2538),
                              side: const BorderSide(color: Colors.greenAccent),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.code, color: Colors.greenAccent, size: 18),
                            label: Text(_loc.text('export_json_btn'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            onPressed: () => _exportPasswords('json'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sección 1: Cambiar PIN de la Bóveda
              _buildSectionCard(
                title: _loc.text('vault_security'),
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF6C63FF),
                child: Column(
                  children: [
                    Text(
                      _loc.text('setup_subtitle'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currentPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, letterSpacing: 6),
                      decoration: InputDecoration(
                        labelText: _loc.text('current_pin'),
                        labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, letterSpacing: 6),
                      decoration: InputDecoration(
                        labelText: _loc.text('new_pin'),
                        labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, letterSpacing: 6),
                      decoration: InputDecoration(
                        labelText: _loc.text('confirm_new_pin'),
                        labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
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
                            : Text(_loc.text('update_pin'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sección 2: Cambiar Contraseña de la Cuenta Cloud
              if (currentUser != null)
                _buildSectionCard(
                  title: _loc.text('cloud_account'),
                  icon: Icons.cloud_done_outlined,
                  iconColor: Colors.greenAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentUser.email}',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: _loc.text('current_pass'),
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
                          labelText: _loc.text('new_pass'),
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
                        decoration: InputDecoration(
                          labelText: _loc.text('confirm_new_pass'),
                          labelStyle: const TextStyle(color: Colors.white70),
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
                              : Text(_loc.text('update_account_pass'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Sección 3: Suscripción PRO
              _buildSectionCard(
                title: _loc.text('pro_subscription'),
                icon: Icons.stars_outlined,
                iconColor: const Color(0xFF6C63FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        child: Text(_loc.text('view_pro_plans'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
