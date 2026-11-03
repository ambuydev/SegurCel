import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/password_entry.dart';
import '../../models/user_profile.dart';
import '../../screens/paywall_screen.dart';
import '../../services/localization_service.dart';
import '../../services/totp_service.dart';
import '../../services/vault_service.dart';
import 'add_edit_entry_sheet.dart';
import 'password_history_sheet.dart';

class PasswordEntryTile extends StatelessWidget {
  final PasswordEntry item;
  final int index;
  final UserProfile? userProfile;
  final Set<String> visiblePasswordIds;
  final VaultService vaultService;
  final LocalizationService loc;
  final Function(String id) onToggleVisibility;
  final Function(PasswordEntry entry) onToggleFavorite;
  final Function(PasswordEntry entry) onDeleteEntry;
  final Function(String? newCat) onEntryUpdated;

  const PasswordEntryTile({
    super.key,
    required this.item,
    required this.index,
    required this.userProfile,
    required this.visiblePasswordIds,
    required this.vaultService,
    required this.loc,
    required this.onToggleVisibility,
    required this.onToggleFavorite,
    required this.onDeleteEntry,
    required this.onEntryUpdated,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ${loc.text("copied_toast")}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = userProfile?.isPremium ?? false;
    final isLockedByLimit = !isPremium && index >= 20;
    final isVisible = visiblePasswordIds.contains(item.id);
    final isCard = item.entryType == 'cards';
    final isNote = item.entryType == 'notes';
    final totp = isLockedByLimit ? null : TotpService.generateTotp(item.totpSecret);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10141D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isFavorite ? Colors.amber.withAlpha(100) : Colors.white12,
          width: item.isFavorite ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isCard
                      ? Colors.amber.withAlpha(51)
                      : (isNote
                          ? Colors.teal.withAlpha(51)
                          : (item.isFavorite
                              ? Colors.amber.withAlpha(51)
                              : const Color(0xFF6C63FF).withAlpha(51))),
                  child: Icon(
                    isCard
                        ? Icons.credit_card
                        : (isNote ? Icons.note_alt_outlined : Icons.vpn_key_outlined),
                    size: 18,
                    color: isCard
                        ? Colors.amberAccent
                        : (isNote
                            ? Colors.tealAccent
                            : (item.isFavorite ? Colors.amber : const Color(0xFF6C63FF))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.username.isNotEmpty)
                        Text(
                          item.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.star : Icons.star_border,
                    color: item.isFavorite ? Colors.amber : Colors.white38,
                    size: 22,
                  ),
                  tooltip: 'Favorito',
                  onPressed: () => onToggleFavorite(item),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 12),

            if (isLockedByLimit) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '🔒 Requiere SegurCel Premium para ver / copiar',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Renovar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaywallScreen(vaultService: vaultService, userProfile: userProfile),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else if (isNote) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isVisible
                          ? (item.notes.isNotEmpty ? item.notes : 'Sin contenido')
                          : '••••••••••••••••••••',
                      maxLines: isVisible ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isVisible ? Colors.tealAccent : Colors.white70,
                        fontSize: 14,
                        letterSpacing: isVisible ? 0 : 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => onToggleVisibility(item.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, color: Color(0xFF6C63FF), size: 20),
                    tooltip: loc.text('copy'),
                    onPressed: () => _copyToClipboard(context, item.notes, loc.text('type_note')),
                  ),
                ],
              ),
            ] else if (isCard) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVisible
                              ? item.password
                              : (item.password.length > 4
                                  ? '•••• •••• •••• ${item.password.substring(item.password.length - 4)}'
                                  : '•••• •••• •••• ••••'),
                          style: TextStyle(
                            color: isVisible ? Colors.amberAccent : Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        if (isVisible && (item.cardExpiry.isNotEmpty || item.cardCvv.isNotEmpty || item.cardPin.isNotEmpty)) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${loc.text("card_expiry")}: ${item.cardExpiry}  |  CVV: ${item.cardCvv}  |  PIN: ${item.cardPin}',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => onToggleVisibility(item.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, color: Color(0xFF6C63FF), size: 20),
                    tooltip: loc.text('copy'),
                    onPressed: () => _copyToClipboard(context, item.password, loc.text('card_number')),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isVisible ? item.password : '••••••••••••',
                      style: TextStyle(
                        color: isVisible ? const Color(0xFF80EE99) : Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: isVisible ? 1 : 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => onToggleVisibility(item.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, color: Color(0xFF6C63FF), size: 20),
                    tooltip: loc.text('copy'),
                    onPressed: () => _copyToClipboard(context, item.password, loc.text('password_label')),
                  ),
                ],
              ),
            ],

            if (totp != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyan.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      '2FA:',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        totp.code,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: totp.progress,
                        strokeWidth: 3,
                        color: totp.remainingSeconds < 6 ? Colors.redAccent : Colors.cyanAccent,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.cyanAccent, size: 18),
                      tooltip: loc.text('totp_code_copied'),
                      onPressed: () => _copyToClipboard(context, totp.rawCode, 'Código 2FA'),
                    ),
                  ],
                ),
              ),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCard && !isNote)
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.amberAccent, size: 18),
                    tooltip: loc.text('history_title'),
                    onPressed: () => PasswordHistorySheet.show(
                      context,
                      item,
                      vaultService,
                      loc,
                      () => onEntryUpdated(null),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                  onPressed: () => AddEditEntrySheet.show(
                    context,
                    vaultService,
                    loc,
                    onEntryUpdated,
                    item,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  onPressed: () => onDeleteEntry(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
