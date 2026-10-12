import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/password_entry.dart';
import '../../services/localization_service.dart';
import '../../services/vault_service.dart';

class PasswordHistorySheet extends StatefulWidget {
  final PasswordEntry entry;
  final VaultService vaultService;
  final LocalizationService loc;
  final VoidCallback onStateUpdated;

  const PasswordHistorySheet({
    super.key,
    required this.entry,
    required this.vaultService,
    required this.loc,
    required this.onStateUpdated,
  });

  static void show(
    BuildContext context,
    PasswordEntry entry,
    VaultService vaultService,
    LocalizationService loc,
    VoidCallback onStateUpdated,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2538),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PasswordHistorySheet(
        entry: entry,
        vaultService: vaultService,
        loc: loc,
        onStateUpdated: onStateUpdated,
      ),
    );
  }

  @override
  State<PasswordHistorySheet> createState() => _PasswordHistorySheetState();
}

class _PasswordHistorySheetState extends State<PasswordHistorySheet> {
  final Set<int> _visibleHistoryIndexes = {};

  String _formatDateTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
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

  Future<void> _updateEntryHistory(List<HistoricalPassword> newHistory) async {
    final updatedEntry = widget.entry.copyWith(history: newHistory);
    final currentList = List<PasswordEntry>.from(widget.vaultService.entries);
    final idx = currentList.indexWhere((e) => e.id == widget.entry.id);
    if (idx != -1) {
      currentList[idx] = updatedEntry;
      await widget.vaultService.saveEntries(currentList);
    }
    widget.onStateUpdated();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final historyList = widget.entry.history;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${widget.loc.text("history_title")} - ${widget.entry.title}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (historyList.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  tooltip: widget.loc.text('clear_history'),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF10141D),
                        title: Text(widget.loc.text('clear_history'), style: const TextStyle(color: Colors.white)),
                        content: Text(widget.loc.text('clear_history_confirm')),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: Text(widget.loc.text('cancel'))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => Navigator.of(dCtx).pop(true),
                            child: Text(widget.loc.text('delete'), style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _updateEntryHistory([]);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (historyList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                widget.loc.text('no_history'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: historyList.length,
                itemBuilder: (context, idx) {
                  final h = historyList[idx];
                  final isRevealed = _visibleHistoryIndexes.contains(idx);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10141D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.loc.text("modified_on")} ${_formatDateTime(h.changedAt)}',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isRevealed ? h.password : '••••••••••••',
                                style: TextStyle(
                                  color: isRevealed ? const Color(0xFF80EE99) : Colors.white70,
                                  fontSize: 14,
                                  letterSpacing: isRevealed ? 1 : 2,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white54,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isRevealed) {
                                    _visibleHistoryIndexes.remove(idx);
                                  } else {
                                    _visibleHistoryIndexes.add(idx);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined, color: Color(0xFF6C63FF), size: 18),
                              tooltip: widget.loc.text('copy'),
                              onPressed: () => _copyToClipboard(h.password, widget.loc.text('password_label')),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                              tooltip: widget.loc.text('delete'),
                              onPressed: () async {
                                final newList = List<HistoricalPassword>.from(historyList)..removeAt(idx);
                                await _updateEntryHistory(newList);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
