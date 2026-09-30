import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/password_health_service.dart';
import '../services/vault_service.dart';
import 'login_screen.dart';
import 'pin_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VaultService vaultService;

  const HomeScreen({super.key, required this.vaultService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _loc = LocalizationService();
  String _searchQuery = '';
  late String _selectedCategory;
  final Set<String> _visiblePasswordIds = {};

  @override
  void initState() {
    super.initState();
    _selectedCategory = _loc.text('all_categories');
  }

  List<String> get _availableCategories {
    final allCatText = _loc.text('all_categories');
    const favCatText = '⭐ Favoritos';
    final categoriesSet = <String>{allCatText};

    final hasFavorites = widget.vaultService.entries.any((e) => e.isFavorite);
    if (hasFavorites) {
      categoriesSet.add(favCatText);
    }

    for (final e in widget.vaultService.entries) {
      if (e.category.trim().isNotEmpty) {
        categoriesSet.add(e.category.trim());
      }
    }
    final list = categoriesSet.toList();
    list.sort((a, b) {
      if (a == allCatText) return -1;
      if (b == allCatText) return 1;
      if (a == favCatText) return -1;
      if (b == favCatText) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  void _lockVault() {
    widget.vaultService.lock();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PinScreen(vaultService: widget.vaultService),
      ),
      (route) => false,
    );
  }

  void _signOut() async {
    await AuthService().signOut();
    widget.vaultService.lock();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(vaultService: widget.vaultService),
        ),
        (route) => false,
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ${_loc.text("copied_toast")}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _togglePasswordVisibility(String id) {
    setState(() {
      if (_visiblePasswordIds.contains(id)) {
        _visiblePasswordIds.remove(id);
      } else {
        _visiblePasswordIds.add(id);
      }
    });
  }

  Future<void> _toggleFavorite(PasswordEntry entry) async {
    final updatedEntry = entry.copyWith(isFavorite: !entry.isFavorite);
    final currentList = List<PasswordEntry>.from(widget.vaultService.entries);
    final idx = currentList.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      currentList[idx] = updatedEntry;
      await widget.vaultService.saveEntries(currentList);
      setState(() {});
    }
  }

  String _formatDateTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _deleteEntry(PasswordEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2538),
        title: Text(_loc.text('delete_password'), style: const TextStyle(color: Colors.white)),
        content: Text('${_loc.text("delete_confirm")} (${entry.title})', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_loc.text('cancel'), style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_loc.text('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedList = List<PasswordEntry>.from(widget.vaultService.entries)
        ..removeWhere((e) => e.id == entry.id);

      await widget.vaultService.saveEntries(updatedList);
      setState(() {});
    }
  }

  void _showHealthAuditBottomSheet() {
    String selectedFilter = 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2538),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final report = PasswordHealthService.analyzeVault(widget.vaultService.entries);

            Color scoreColor = Colors.greenAccent;
            String statusText = _loc.text('health_excellent');

            if (report.overallScore < 50) {
              scoreColor = Colors.redAccent;
              statusText = _loc.text('health_action_needed');
            } else if (report.overallScore < 80) {
              scoreColor = Colors.amberAccent;
              statusText = _loc.text('health_good');
            }

            List<PasswordEntry> currentFilteredList = [];
            if (selectedFilter == 'weak') {
              currentFilteredList = report.weakEntries;
            } else if (selectedFilter == 'reused') {
              currentFilteredList = report.reusedEntries;
            } else if (selectedFilter == 'old') {
              currentFilteredList = report.oldEntries;
            } else if (selectedFilter == 'strong') {
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
                        _loc.text('audit_vault'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Anillo de Salud de Seguridad
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
                                '${_loc.text("security_score")}: ${report.overallScore}/100',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjetas Interactivas de Desglose
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAuditFilterChip(
                        id: 'weak',
                        label: _loc.text('weak_passwords'),
                        count: report.weakEntries.length,
                        color: Colors.redAccent,
                        isSelected: selectedFilter == 'weak',
                        onTap: () => setModalState(() => selectedFilter = selectedFilter == 'weak' ? 'all' : 'weak'),
                      ),
                      _buildAuditFilterChip(
                        id: 'reused',
                        label: _loc.text('reused_passwords'),
                        count: report.reusedEntries.length,
                        color: Colors.amberAccent,
                        isSelected: selectedFilter == 'reused',
                        onTap: () => setModalState(() => selectedFilter = selectedFilter == 'reused' ? 'all' : 'reused'),
                      ),
                      _buildAuditFilterChip(
                        id: 'old',
                        label: _loc.text('old_passwords'),
                        count: report.oldEntries.length,
                        color: Colors.lightBlueAccent,
                        isSelected: selectedFilter == 'old',
                        onTap: () => setModalState(() => selectedFilter = selectedFilter == 'old' ? 'all' : 'old'),
                      ),
                      _buildAuditFilterChip(
                        id: 'strong',
                        label: _loc.text('strong_passwords'),
                        count: report.strongEntries.length,
                        color: Colors.greenAccent,
                        isSelected: selectedFilter == 'strong',
                        onTap: () => setModalState(() => selectedFilter = selectedFilter == 'strong' ? 'all' : 'strong'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Lista filtrada para corregir contraseñas
                  if (selectedFilter != 'all') ...[
                    Text(
                      '${_loc.text("vault_title")} (${currentFilteredList.length})',
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
                                    Navigator.of(ctx).pop();
                                    _showAddOrEditDialog(item);
                                  },
                                  child: Text(_loc.text('edit_password'), style: const TextStyle(color: Colors.white, fontSize: 12)),
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
          },
        );
      },
    );
  }

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

  void _showHistoryBottomSheet(PasswordEntry entry) {
    final visibleHistoryIndexes = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2538),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final historyList = entry.history;

            Future<void> updateEntryHistory(List<HistoricalPassword> newHistory) async {
              final updatedEntry = entry.copyWith(history: newHistory);
              final currentList = List<PasswordEntry>.from(widget.vaultService.entries);
              final idx = currentList.indexWhere((e) => e.id == entry.id);
              if (idx != -1) {
                currentList[idx] = updatedEntry;
                await widget.vaultService.saveEntries(currentList);
              }
              setState(() {});
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
                      Expanded(
                        child: Text(
                          '${_loc.text("history_title")} - ${entry.title}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      if (historyList.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                          tooltip: _loc.text('clear_history'),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF10141D),
                                title: Text(_loc.text('clear_history'), style: const TextStyle(color: Colors.white)),
                                content: Text(_loc.text('clear_history_confirm')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: Text(_loc.text('cancel'))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => Navigator.of(dCtx).pop(true),
                                    child: Text(_loc.text('delete'), style: const TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await updateEntryHistory([]);
                              if (ctx.mounted) Navigator.of(ctx).pop();
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
                        _loc.text('no_history'),
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
                          final isRevealed = visibleHistoryIndexes.contains(idx);

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
                                  '${_loc.text("modified_on")} ${_formatDateTime(h.changedAt)}',
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
                                        setModalState(() {
                                          if (isRevealed) {
                                            visibleHistoryIndexes.remove(idx);
                                          } else {
                                            visibleHistoryIndexes.add(idx);
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_outlined, color: Color(0xFF6C63FF), size: 18),
                                      tooltip: _loc.text('copy'),
                                      onPressed: () => _copyToClipboard(h.password, _loc.text('password_label')),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                      tooltip: _loc.text('delete'),
                                      onPressed: () async {
                                        final newList = List<HistoricalPassword>.from(historyList)..removeAt(idx);
                                        await updateEntryHistory(newList);
                                        setModalState(() {});
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
          },
        );
      },
    );
  }

  void _showAddOrEditDialog([PasswordEntry? existingEntry]) {
    final isEditing = existingEntry != null;
    final titleController = TextEditingController(text: existingEntry?.title ?? '');
    final usernameController = TextEditingController(text: existingEntry?.username ?? '');
    final passwordController = TextEditingController(text: existingEntry?.password ?? '');
    final categoryController = TextEditingController(text: existingEntry?.category ?? 'General');
    final notesController = TextEditingController(text: existingEntry?.notes ?? '');

    String? dialogError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2538),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void generatePassword() {
              const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
              final random = Random.secure();
              final pass = List.generate(16, (i) => chars[random.nextInt(chars.length)]).join();
              passwordController.text = pass;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? _loc.text('edit_password') : _loc.text('add_password'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: _loc.text('title_label'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: _loc.text('username_label'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: _loc.text('password_label'),
                              labelStyle: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.autorenew, color: Color(0xFF6C63FF)),
                          tooltip: _loc.text('generate_password'),
                          onPressed: generatePassword,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: categoryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: _loc.text('category_label'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: _loc.text('notes_label'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),

                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Text(dialogError!, style: const TextStyle(color: Colors.redAccent)),
                    ],

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final username = usernameController.text.trim();
                        final password = passwordController.text.trim();

                        if (title.isEmpty || password.isEmpty) {
                          setModalState(() {
                            dialogError = _loc.text('pin_error');
                          });
                          return;
                        }

                        final now = DateTime.now().millisecondsSinceEpoch;
                        List<HistoricalPassword> history = [];

                        if (isEditing) {
                          history = List<HistoricalPassword>.from(existingEntry.history);
                          if (existingEntry.password != password) {
                            history.insert(
                              0,
                              HistoricalPassword(
                                password: existingEntry.password,
                                changedAt: existingEntry.updatedAt,
                              ),
                            );
                          }
                        }

                        final catText = categoryController.text.trim();
                        final newEntry = PasswordEntry(
                          id: isEditing ? existingEntry.id : now.toString(),
                          title: title,
                          username: username,
                          password: password,
                          category: catText.isEmpty ? 'General' : catText,
                          notes: notesController.text.trim(),
                          isFavorite: existingEntry?.isFavorite ?? false,
                          updatedAt: now,
                          history: history,
                        );

                        final currentList = List<PasswordEntry>.from(widget.vaultService.entries);
                        if (isEditing) {
                          final idx = currentList.indexWhere((e) => e.id == existingEntry.id);
                          if (idx != -1) currentList[idx] = newEntry;
                        } else {
                          currentList.add(newEntry);
                        }

                        await widget.vaultService.saveEntries(currentList);
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          setState(() {
                            if (catText.isNotEmpty && !_availableCategories.contains(catText)) {
                              _selectedCategory = catText;
                            }
                          });
                        }
                      },
                      child: Text(
                        isEditing ? _loc.text('save_changes') : _loc.text('add_password'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
      icon: const Icon(Icons.language, color: Colors.amberAccent, size: 24),
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
    final allCatText = _loc.text('all_categories');
    const favCatText = '⭐ Favoritos';
    final categories = _availableCategories;

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = allCatText;
    }

    final healthReport = PasswordHealthService.analyzeVault(widget.vaultService.entries);

    Color healthColor = Colors.greenAccent;
    if (healthReport.overallScore < 50) {
      healthColor = Colors.redAccent;
    } else if (healthReport.overallScore < 80) {
      healthColor = Colors.amberAccent;
    }

    final categoryFiltered = widget.vaultService.entries.where((e) {
      if (_selectedCategory == allCatText) return true;
      if (_selectedCategory == favCatText) return e.isFavorite;
      return e.category.trim().toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    final searchFiltered = categoryFiltered.where((e) {
      final q = _searchQuery.toLowerCase();
      return e.title.toLowerCase().contains(q) ||
          e.username.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q);
    }).toList();

    searchFiltered.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2538),
        elevation: 2,
        titleSpacing: 12,
        title: Text(
          _loc.text('app_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          _buildLanguagePicker(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: _loc.text('settings'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(vaultService: widget.vaultService),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.amberAccent),
            tooltip: _loc.text('lock_vault'),
            onPressed: _lockVault,
          ),
          if (AuthService().currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: _loc.text('sign_out'),
              onPressed: _signOut,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de Estado de la Nube
            if (AuthService().currentUser == null)
              Container(
                color: const Color(0xFF6C63FF).withAlpha(51),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_outlined, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _loc.text('local_mode_banner'),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        backgroundColor: const Color(0xFF6C63FF),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(vaultService: widget.vaultService),
                          ),
                        );
                      },
                      child: Text(_loc.text('connect_button'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              )
            else
              Container(
                color: Colors.green.withAlpha(38),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_loc.text("cloud_active_banner")} (${AuthService().currentUser?.email})',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Tarjeta de Indicador de Salud de la Bóveda
            if (widget.vaultService.entries.isNotEmpty)
              GestureDetector(
                onTap: _showHealthAuditBottomSheet,
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2538),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: healthColor.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield, color: healthColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc.text('vault_health'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${_loc.text("security_score")}: ${healthReport.overallScore}/100',
                              style: TextStyle(color: healthColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: healthColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: healthColor),
                        ),
                        child: Text(
                          _loc.text('audit_vault'),
                          style: TextStyle(color: healthColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Buscador
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: _loc.text('search_placeholder'),
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E2538),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Pestañas / Orejetas de Fichero (Categorías)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = cat.toLowerCase() == _selectedCategory.toLowerCase();

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E2538) : const Color(0xFF141A28),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          border: Border(
                            top: BorderSide(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.white12,
                              width: isSelected ? 2.5 : 1,
                            ),
                            left: BorderSide(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                            right: BorderSide(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                            bottom: BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat == allCatText
                                  ? Icons.folder_copy_outlined
                                  : (cat == favCatText ? Icons.star : Icons.folder_outlined),
                              size: 16,
                              color: isSelected
                                  ? (cat == favCatText ? Colors.amber : const Color(0xFF6C63FF))
                                  : (cat == favCatText ? Colors.amber.withAlpha(180) : Colors.white54),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Cuerpo del Fichero (Contenido de la categoría activa)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2538),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border.all(color: const Color(0xFF6C63FF).withAlpha(100), width: 1.5),
                ),
                child: searchFiltered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open, size: 70, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCategory == allCatText
                                  ? _loc.text('no_passwords')
                                  : '${_loc.text("no_passwords_category")} "$_selectedCategory"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: searchFiltered.length,
                        itemBuilder: (context, index) {
                          final item = searchFiltered[index];
                          final isVisible = _visiblePasswordIds.contains(item.id);

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
                                  // Fila Superior: Avatar + Título y Usuario Espaciosos + Estrella Favorito
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: item.isFavorite
                                            ? Colors.amber.withAlpha(51)
                                            : const Color(0xFF6C63FF).withAlpha(51),
                                        child: Text(
                                          item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: item.isFavorite ? Colors.amber : const Color(0xFF6C63FF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
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
                                        onPressed: () => _toggleFavorite(item),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white12, height: 14),

                                  // Fila Inferior: Contraseña + Botones de Acción (Ver, Copiar, Historial, Editar, Eliminar)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isVisible ? item.password : '••••••••••••',
                                          style: TextStyle(
                                            color: isVisible ? const Color(0xFF80EE99) : Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: isVisible ? 1 : 2,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: Colors.white54,
                                          size: 18,
                                        ),
                                        onPressed: () => _togglePasswordVisibility(item.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_outlined, color: Color(0xFF6C63FF), size: 18),
                                        tooltip: _loc.text('copy'),
                                        onPressed: () => _copyToClipboard(item.password, _loc.text('password_label')),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.history, color: Colors.amberAccent, size: 18),
                                        tooltip: _loc.text('history_title'),
                                        onPressed: () => _showHistoryBottomSheet(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                                        onPressed: () => _showAddOrEditDialog(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        onPressed: () => _deleteEntry(item),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: () => _showAddOrEditDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
