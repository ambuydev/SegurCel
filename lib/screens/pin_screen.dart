import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/vault_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'recovery_screen.dart';

class PinScreen extends StatefulWidget {
  final VaultService vaultService;

  const PinScreen({super.key, required this.vaultService});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _loc = LocalizationService();
  String _pin = '';
  bool _isLoading = false;
  bool _isAuthenticatingBiometrics = false;
  String? _errorMessage;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await widget.vaultService.isBiometricsAvailable();
    if (mounted) {
      setState(() => _canUseBiometrics = available);
    }
  }

  Future<void> _tryBiometricUnlock() async {
    if (_isAuthenticatingBiometrics) return;

    setState(() {
      _isAuthenticatingBiometrics = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.vaultService.unlockWithBiometrics();
      if (success && mounted) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticatingBiometrics = false);
      }
    }
  }

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _onSubmitPin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _onSubmitPin() async {
    if (_pin.length != 4) return;
    setState(() => _isLoading = true);

    try {
      final success = await widget.vaultService.unlockWithPin(_pin);
      if (success && mounted) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _pin = '';
          _isLoading = false;
        });

        if (!widget.vaultService.isInitialized) {
          await AuthService().signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_loc.text('vault_destroyed_logout')),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => LoginScreen(vaultService: widget.vaultService),
              ),
              (route) => false,
            );
          }
        }
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(vaultService: widget.vaultService),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    final languages = [
      {'code': 'es', 'name': '🇪🇸 Español'},
      {'code': 'en', 'name': '🇺🇸 English'},
      {'code': 'pt', 'name': '🇧🇷 Português'},
      {'code': 'zh', 'name': '🇨🇳 中文'},
      {'code': 'fr', 'name': '🇫🇷 Français'},
      {'code': 'hi', 'name': '🇮🇳 हिन्दी'},
    ];

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.amberAccent, size: 26),
      tooltip: _loc.text('language'),
      color: const Color(0xFF1E2538),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String code) {
        _loc.changeLanguage(code);
        setState(() {});
      },
      itemBuilder: (BuildContext context) {
        return languages.map((lang) {
          final isSelected = _loc.currentLanguage == lang['code'];
          return PopupMenuItem<String>(
            value: lang['code']!,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang['name']!,
                  style: TextStyle(
                    color: isSelected ? Colors.amberAccent : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.amberAccent, size: 18),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.vaultService.remainingAttempts;

    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                child: _buildLanguagePicker(),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const Icon(Icons.security, size: 54, color: Color(0xFF6C63FF)),
                          const SizedBox(height: 10),
                          Text(
                            _loc.text('app_title'),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _loc.text('enter_pin'),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 24),

                          // Indicador de Puntos (Exactamente 4 Puntos)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled = index < _pin.length;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled ? const Color(0xFF6C63FF) : Colors.white24,
                                  border: Border.all(
                                    color: isFilled ? const Color(0xFF6C63FF) : Colors.white38,
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 16),

                          // Mensaje de Error / Intentos restantes
                          if (_errorMessage != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          if (widget.vaultService.failedAttempts > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(38),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withAlpha(76)),
                              ),
                              child: Text(
                                '${_loc.text("attempts_remaining")}: $remaining / ${VaultService.maxAttempts}',
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),

                          const Spacer(),

                          // Teclado Numérico
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                            )
                          else
                            _buildNumericKeypad(),

                          const SizedBox(height: 12),

                          // Botón "Olvidé mi PIN"
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecoveryScreen(vaultService: widget.vaultService),
                                ),
                              );
                            },
                            child: Text(
                              _loc.text('forgot_pin'),
                              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [_canUseBiometrics ? 'bio' : '', '0', 'del'],
    ];

    const double btnSize = 56;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      alignment: Alignment.center,
      child: Column(
        children: buttons.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((btn) {
                if (btn == '') {
                  return const SizedBox(width: btnSize, height: btnSize);
                }
                if (btn == 'del') {
                  return SizedBox(
                    width: btnSize,
                    height: btnSize,
                    child: IconButton(
                      icon: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 22),
                      onPressed: _onDelete,
                    ),
                  );
                }
                if (btn == 'bio') {
                  return SizedBox(
                    width: btnSize,
                    height: btnSize,
                    child: IconButton(
                      icon: _isAuthenticatingBiometrics
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)),
                            )
                          : const Icon(Icons.fingerprint, color: Color(0xFF6C63FF), size: 32),
                      onPressed: _tryBiometricUnlock,
                    ),
                  );
                }
                return SizedBox(
                  width: btnSize,
                  height: btnSize,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: const Color(0xFF1E2538),
                      elevation: 2,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _onKeyPress(btn),
                    child: Text(
                      btn,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
