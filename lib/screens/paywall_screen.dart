import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/vault_service.dart';
import 'pin_screen.dart';

class PaywallScreen extends StatefulWidget {
  final VaultService vaultService;
  final UserProfile? userProfile;
  final bool isEmergency;

  const PaywallScreen({
    super.key,
    required this.vaultService,
    this.userProfile,
    this.isEmergency = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _authService = AuthService();
  Timer? _countdownTimer;
  int _remainingMillis = 0;
  String _selectedPlan = 'yearly'; // 'monthly', 'yearly', 'lifetime', 'emergency_6m'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEmergency) {
      _selectedPlan = 'emergency_6m';
    }
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (widget.userProfile?.gracePeriodExpiresAt != null) {
      _updateRemainingTime();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemainingTime();
      });
    }
  }

  void _updateRemainingTime() {
    final expires = widget.userProfile?.gracePeriodExpiresAt ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = expires - now;

    if (mounted) {
      setState(() {
        _remainingMillis = diff > 0 ? diff : 0;
      });
    }
  }

  String _formatCountdown(int millis) {
    if (millis <= 0) return '00h : 00m : 00s';
    final duration = Duration(milliseconds: millis);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '${hours}h : ${minutes}m : ${seconds}s';
  }

  Future<void> _activateSubscription() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Actualizar perfil de usuario en Firestore a Premium
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'isPremium': true,
        'subscriptionType': _selectedPlan,
        'selfDestructedAt': null,
        'gracePeriodExpiresAt': null,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Suscripción PRO activada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );

        await widget.vaultService.checkVaultExists();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PinScreen(vaultService: widget.vaultService),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar suscripción: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.isEmergency ? 'Rescate de Emergencia' : 'SegurCel PRO'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isEmergency) ...[
                // Banner de Emergencia con Temporizador
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      const Text(
                        '¡Bóveda Local Eliminada!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresaste 3 PINs incorrectos. Tus contraseñas están resguardadas e intactas en la nube, pero tu copia de seguridad expirará cuando venza el reloj:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10141D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amberAccent),
                        ),
                        child: Text(
                          _formatCountdown(_remainingMillis),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Icon(Icons.stars_outlined, size: 80, color: Color(0xFF6C63FF)),
                const SizedBox(height: 16),
                const Text(
                  'Desbloquea SegurCel PRO',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accede a tus contraseñas desde cualquier dispositivo en tiempo real.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Lista de beneficios
                _buildBenefitRow(Icons.cloud_done_outlined, 'Sincronización ilimitada (Android, Windows, Web, iOS)'),
                _buildBenefitRow(Icons.security, 'Respaldo permanente cifrado con AES-256 en la nube'),
                _buildBenefitRow(Icons.history, 'Historial completo de contraseñas anteriores'),
                _buildBenefitRow(Icons.language, 'Acceso rápido desde cualquier navegador Web'),
                const SizedBox(height: 24),
              ],

              const Text(
                'Selecciona tu Plan:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              if (widget.isEmergency)
                _buildPlanTile(
                  id: 'emergency_6m',
                  title: 'Plan Rescate 6 Meses',
                  price: '\$8.99 USD',
                  subtitle: 'Restaura tu bóveda cifrada de inmediato',
                  badge: 'RESCATE',
                  badgeColor: Colors.amber,
                )
              else ...[
                _buildPlanTile(
                  id: 'yearly',
                  title: 'Plan Anual',
                  price: '\$9.99 USD / año',
                  subtitle: '\$0.83 USD / mes (Ahorras 45%)',
                  badge: 'POPULAR',
                  badgeColor: const Color(0xFF6C63FF),
                ),
                const SizedBox(height: 10),
                _buildPlanTile(
                  id: 'monthly',
                  title: 'Plan Mensual',
                  price: '\$1.50 USD / mes',
                  subtitle: 'Cancela cuando quieras',
                ),
                const SizedBox(height: 10),
                _buildPlanTile(
                  id: 'lifetime',
                  title: 'Licencia Vitalicia',
                  price: '\$24.99 USD',
                  subtitle: 'Un solo pago de por vida',
                  badge: 'PAGO ÚNICO',
                  badgeColor: Colors.green,
                ),
              ],

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _activateSubscription,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isEmergency ? 'Restaurar y Activar PRO' : 'Obtener SegurCel PRO',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTile({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = _selectedPlan == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2538),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF6C63FF) : Colors.white38,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? const Color(0xFF6C63FF)).withAlpha(51),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor ?? const Color(0xFF6C63FF)),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(color: badgeColor ?? const Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
