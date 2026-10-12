import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/localization_service.dart';

class PasswordGeneratorSheet extends StatefulWidget {
  final TextEditingController targetController;
  final LocalizationService loc;

  const PasswordGeneratorSheet({
    super.key,
    required this.targetController,
    required this.loc,
  });

  static void show(BuildContext context, TextEditingController targetController, LocalizationService loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2538),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PasswordGeneratorSheet(
        targetController: targetController,
        loc: loc,
      ),
    );
  }

  @override
  State<PasswordGeneratorSheet> createState() => _PasswordGeneratorSheetState();
}

class _PasswordGeneratorSheetState extends State<PasswordGeneratorSheet> {
  double _length = 16;
  bool _includeUpper = true;
  bool _includeLower = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _avoidAmbiguous = false;
  late String _generatedPassword;

  @override
  void initState() {
    super.initState();
    _generatedPassword = _generatePassword();
  }

  String _generatePassword() {
    String upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String lowerChars = 'abcdefghijklmnopqrstuvwxyz';
    String numberChars = '0123456789';
    String symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    if (_avoidAmbiguous) {
      upperChars = upperChars.replaceAll(RegExp(r'[IO]'), '');
      lowerChars = lowerChars.replaceAll(RegExp(r'[l]'), '');
      numberChars = numberChars.replaceAll(RegExp(r'[01]'), '');
    }

    String allowed = '';
    if (_includeUpper) allowed += upperChars;
    if (_includeLower) allowed += lowerChars;
    if (_includeNumbers) allowed += numberChars;
    if (_includeSymbols) allowed += symbolChars;

    if (allowed.isEmpty) {
      allowed = lowerChars;
    }

    final random = Random.secure();
    final lenInt = _length.toInt();
    return List.generate(lenInt, (i) => allowed[random.nextInt(allowed.length)]).join();
  }

  void _regenerate() {
    setState(() {
      _generatedPassword = _generatePassword();
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ${widget.loc.text("copied_toast")}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.loc.text('generator_title'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10141D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C63FF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _generatedPassword,
                      style: const TextStyle(
                        color: Color(0xFF80EE99),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, color: Color(0xFF6C63FF), size: 20),
                    tooltip: widget.loc.text('copy'),
                    onPressed: () => _copyToClipboard(_generatedPassword, widget.loc.text('password_label')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.autorenew, color: Colors.amberAccent, size: 22),
                    tooltip: widget.loc.text('generate_password'),
                    onPressed: _regenerate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.loc.text('pass_length'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_length.toInt()} caracteres',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: _length,
              min: 8,
              max: 64,
              divisions: 56,
              activeColor: const Color(0xFF6C63FF),
              inactiveColor: Colors.white12,
              label: '${_length.toInt()}',
              onChanged: (val) {
                setState(() {
                  _length = val;
                  _generatedPassword = _generatePassword();
                });
              },
            ),

            const SizedBox(height: 8),

            CheckboxListTile(
              title: Text(widget.loc.text('include_uppercase'), style: const TextStyle(color: Colors.white, fontSize: 13)),
              value: _includeUpper,
              activeColor: const Color(0xFF6C63FF),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _includeUpper = val ?? true;
                  _generatedPassword = _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: Text(widget.loc.text('include_lowercase'), style: const TextStyle(color: Colors.white, fontSize: 13)),
              value: _includeLower,
              activeColor: const Color(0xFF6C63FF),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _includeLower = val ?? true;
                  _generatedPassword = _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: Text(widget.loc.text('include_numbers'), style: const TextStyle(color: Colors.white, fontSize: 13)),
              value: _includeNumbers,
              activeColor: const Color(0xFF6C63FF),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _includeNumbers = val ?? true;
                  _generatedPassword = _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: Text(widget.loc.text('include_symbols'), style: const TextStyle(color: Colors.white, fontSize: 13)),
              value: _includeSymbols,
              activeColor: const Color(0xFF6C63FF),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _includeSymbols = val ?? true;
                  _generatedPassword = _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: Text(widget.loc.text('avoid_ambiguous'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              value: _avoidAmbiguous,
              activeColor: const Color(0xFF6C63FF),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _avoidAmbiguous = val ?? false;
                  _generatedPassword = _generatePassword();
                });
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.targetController.text = _generatedPassword;
                Navigator.of(context).pop();
              },
              child: Text(
                widget.loc.text('use_password'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
