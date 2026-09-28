import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../services/auth_service.dart';
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
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  final Set<String> _visiblePasswordIds = {};

  List<String> get _availableCategories {
    final categoriesSet = <String>{'Todas'};
    for (final e in widget.vaultService.entries) {
      if (e.category.trim().isNotEmpty) {
        categoriesSet.add(e.category.trim());
      }
    }
    final list = categoriesSet.toList();
    list.sort((a, b) {
      if (a == 'Todas') return -1;
      if (b == 'Todas') return 1;
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
        content: Text('$label copiado al portapapeles'),
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
        title: const Text('Eliminar Contraseña', style: TextStyle(color: Colors.white)),
        content: Text('¿Seguro que deseas eliminar "${entry.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
                          'Historial de "${entry.title}"',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      if (historyList.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                          tooltip: 'Vaciar Historial',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF10141D),
                                title: const Text('Vaciar Historial', style: TextStyle(color: Colors.white)),
                                content: const Text('¿Deseas eliminar todo el historial de contraseñas anteriores para este registro?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancelar')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => Navigator.of(dCtx).pop(true),
                                    child: const Text('Vaciar', style: TextStyle(color: Colors.white)),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No hay contraseñas anteriores guardadas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
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
                                  'Modificada el ${_formatDateTime(h.changedAt)}',
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
                                      tooltip: 'Copiar Contraseña',
                                      onPressed: () => _copyToClipboard(h.password, 'Contraseña histórica'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                      tooltip: 'Eliminar este elemento',
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
                      isEditing ? 'Editar Contraseña' : 'Nueva Contraseña',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Título (ej. Gmail, Banco, WiFi)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Usuario / Email',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.autorenew, color: Color(0xFF6C63FF)),
                          tooltip: 'Generar Contraseña Segura',
                          onPressed: generatePassword,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: categoryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notas adicionales (Opcional)',
                        labelStyle: TextStyle(color: Colors.white70),
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
                            dialogError = 'Ingresa al menos el Título y la Contraseña.';
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
                        isEditing ? 'Guardar Cambios' : 'Agregar Contraseña',
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

  @override
  Widget build(BuildContext context) {
    final categories = _availableCategories;

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'Todas';
    }

    // Filtrar por categoría seleccionada
    final categoryFiltered = widget.vaultService.entries.where((e) {
      if (_selectedCategory == 'Todas') return true;
      return e.category.trim().toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    // Filtrar por texto de búsqueda
    final searchFiltered = categoryFiltered.where((e) {
      final q = _searchQuery.toLowerCase();
      return e.title.toLowerCase().contains(q) ||
          e.username.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q);
    }).toList();

    // Ordenar alfabéticamente A-Z por Título
    searchFiltered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2538),
        elevation: 2,
        title: const Text('Bóveda SegurCel', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Ajustes',
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
            tooltip: 'Bloquear Bóveda',
            onPressed: _lockVault,
          ),
          if (AuthService().currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Cerrar Sesión',
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
                    const Expanded(
                      child: Text(
                        'Modo local. Inicia sesión para sincronizar.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
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
                      child: const Text('Conectar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                        'Nube activa (${AuthService().currentUser?.email})',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Buscador
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar contraseña o servicio...',
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
                              cat == 'Todas' ? Icons.folder_copy_outlined : Icons.folder_outlined,
                              size: 16,
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                              _selectedCategory == 'Todas'
                                  ? 'No hay contraseñas guardadas'
                                  : 'No hay contraseñas en la categoría "$_selectedCategory"',
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
                              border: Border.all(color: Colors.white12),
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
                                        backgroundColor: const Color(0xFF6C63FF).withAlpha(51),
                                        child: Text(
                                          item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (item.username.isNotEmpty)
                                              Text(
                                                item.username,
                                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.history, color: Colors.amberAccent, size: 18),
                                        tooltip: 'Ver Historial',
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
                                  const Divider(color: Colors.white12, height: 14),
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
                                        tooltip: 'Copiar Contraseña',
                                        onPressed: () => _copyToClipboard(item.password, 'Contraseña'),
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
