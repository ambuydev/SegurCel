import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/import_export_service.dart';
import '../services/localization_service.dart';
import '../services/purchase_service.dart';
import '../services/theme_service.dart';
import '../services/vault_service.dart';
import '../utils/file_helper.dart';
import '../utils/promo_code_helper.dart';
import '../utils/secure_storage_helper.dart';
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
  final _themeService = ThemeService();

  int _autoLockMinutes = 0; // 0 = Nunca, 1 = 1m, 5 = 5m, 15 = 15m

  @override
  void initState() {
    super.initState();
    _loadAutoLockMinutes();
  }

  Future<void> _loadAutoLockMinutes() async {
    final val = await SecureStorageHelper.safeRead('segurcel_autolock_minutes');
    if (val != null && mounted) {
      setState(() => _autoLockMinutes = int.tryParse(val) ?? 0);
    }
  }

  Future<void> _setAutoLockMinutes(int mins) async {
    await SecureStorageHelper.safeWrite('segurcel_autolock_minutes', mins.toString());
    if (mounted) {
      setState(() => _autoLockMinutes = mins);
    }
  }

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
          SnackBar(
            content: Text(_loc.text('pin_updated_toast')),
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
          SnackBar(
            content: Text(_loc.text('pass_updated_toast')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final inputFillColor = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);
    final accentAmber = isDark ? Colors.amberAccent : const Color(0xFFD97706);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loc.text('delete_account_perm_title'),
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _loc.text('delete_account_perm_desc'),
                      style: TextStyle(color: textSubColor, fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    if (isPremium) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.amber.withAlpha(30) : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentAmber),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: accentAmber, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _loc.text('premium_sub_notice_title'),
                                    style: TextStyle(color: accentAmber, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _loc.text('premium_sub_notice_desc'),
                              style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF5D4037), fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accentAmber),
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              ),
                              icon: Icon(Icons.open_in_new, color: accentAmber, size: 14),
                              label: Text(
                                _loc.text('open_google_subscriptions'),
                                style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
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

                    Text(
                      _loc.text('enter_pass_confirm_label'),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: _loc.text('pass_account_hint'),
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                        filled: true,
                        fillColor: inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                  child: Text(_loc.text('cancel'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final pass = passwordController.text.trim();
                          if (pass.isEmpty) {
                            setDialogState(() => errorMessage = _loc.text('enter_pass_prompt'));
                            return;
                          }

                          setDialogState(() => isDeleting = true);

                          try {
                            final rootContext = context;
                            await widget.vaultService.deleteAccountAndVault(pass);

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(
                                  content: Text(_loc.text('account_deleted_toast')),
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
      widget.vaultService.isPickingFile = true;
      final rawContent = await ImportExportService.pickRawFileContent();
      if (rawContent == null || rawContent.trim().isEmpty) return;

      List<PasswordEntry> importedEntries = [];

      if (ImportExportService.isEncryptedBackup(rawContent)) {
        final decryptedEntries = await _promptBackupPasswordForImport(rawContent);
        if (decryptedEntries == null) return;
        importedEntries = decryptedEntries;
      } else {
        importedEntries = ImportExportService.parsePlainContent(rawContent);
      }

      if (importedEntries.isEmpty) return;

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1E2538) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF10141D);

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: dialogBg,
            title: Text(_loc.text('import_preview_title'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            content: Text('${_loc.text("import_found_count")} ${importedEntries.length}', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4A5568))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(_loc.text('cancel'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(_loc.text('confirm_import'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final mergedList = VaultService.mergeAndDeduplicate(widget.vaultService.entries, importedEntries);
          await widget.vaultService.saveEntries(mergedList);

          if (mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: dialogBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Restauración Exitosa',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  '✅ ¡Bóveda restaurada con éxito!\n\nSe importaron ${importedEntries.length} registros y contraseñas a tu bóveda.',
                  style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4A5568), fontSize: 13, height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
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
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      widget.vaultService.isPickingFile = false;
    }
  }

  Future<List<PasswordEntry>?> _promptBackupPasswordForImport(String rawContent) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final inputFillColor = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);

    final passController = TextEditingController();
    String? errorMessage;
    bool isProcessing = false;

    return await showDialog<List<PasswordEntry>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loc.text('restore_pass_dialog_title'),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loc.text('restore_pass_dialog_desc'),
                      style: TextStyle(color: textSubColor, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _loc.text('backup_pass_label'),
                        labelStyle: TextStyle(color: textSubColor, fontSize: 12),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                  onPressed: isProcessing ? null : () => Navigator.pop(ctx, null),
                  child: Text(_loc.text('cancel'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final pass = passController.text.trim();
                          if (pass.isEmpty) {
                            setDialogState(() => errorMessage = _loc.text('backup_pass_label'));
                            return;
                          }

                          setDialogState(() {
                            isProcessing = true;
                            errorMessage = null;
                          });

                          try {
                            final entries = await ImportExportService.importFromEncryptedBackup(rawContent, pass);
                            if (context.mounted) {
                              Navigator.pop(ctx, entries);
                            }
                          } catch (_) {
                            setDialogState(() {
                              isProcessing = false;
                              errorMessage = _loc.text('invalid_backup_pass');
                            });
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Descifrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportPasswords(String format) async {
    try {
      widget.vaultService.isPickingFile = true;
      final entries = widget.vaultService.entries;
      if (entries.isEmpty) return;

      final String content;
      final String fileName;

      if (format == 'segurcel') {
        final backupPass = await _promptBackupPasswordForExport();
        if (backupPass == null || backupPass.trim().isEmpty) return;

        content = await ImportExportService.exportToEncryptedBackup(entries, backupPass);
        final dateStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
        fileName = 'segurcel_backup_$dateStr.segurcel';
      } else if (format == 'csv') {
        content = ImportExportService.exportToCsv(entries);
        fileName = 'segurcel_passwords.csv';
      } else {
        content = ImportExportService.exportToJson(entries);
        fileName = 'segurcel_passwords.json';
      }

      await FileHelper.saveFile(content, fileName);

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1E2538) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF10141D);

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Respaldo Creado',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              '✅ ¡Respaldo generado con éxito!\n\nEl archivo "$fileName" fue guardado en la carpeta de descargas / documentos de tu dispositivo.',
              style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4A5568), fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      widget.vaultService.isPickingFile = false;
    }
  }

  Future<String?> _promptBackupPasswordForExport() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final inputFillColor = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);

    final passController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;

    return await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loc.text('backup_pass_dialog_title'),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loc.text('backup_pass_dialog_desc'),
                      style: TextStyle(color: textSubColor, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _loc.text('backup_pass_label'),
                        labelStyle: TextStyle(color: textSubColor, fontSize: 12),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _loc.text('confirm_backup_pass_label'),
                        labelStyle: TextStyle(color: textSubColor, fontSize: 12),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text(_loc.text('cancel'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                  onPressed: () {
                    final pass = passController.text.trim();
                    final confirm = confirmController.text.trim();

                    if (pass.isEmpty) {
                      setDialogState(() => errorMessage = _loc.text('backup_pass_label'));
                      return;
                    }
                    if (pass != confirm) {
                      setDialogState(() => errorMessage = _loc.text('passwords_dont_match'));
                      return;
                    }

                    Navigator.pop(ctx, pass);
                  },
                  child: const Text('Crear Respaldo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showFamilyCodesListDialog(String ownerUid, String ownerEmail) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final cardBg = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final accentAmber = isDark ? Colors.amberAccent : const Color(0xFFD97706);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('promo_codes')
              .where('ownerUid', isEqualTo: ownerUid)
              .snapshots(),
          builder: (context, snapshot) {
            final allDocs = snapshot.data?.docs ?? [];
            final docs = allDocs.where((d) {
              final data = d.data();
              final isFamily = data['isFamilyCode'] == true;
              final isDisabled = data['disabled'] == true;
              return isFamily && !isDisabled;
            }).toList();
            final count = docs.length;

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.family_restroom, color: accentAmber, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_loc.text("family_codes_count")} ($count / 4)',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _loc.text('my_family_codes'),
                      style: TextStyle(color: textSubColor, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Center(child: CircularProgressIndicator(color: accentAmber))
                    else if (docs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _loc.text('family_code_available'),
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: docs.map((d) {
                              final data = d.data();
                              final code = data['code'] as String? ?? d.id;
                              final used = data['used'] as bool? ?? false;
                              final usedByEmail = data['usedByEmail'] as String? ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: used ? (isDark ? Colors.white12 : Colors.black12) : accentAmber,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SelectableText(
                                            code,
                                            style: TextStyle(
                                              color: used ? (isDark ? Colors.white38 : const Color(0xFF4A5568)) : accentAmber,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            used ? '${_loc.text("family_code_used")} $usedByEmail' : _loc.text('family_code_available'),
                                            style: TextStyle(
                                              color: used ? (isDark ? Colors.white54 : const Color(0xFF718096)) : (isDark ? Colors.greenAccent : const Color(0xFF137333)),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.copy, color: isDark ? Colors.cyanAccent : const Color(0xFF00796B), size: 18),
                                      tooltip: _loc.text('copy'),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${_loc.text("copy")}: $code'),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: count >= 4 ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0)) : accentAmber,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(
                        count >= 4 ? Icons.lock : Icons.add,
                        color: count >= 4 ? (isDark ? Colors.white54 : const Color(0xFF4A5568)) : Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        count >= 4 ? _loc.text('family_code_limit_reached') : '${_loc.text("generate_family_code")} ($count/4)',
                        style: TextStyle(
                          color: count >= 4 ? (isDark ? Colors.white54 : const Color(0xFF2D3748)) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: count >= 4
                          ? null
                          : () async {
                              final newCode = PromoCodeHelper.generateRandomCode();
                              await FirebaseFirestore.instance.collection('promo_codes').doc(newCode).set({
                                'code': newCode,
                                'used': false,
                                'isFamilyCode': true,
                                'ownerUid': ownerUid,
                                'ownerEmail': ownerEmail,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${_loc.text("generate_family_code")}: $newCode'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(_loc.text('cancel'), style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF10141D))),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);
    final appBarBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        title: Text(_loc.text('settings_title'), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
                  final subType = profile?.subscriptionType ?? '';
                  final isFamilyOwner = isPremium &&
                      ((subType.contains('family') && subType != 'family_member') ||
                          currentUser?.email == 'alejandro.martinez.briao@gmail.com');

                  return _buildSectionCard(
                    title: _loc.text('subscription_status'),
                    icon: isPremium ? Icons.stars : Icons.stars_outlined,
                    iconColor: isPremium ? Colors.amberAccent : Colors.cyanAccent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPremium ? Icons.verified : Icons.info_outline,
                              color: isPremium ? (isDark ? Colors.amberAccent : const Color(0xFFD97706)) : textSubColor,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPremium ? _loc.text('premium_active') : _loc.text('free_plan'),
                                    style: TextStyle(
                                      color: isPremium ? (isDark ? Colors.amberAccent : const Color(0xFFD97706)) : textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    isPremium ? _loc.text('unlimited_access') : _loc.text('free_limits'),
                                    style: TextStyle(color: textSubColor, fontSize: 12),
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
                                  label: Text(
                                    _loc.text('upgrade_pro'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                                  side: BorderSide(color: isDark ? Colors.cyanAccent : const Color(0xFF00796B)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  _loc.text('restore_purchases'),
                                  style: TextStyle(color: isDark ? Colors.cyanAccent : const Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
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
                        ],
                        if (isFamilyOwner) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8),
                              side: BorderSide(color: isDark ? Colors.amberAccent : const Color(0xFFD97706)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(Icons.family_restroom, color: isDark ? Colors.amberAccent : const Color(0xFFD97706), size: 20),
                            label: Text(
                              _loc.text('my_family_codes'),
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () {
                              final user = _authService.currentUser;
                              if (user != null) {
                                _showFamilyCodesListDialog(user.uid, user.email ?? '');
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
                  title: _loc.text('admin_panel_title'),
                  icon: Icons.admin_panel_settings,
                  iconColor: isDark ? Colors.amberAccent : const Color(0xFFD97706),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _loc.text('admin_panel_desc'),
                        style: TextStyle(color: textSubColor, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8),
                          side: BorderSide(color: isDark ? Colors.amberAccent : const Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(Icons.flash_on, color: isDark ? Colors.amberAccent : const Color(0xFFD97706), size: 20),
                        label: Text(
                          _loc.text('generate_gift_code'),
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
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
                                  backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      Icon(Icons.card_giftcard, color: isDark ? Colors.amberAccent : const Color(0xFFD97706)),
                                      const SizedBox(width: 8),
                                      Text('Código Módulo 10 Creado', style: TextStyle(color: textColor, fontSize: 16)),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Copia este código de único uso y envíaselo a tu familiar:', style: TextStyle(color: textSubColor, fontSize: 13)),
                                      const SizedBox(height: 12),
                                      SelectableText(
                                        newCode,
                                        style: TextStyle(color: isDark ? Colors.amberAccent : const Color(0xFFD97706), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('Copiar y Cerrar', style: TextStyle(color: isDark ? Colors.cyanAccent : const Color(0xFF00796B), fontWeight: FontWeight.bold)),
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
                      style: TextStyle(color: textSubColor, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF6C63FF)),
                      label: Text(_loc.text('import_passwords'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: _importPasswords,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loc.text('export_subtitle'),
                      style: TextStyle(color: textSubColor, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E2538) : const Color(0xFFEEF2FF),
                          side: BorderSide(color: isDark ? Colors.amberAccent : const Color(0xFFD97706), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(Icons.shield_outlined, color: isDark ? Colors.amberAccent : const Color(0xFFD97706), size: 20),
                        label: Text(
                          _loc.text('export_segurcel_btn'),
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF10141D),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () => _exportPasswords('segurcel'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
                              side: const BorderSide(color: Colors.amberAccent),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.file_download_outlined, color: Colors.amber, size: 18),
                            label: Text(_loc.text('export_csv_btn'), style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _exportPasswords('csv'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
                              side: const BorderSide(color: Colors.greenAccent),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.code, color: Colors.teal, size: 18),
                            label: Text(_loc.text('export_json_btn'), style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
                      style: TextStyle(color: textSubColor, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currentPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: TextStyle(color: textColor, letterSpacing: 6),
                      decoration: InputDecoration(
                        labelText: _loc.text('current_pin'),
                        labelStyle: TextStyle(color: textSubColor, letterSpacing: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: TextStyle(color: textColor, letterSpacing: 6),
                      decoration: InputDecoration(
                        labelText: _loc.text('new_pin'),
                        labelStyle: TextStyle(color: textSubColor, letterSpacing: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: TextStyle(color: textColor, letterSpacing: 6),
                      decoration: InputDecoration(
                        labelText: _loc.text('confirm_new_pin'),
                        labelStyle: TextStyle(color: textSubColor, letterSpacing: 0),
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
                        style: TextStyle(color: isDark ? Colors.amberAccent : Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loc.text('change_pass_subtitle'),
                        style: TextStyle(color: textSubColor, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPass,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _loc.text('current_pass'),
                          labelStyle: TextStyle(color: textSubColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPass,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _loc.text('new_pass'),
                          labelStyle: TextStyle(color: textSubColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPass,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _loc.text('confirm_new_pass'),
                          labelStyle: TextStyle(color: textSubColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: isDark ? Colors.white54 : Colors.black54,
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
                            backgroundColor: const Color(0xFF6C63FF),
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

              // Sección 3: Preferencias de la Aplicación
              _buildSectionCard(
                title: _loc.text('app_preferences'),
                icon: Icons.tune,
                iconColor: Colors.amberAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tema de la Aplicación
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.palette_outlined, color: Colors.cyan, size: 20),
                      title: Text(_loc.text('app_theme'), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _themeService.themeMode == ThemeMode.light
                            ? _loc.text('theme_light')
                            : _themeService.themeMode == ThemeMode.system
                                ? _loc.text('theme_system')
                                : _loc.text('theme_dark'),
                        style: TextStyle(color: isDark ? Colors.cyanAccent : Colors.cyan.shade800, fontSize: 12),
                      ),
                      trailing: DropdownButton<ThemeMode>(
                        dropdownColor: isDark ? const Color(0xFF1E2538) : Colors.white,
                        value: _themeService.themeMode,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white54 : Colors.black54),
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            _themeService.changeTheme(mode);
                            setState(() {});
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text(_loc.text('theme_dark'), style: TextStyle(color: textColor, fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text(_loc.text('theme_light'), style: TextStyle(color: textColor, fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text(_loc.text('theme_system'), style: TextStyle(color: textColor, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: dividerColor, height: 8),
                    // Auto-bloqueo por Inactividad
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer_outlined, color: Colors.amber, size: 20),
                      title: Text(_loc.text('autolock_timer'), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _autoLockMinutes == 0
                            ? _loc.text('autolock_never')
                            : '$_autoLockMinutes ${_loc.text("autolock_5m").contains("Minut") ? "Min" : "m"}',
                        style: TextStyle(color: isDark ? Colors.amberAccent : Colors.amber.shade900, fontSize: 12),
                      ),
                      trailing: DropdownButton<int>(
                        dropdownColor: isDark ? const Color(0xFF1E2538) : Colors.white,
                        value: _autoLockMinutes,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white54 : Colors.black54),
                        onChanged: (int? mins) {
                          if (mins != null) {
                            _setAutoLockMinutes(mins);
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(_loc.text('autolock_never'), style: TextStyle(color: textColor, fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text(_loc.text('autolock_1m'), style: TextStyle(color: textColor, fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(_loc.text('autolock_5m'), style: TextStyle(color: textColor, fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text(_loc.text('autolock_15m'), style: TextStyle(color: textColor, fontSize: 12)),
                          ),
                        ],
                      ),
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
                      title: _loc.text('danger_zone'),
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.redAccent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _loc.text('delete_account_warning'),
                            style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFFB71C1C), fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF10141D) : const Color(0xFFFFEBEE),
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                            label: Text(
                              _loc.text('delete_account_btn'),
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E2538) : Colors.white,
      elevation: isDark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF6C63FF).withAlpha(100) : Colors.black12,
        ),
      ),
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
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF10141D),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: isDark ? Colors.white12 : Colors.black12, height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
