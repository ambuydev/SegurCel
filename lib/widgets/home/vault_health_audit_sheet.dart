import 'package:flutter/material.dart';
import '../../models/password_entry.dart';
import '../../services/localization_service.dart';
import '../../services/password_health_service.dart';
import '../../services/vault_service.dart';
import 'add_edit_entry_sheet.dart';

class VaultHealthAuditSheet extends StatefulWidget {
  final VaultService vaultService;
  final LocalizationService loc;
  final Function(String? newCat) onEntryUpdated;

  const VaultHealthAuditSheet({
    super.key,
    required this.vaultService,
    required this.loc,
    required this.onEntryUpdated,
  });

  static void show(
    BuildContext context,
    VaultService vaultService,
    LocalizationService loc,
    Function(String? newCat) onEntryUpdated,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1E2538),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => VaultHealthAuditSheet(
        vaultService: vaultService,
        loc: loc,
        onEntryUpdated: onEntryUpdated,
      ),
    );
  }

  @override
  State<VaultHealthAuditSheet> createState() => _VaultHealthAuditSheetState();
}

class _VaultHealthAuditSheetState extends State<VaultHealthAuditSheet> {
  String _selectedFilter = 'all';

  Widget _buildAuditFilterChip({
    required String id,
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(51) : const Color(0xFF10141D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = PasswordHealthService.analyzeVault(widget.vaultService.entries);

    Color scoreColor = Colors.greenAccent;
    String statusText = widget.loc.text('health_excellent');

    if (report.overallScore < 50) {
      scoreColor = Colors.redAccent;
      statusText = widget.loc.text('health_action_needed');
    } else if (report.overallScore < 80) {
      scoreColor = Colors.amberAccent;
      statusText = widget.loc.text('health_good');
    }

    List<PasswordEntry> currentFilteredList = [];
    if (_selectedFilter == 'weak') {
      currentFilteredList = report.weakEntries;
    } else if (_selectedFilter == 'reused') {
      currentFilteredList = report.reusedEntries;
    } else if (_selectedFilter == 'old') {
      currentFilteredList = report.oldEntries;
    } else if (_selectedFilter == 'strong') {
      currentFilteredList = report.strongEntries;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.loc.text('audit_vault'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10141D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scoreColor.withAlpha(128)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: report.overallScore / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white12,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '${report.overallScore}%',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scoreColor),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scoreColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.loc.text("security_score")}: ${report.overallScore}/100',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAuditFilterChip(
                id: 'weak',
                label: widget.loc.text('weak_passwords'),
                count: report.weakEntries.length,
                color: Colors.redAccent,
                isSelected: _selectedFilter == 'weak',
                onTap: () => setState(() => _selectedFilter = _selectedFilter == 'weak' ? 'all' : 'weak'),
              ),
              _buildAuditFilterChip(
                id: 'reused',
                label: widget.loc.text('reused_passwords'),
                count: report.reusedEntries.length,
                color: Colors.amberAccent,
                isSelected: _selectedFilter == 'reused',
                onTap: () => setState(() => _selectedFilter = _selectedFilter == 'reused' ? 'all' : 'reused'),
              ),
              _buildAuditFilterChip(
                id: 'old',
                label: widget.loc.text('old_passwords'),
                count: report.oldEntries.length,
                color: Colors.lightBlueAccent,
                isSelected: _selectedFilter == 'old',
                onTap: () => setState(() => _selectedFilter = _selectedFilter == 'old' ? 'all' : 'old'),
              ),
              _buildAuditFilterChip(
                id: 'strong',
                label: widget.loc.text('strong_passwords'),
                count: report.strongEntries.length,
                color: Colors.greenAccent,
                isSelected: _selectedFilter == 'strong',
                onTap: () => setState(() => _selectedFilter = _selectedFilter == 'strong' ? 'all' : 'strong'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_selectedFilter != 'all') ...[
            Text(
              '${widget.loc.text("vault_title")} (${currentFilteredList.length})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currentFilteredList.length,
                itemBuilder: (context, idx) {
                  final item = currentFilteredList[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10141D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              if (item.username.isNotEmpty)
                                Text(item.username, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            AddEditEntrySheet.show(
                              context,
                              widget.vaultService,
                              widget.loc,
                              widget.onEntryUpdated,
                              item,
                            );
                          },
                          child: Text(widget.loc.text('edit_password'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
