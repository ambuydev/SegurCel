import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/import_export_service.dart';
import '../services/localization_service.dart';
import '../services/purchase_service.dart';
import '../services/vault_service.dart';
import '../utils/file_helper.dart';
import '../utils/promo_code_helper.dart';
import 'login_screen.dart';
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
  bool _obscureConfirmPass = true;
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

  Future<void> _showDeleteAccountDialog(bool isPremium) async {
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2538),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Eliminar Cuenta Permanentemente',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Esta acción destruirá tu cuenta, tu bóveda cifrada en la Nube y todos los datos guardados en este dispositivo de forma permanente. Esta acción NO se puede deshacer.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    if (isPremium) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amberAccent),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amberAccent, size: 18),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'AVISO DE SUSCRIPCIÓN PREMIUM:',
                                    style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Si compraste tu suscripción en Google Play Store, recuerda cancelar la renovación automática desde la tienda para evitar cobros futuros.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.amberAccent),
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              ),
                              icon: const Icon(Icons.open_in_new, color: Colors.amberAccent, size: 14),
                              label: const Text(
                                '1. Abrir Suscripciones en Google Play',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                FileHelper.openUrl('https://play.google.com/store/account/subscriptions');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text(
                      'Ingresa tu Contraseña de SegurCel para confirmar:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Contraseña de tu cuenta',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF10141D),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final pass = passwordController.text.trim();
                          if (pass.isEmpty) {
                            setDialogState(() => errorMessage = 'Por favor ingresa tu contraseña.');
                            return;
                          }

                          setDialogState(() => isDeleting = true);

                          try {
                            final rootContext = context;
                            await widget.vaultService.deleteAccountAndVault(pass);

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                const SnackBar(
                                  content: Text('🗑️ Tu cuenta y tus datos fueron eliminados permanentemente.'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              Navigator.of(rootContext).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(vaultService: widget.vaultService),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              errorMessage = e.toString().replaceAll('Exception: ', '');
                              isDeleting = false;
                            });
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('2. Confirmar y Eliminar Cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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

  Future<void> _generateFamilyCode(String ownerUid, String ownerEmail) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('promo_codes')
          .where('ownerUid', isEqualTo: ownerUid)
          .where('isFamilyCode', isEqualTo: true)
          .get();

      final existingCount = query.docs.length;
      if (existingCount >= 4) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Límite alcanzado: Ya has generado tus 4 Códigos Familiares Módulo 10.'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final newCode = PromoCodeHelper.generateRandomCode();

      await FirebaseFirestore.instance.collection('promo_codes').doc(newCode).set({
        'code': newCode,
        'used': false,
        'isFamilyCode': true,
        'ownerUid': ownerUid,
        'ownerEmail': ownerEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E2538),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.family_restroom, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('Código Familiar Módulo 10', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Envía este código Módulo 10 a tu familiar (Generado ${existingCount + 1} de 4):', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                SelectableText(
                  newCode,
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Copiar Código y Cerrar', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: newCode));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Código copiado: $newCode'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar código familiar: $e'), backgroundColor: Colors.red),
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
              // Sección Estado de Suscripción (Gratuito vs Premium)
              FutureBuilder<UserProfile?>(
                future: widget.vaultService.fetchUserProfile(),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final isPremium = profile?.isPremium ?? false;

                  return _buildSectionCard(
                    title: 'Estado de la Suscripción',
                    icon: isPremium ? Icons.stars : Icons.stars_outlined,
                    iconColor: isPremium ? Colors.amberAccent : Colors.cyanAccent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPremium ? Icons.verified : Icons.info_outline,
                              color: isPremium ? Colors.amberAccent : Colors.white70,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPremium ? '👑 SegurCel Premium Activo' : '🟢 Plan Gratuito (SegurCel Free)',
                                    style: TextStyle(
                                      color: isPremium ? Colors.amberAccent : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    isPremium ? 'Acceso ilimitado a todas las funciones' : 'Límite de 15 contraseñas y 2 cuentas TOTP',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isPremium) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.star, color: Colors.amberAccent, size: 20),
                                  label: const Text(
                                    '🚀 Mejorar a SegurCel Premium',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PaywallScreen(vaultService: widget.vaultService, userProfile: profile),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.cyanAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('🔄 Restaurar', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                onPressed: () async {
                                  await PurchaseService.restorePurchases();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🔄 Compras In-App sincronizadas con Google Play.'),
                                        backgroundColor: Colors.cyan,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10141D),
                              side: const BorderSide(color: Colors.amberAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.family_restroom, color: Colors.amberAccent, size: 20),
                            label: const Text(
                              '👨‍👩‍👧‍👦 Generar Código Familiar Módulo 10',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () {
                              final user = _authService.currentUser;
                              if (user != null) {
                                _generateFamilyCode(user.uid, user.email ?? '');
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Panel Generador de Códigos Módulo 10 para Administrador
              if (currentUser?.email == 'alejandro.martinez.briao@gmail.com') ...[
                _buildSectionCard(
                  title: 'Panel Administrador SegurCel',
                  icon: Icons.admin_panel_settings,
                  iconColor: Colors.amberAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Genera un nuevo Código de Regalo Módulo 10 exclusivo de único uso para tus familiares o clientes VIP.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10141D),
                          side: const BorderSide(color: Colors.amberAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.flash_on, color: Colors.amberAccent, size: 20),
                        label: const Text(
                          '⚡ Generar Código de Regalo Módulo 10',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () async {
                          final newCode = PromoCodeHelper.generateRandomCode();
                          try {
                            await FirebaseFirestore.instance.collection('promo_codes').doc(newCode).set({
                              'code': newCode,
                              'used': false,
                              'createdBy': currentUser?.email,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E2538),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.card_giftcard, color: Colors.amberAccent),
                                      SizedBox(width: 8),
                                      Text('Código Módulo 10 Creado', style: TextStyle(color: Colors.white, fontSize: 16)),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Copia este código de único uso y envíaselo a tu familiar:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      const SizedBox(height: 12),
                                      SelectableText(
                                        newCode,
                                        style: const TextStyle(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Copiar y Cerrar', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: newCode));
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Código copiado: $newCode'), backgroundColor: Colors.green),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creando código: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loc.text('change_pin_subtitle'),
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
                      const SizedBox(height: 4),
                      Text(
                        _loc.text('change_pass_subtitle'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                        obscureText: _obscureConfirmPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: _loc.text('confirm_new_pass'),
                          labelStyle: const TextStyle(color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                          ),
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
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _loc.text('update_account_pass'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Sección 3: Soporte y Contacto Oficial
              _buildSectionCard(
                title: _loc.text('support_contact'),
                icon: Icons.contact_support_outlined,
                iconColor: Colors.amberAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language, color: Colors.cyanAccent, size: 20),
                      title: Text(_loc.text('official_website'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('https://segurcel.app', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 18),
                      onTap: () {
                        try {
                          FileHelper.openUrl('https://segurcel.app');
                        } catch (_) {
                          Clipboard.setData(const ClipboardData(text: 'https://segurcel.app'));
                        }
                      },
                    ),
                    const Divider(color: Colors.white12, height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined, color: Colors.amberAccent, size: 20),
                      title: Text(_loc.text('support_email'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('support.segurcel@gmail.com', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                      trailing: const Icon(Icons.copy, color: Colors.white54, size: 18),
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: 'support.segurcel@gmail.com'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_loc.text("support_email")} ${_loc.text("copied_toast")}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white12, height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6C63FF), size: 20),
                      title: Text(_loc.text('privacy_policy'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('https://segurcel.app/privacy.html', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 18),
                      onTap: () {
                        try {
                          FileHelper.openUrl('https://segurcel.app/privacy.html');
                        } catch (_) {
                          Clipboard.setData(const ClipboardData(text: 'https://segurcel.app/privacy.html'));
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sección 4: Suscripción PRO
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

              const SizedBox(height: 20),

              // Zona de Peligro: Eliminar Cuenta (Requisito Google Play Store)
              if (currentUser != null)
                FutureBuilder<UserProfile?>(
                  future: widget.vaultService.fetchUserProfile(),
                  builder: (context, snapshot) {
                    final isPremium = snapshot.data?.isPremium ?? false;

                    return _buildSectionCard(
                      title: 'Zona de Peligro',
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.redAccent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Puedes eliminar tu cuenta de SegurCel y borrar de forma permanente todas tus contraseñas y datos guardados.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10141D),
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                            label: const Text(
                              '🗑️ Eliminar Cuenta y Borrar Todos los Datos',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => _showDeleteAccountDialog(isPremium),
                          ),
                        ],
                      ),
                    );
                  },
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
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
