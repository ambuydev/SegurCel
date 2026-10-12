import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/vault_service.dart';
import '../widgets/pin_creation_form.dart';
import '../widgets/recovery_code_card.dart';
import '../widgets/recovery_confirmation_dialog.dart';

class SetupScreen extends StatefulWidget {
  final VaultService vaultService;

  const SetupScreen({super.key, required this.vaultService});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _loc = LocalizationService();
  String? _generatedRecoveryCode;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleVaultCreation(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recoveryCode = await widget.vaultService.setupVault(pin, []);
      if (mounted) {
        setState(() {
          _generatedRecoveryCode = recoveryCode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _finishSetup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => RecoveryConfirmationDialog(
        vaultService: widget.vaultService,
        loc: _loc,
        parentContext: context,
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
        title: Text(_loc.text('welcome')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _generatedRecoveryCode != null
              ? RecoveryCodeCard(
                  recoveryCode: _generatedRecoveryCode!,
                  onFinishSetup: _finishSetup,
                  loc: _loc,
                )
              : PinCreationForm(
                  onSubmitPin: _handleVaultCreation,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  loc: _loc,
                ),
        ),
      ),
    );
  }
}
