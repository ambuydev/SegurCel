import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/vault_service.dart';
import '../utils/file_helper.dart';
import 'paywall_screen.dart';
import 'pin_screen.dart';
import 'setup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VaultService vaultService;

  const LoginScreen({super.key, required this.vaultService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _loc = LocalizationService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = _loc.text('login_subtitle'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await _authService.loginWithEmail(email, password);
      } else {
        await _authService.registerWithEmail(email, password);
      }

      final profile = await widget.vaultService.fetchUserProfile();

      if (mounted) {
        final isPremium = profile?.isPremium ?? false;

        // Si se ingresa desde navegador Web (kIsWeb) y el usuario es GRATUITO:
        if (kIsWeb && !isPremium) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E2538),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loc.text('web_access_premium_title'),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                _loc.text('web_access_premium_desc'),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              actions: [
                TextButton(
                  child: Text(_loc.text('cancel'), style: const TextStyle(color: Colors.white54)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _authService.signOut();
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.star, color: Colors.amberAccent, size: 18),
                  label: Text(
                    _loc.text('view_pro_plans'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaywallScreen(
                          vaultService: widget.vaultService,
                          userProfile: profile,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
          return;
        }

        if (profile != null && profile.isInGracePeriod) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PaywallScreen(
                vaultService: widget.vaultService,
                userProfile: profile,
                isEmergency: true,
              ),
            ),
          );
          return;
        }

        final vaultExists = await widget.vaultService.checkVaultExists();
        if (mounted) {
          if (widget.vaultService.lastSyncError != null) {
            setState(() {
              _errorMessage = widget.vaultService.lastSyncError;
              _isLoading = false;
            });
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => vaultExists
                  ? PinScreen(vaultService: widget.vaultService)
                  : SetupScreen(vaultService: widget.vaultService),
            ),
          );
        }
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

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = _loc.text('email_label'));
      return;
    }

    try {
      await _authService.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_loc.text('forgot_account_pass')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Widget _buildLanguagePicker() {
    final languages = [
      {'code': 'es', 'name': '🇪🇸 Español'},
      {'code': 'en', 'name': '🇺🇸 English'},
      {'code': 'pt', 'name': '🇧🇷 Português'},
      {'code': 'zh', 'name': '🇨🇳 中文'},
      {'code': 'fr', 'name': '🇫🇷 Français'},
      {'code': 'hi', 'name': '🇮🇳 हिन्दी'},
      {'code': 'de', 'name': '🇩🇪 Deutsch'},
      {'code': 'ja', 'name': '🇯🇵 日本語'},
      {'code': 'ko', 'name': '🇰🇷 한국어'},
      {'code': 'ru', 'name': '🇷🇺 Русский'},
    ];

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.amberAccent, size: 26),
      tooltip: _loc.text('language'),
      color: const Color(0xFF1E2538),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String code) async {
        await _loc.changeLanguage(code);
        if (mounted) {
          setState(() {});
        }
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
    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: kIsWeb
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.amberAccent),
                tooltip: _loc.text('back_to_official_site'),
                onPressed: () {
                  FileHelper.openUrl('https://segurcel.app/?lang=${_loc.currentLanguage}');
                },
              )
            : null,
        title: kIsWeb
            ? TextButton.icon(
                icon: const Icon(Icons.home, color: Colors.amberAccent, size: 18),
                label: Text(
                  _loc.text('back_to_official_site'),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  FileHelper.openUrl('https://segurcel.app/?lang=${_loc.currentLanguage}');
                },
              )
            : null,
        actions: [
          _buildLanguagePicker(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Image.asset(
                  'assets/icon/pantalla_pin.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud_sync_outlined, size: 80, color: Color(0xFF6C63FF)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _loc.text('login_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _isLoginMode
                    ? _loc.text('login_subtitle')
                    : _loc.text('register_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: _loc.text('email_label'),
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6C63FF)),
                  filled: true,
                  fillColor: const Color(0xFF1E2538),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: _loc.text('account_pass_label'),
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6C63FF)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isLoginMode ? _loc.text('login_button') : _loc.text('register_button'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),

              const SizedBox(height: 12),

              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLoginMode ? _loc.text('no_account_register') : _loc.text('has_account_login'),
                      style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 13),
                    ),
                  ),
                  if (_isLoginMode)
                    TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        _loc.text('forgot_account_pass'),
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
