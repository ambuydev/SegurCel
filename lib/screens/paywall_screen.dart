import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
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
  final _loc = LocalizationService();
  final _promoCodeController = TextEditingController();
  Timer? _countdownTimer;
  int _remainingMillis = 0;
  String _selectedPlan = 'yearly';
  bool _isLoading = false;
  bool _isRedeemingPromo = false;

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
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isRedeemingPromo = true);

    try {
      final validCodes = ['FAMILIA_SEGURCEL_2026', 'SEGURCEL_VIP', 'REGALO_PREMIUM'];

      if (validCodes.contains(code)) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.set({
          'isPremium': true,
          'subscriptionType': 'promo_gift',
          'promoCodeUsed': code,
          'selfDestructedAt': null,
          'gracePeriodExpiresAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 ¡Código Promocional Canjeado con Éxito! Ahora eres Premium.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Código promocional inválido o expirado.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al canjear: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRedeemingPromo = false);
    }
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
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'isPremium': true,
        'subscriptionType': _selectedPlan,
        'selfDestructedAt': null,
        'gracePeriodExpiresAt': null,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_loc.text('activate_pro')),
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
            content: Text('$e'),
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
        title: Text(widget.isEmergency ? _loc.text('emergency_title') : _loc.text('pro_subscription')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isEmergency) ...[
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
                      Text(
                        _loc.text('emergency_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loc.text('emergency_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                Center(
                  child: Image.asset(
                    'assets/icon/suscripcion.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars_outlined, size: 80, color: Color(0xFF6C63FF)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _loc.text('pro_subscription'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _loc.text('login_subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),

                _buildBenefitRow(Icons.cloud_done_outlined, _loc.text('pro_benefits_1')),
                _buildBenefitRow(Icons.security, _loc.text('pro_benefits_2')),
                _buildBenefitRow(Icons.history, _loc.text('pro_benefits_3')),
                _buildBenefitRow(Icons.language, _loc.text('pro_benefits_4')),
                const SizedBox(height: 24),
              ],

              Text(
                _loc.text('select_plan'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              if (widget.isEmergency)
                _buildPlanTile(
                  id: 'emergency_6m',
                  title: _loc.text('plan_emergency'),
                  price: '\$8.99 USD',
                  subtitle: _loc.text('emergency_title'),
                  badge: 'RESCUE',
                  badgeColor: Colors.amber,
                )
              else ...[
                _buildPlanTile(
                  id: 'yearly',
                  title: _loc.text('plan_yearly'),
                  price: '\$9.99 USD / year',
                  subtitle: '\$0.83 USD / mo (Save 45%)',
                  badge: 'POPULAR',
                  badgeColor: const Color(0xFF6C63FF),
                ),
                const SizedBox(height: 10),
                _buildPlanTile(
                  id: 'monthly',
                  title: _loc.text('plan_monthly'),
                  price: '\$1.50 USD / mo',
                  subtitle: _loc.text('pro_subscription'),
                ),
                const SizedBox(height: 10),
                _buildPlanTile(
                  id: 'lifetime',
                  title: _loc.text('plan_lifetime'),
                  price: '\$24.99 USD',
                  subtitle: 'Lifetime',
                  badge: 'PRO',
                  badgeColor: Colors.green,
                ),
              ],

              const SizedBox(height: 24),

              // Sección Canje de Código Promocional / Regalo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2538),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amberAccent.withAlpha(120)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.amberAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '¿Tienes un Código de Regalo / Promocional?',
                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoCodeController,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Ej: FAMILIA_SEGURCEL_2026',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF10141D),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isRedeemingPromo ? null : _redeemPromoCode,
                          child: _isRedeemingPromo
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text('Canjear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

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
                        _loc.text('activate_pro'),
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
