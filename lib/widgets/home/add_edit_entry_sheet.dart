import 'package:flutter/material.dart';
import '../../models/password_entry.dart';
import '../../screens/paywall_screen.dart';
import '../../services/localization_service.dart';
import '../../services/vault_service.dart';
import 'password_generator_sheet.dart';

class AddEditEntrySheet extends StatefulWidget {
  final PasswordEntry? existingEntry;
  final VaultService vaultService;
  final LocalizationService loc;
  final Function(String? newCategory) onSaved;

  const AddEditEntrySheet({
    super.key,
    this.existingEntry,
    required this.vaultService,
    required this.loc,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context,
    VaultService vaultService,
    LocalizationService loc,
    Function(String? newCategory) onSaved, [
    PasswordEntry? existingEntry,
  ]) async {
    final isEditing = existingEntry != null;

    if (!isEditing) {
      final profile = await vaultService.fetchUserProfile();
      final isPremium = profile?.isPremium ?? false;

      if (!isPremium && vaultService.entries.length >= 20) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaywallScreen(
                vaultService: vaultService,
                userProfile: profile,
              ),
            ),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFF1E2538),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => AddEditEntrySheet(
          existingEntry: existingEntry,
          vaultService: vaultService,
          loc: loc,
          onSaved: onSaved,
        ),
      );
    }
  }

  @override
  State<AddEditEntrySheet> createState() => _AddEditEntrySheetState();
}

class _AddEditEntrySheetState extends State<AddEditEntrySheet> {
  late bool _isEditing;
  late String _selectedType;

  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _categoryController;
  late TextEditingController _notesController;
  late TextEditingController _totpController;

  late TextEditingController _cardExpiryController;
  late TextEditingController _cardCvvController;
  late TextEditingController _cardPinController;

  late String _selectedCategoryOption;
  late bool _isCreatingNewCategory;

  String? _dialogError;

  List<String> _getExistingCategories() {
    final set = <String>{'General', 'Tarjetas', 'Notas'};
    for (final e in widget.vaultService.entries) {
      final c = e.category.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingEntry != null;
    _selectedType = widget.existingEntry?.entryType ?? 'logins';

    _titleController = TextEditingController(text: widget.existingEntry?.title ?? '');
    _usernameController = TextEditingController(text: widget.existingEntry?.username ?? '');
    _passwordController = TextEditingController(text: widget.existingEntry?.password ?? '');
    
    final initialCat = (widget.existingEntry?.category ?? 'General').trim();
    _categoryController = TextEditingController(text: initialCat);

    final categories = _getExistingCategories();
    if (categories.contains(initialCat)) {
      _selectedCategoryOption = initialCat;
      _isCreatingNewCategory = false;
    } else if (initialCat.isNotEmpty) {
      _selectedCategoryOption = initialCat;
      _isCreatingNewCategory = false;
    } else {
      _selectedCategoryOption = '__NEW_CATEGORY__';
      _isCreatingNewCategory = true;
    }

    _notesController = TextEditingController(text: widget.existingEntry?.notes ?? '');
    _totpController = TextEditingController(text: widget.existingEntry?.totpSecret ?? '');

    _cardExpiryController = TextEditingController(text: widget.existingEntry?.cardExpiry ?? '');
    _cardCvvController = TextEditingController(text: widget.existingEntry?.cardCvv ?? '');
    _cardPinController = TextEditingController(text: widget.existingEntry?.cardPin ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _totpController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardPinController.dispose();
    super.dispose();
  }

  Widget _buildTypeSegmentChip({
    required String id,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF10141D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.white60),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = _getExistingCategories();
    const newCategoryKey = '__NEW_CATEGORY__';

    final dropdownItems = <DropdownMenuItem<String>>[];
    for (final cat in categories) {
      dropdownItems.add(
        DropdownMenuItem<String>(
          value: cat,
          child: Text(
            cat,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    if (!categories.contains(_selectedCategoryOption) && _selectedCategoryOption != newCategoryKey) {
      dropdownItems.add(
        DropdownMenuItem<String>(
          value: _selectedCategoryOption,
          child: Text(
            _selectedCategoryOption,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    dropdownItems.add(
      DropdownMenuItem<String>(
        value: newCategoryKey,
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              widget.loc.text('new_category_option'),
              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dropdownItems.any((item) => item.value == _selectedCategoryOption)
              ? _selectedCategoryOption
              : newCategoryKey,
          dropdownColor: const Color(0xFF1E2538),
          decoration: InputDecoration(
            labelText: widget.loc.text('category_label'),
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.folder_outlined, color: Color(0xFF6C63FF), size: 20),
            filled: true,
            fillColor: const Color(0xFF10141D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
          items: dropdownItems,
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedCategoryOption = val;
              if (val == newCategoryKey) {
                _isCreatingNewCategory = true;
                _categoryController.text = '';
              } else {
                _isCreatingNewCategory = false;
                _categoryController.text = val;
              }
            });
          },
        ),
        if (_isCreatingNewCategory) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _categoryController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: widget.loc.text('new_category_label'),
              labelStyle: const TextStyle(color: Colors.amberAccent),
              hintText: 'Ej. Trabajo, Personal...',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.create_new_folder_outlined, color: Colors.amberAccent, size: 20),
              filled: true,
              fillColor: const Color(0xFF10141D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amberAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.amberAccent.withAlpha(150)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amberAccent),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsetsBottom > 0
        ? viewInsetsBottom + 20
        : viewPaddingBottom + 24;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomPadding,
        ),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? widget.loc.text('edit_password') : widget.loc.text('add_password'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTypeSegmentChip(
                    id: 'logins',
                    label: widget.loc.text('type_login'),
                    icon: Icons.key_outlined,
                    isSelected: _selectedType == 'logins',
                    onTap: () => setState(() => _selectedType = 'logins'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTypeSegmentChip(
                    id: 'cards',
                    label: widget.loc.text('type_card'),
                    icon: Icons.credit_card,
                    isSelected: _selectedType == 'cards',
                    onTap: () => setState(() {
                      _selectedType = 'cards';
                      if (_categoryController.text == 'General' || _categoryController.text.isEmpty) {
                        _categoryController.text = 'Tarjetas';
                        _selectedCategoryOption = 'Tarjetas';
                        _isCreatingNewCategory = false;
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTypeSegmentChip(
                    id: 'notes',
                    label: widget.loc.text('type_note'),
                    icon: Icons.note_alt_outlined,
                    isSelected: _selectedType == 'notes',
                    onTap: () => setState(() {
                      _selectedType = 'notes';
                      if (_categoryController.text == 'General' || _categoryController.text.isEmpty) {
                        _categoryController.text = 'Notas';
                        _selectedCategoryOption = 'Notas';
                        _isCreatingNewCategory = false;
                      }
                    }),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_selectedType == 'logins') ...[
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.loc.text('title_label'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.loc.text('username_label'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: widget.loc.text('password_label'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF6C63FF), size: 24),
                    tooltip: widget.loc.text('generate_password'),
                    onPressed: () => PasswordGeneratorSheet.show(context, _passwordController, widget.loc),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _totpController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.loc.text('totp_label'),
                  hintText: widget.loc.text('totp_hint'),
                  hintStyle: const TextStyle(color: Colors.white30),
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.security, color: Colors.cyanAccent, size: 20),
                ),
              ),
            ] else if (_selectedType == 'cards') ...[
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.loc.text('card_title'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.loc.text('card_holder'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.loc.text('card_number'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardExpiryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: widget.loc.text('card_expiry'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cardCvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: widget.loc.text('card_cvv'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cardPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: widget.loc.text('card_pin'),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.loc.text('note_title'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: widget.loc.text('note_content'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
            ],

            const SizedBox(height: 12),

            _buildCategorySection(),

            if (_selectedType != 'notes') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: widget.loc.text('notes_label'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
            ],

            if (_dialogError != null) ...[
              const SizedBox(height: 10),
              Text(_dialogError!, style: const TextStyle(color: Colors.redAccent)),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final title = _titleController.text.trim();
                final username = _usernameController.text.trim();
                final password = _passwordController.text.trim();

                if (title.isEmpty) {
                  setState(() {
                    _dialogError = widget.loc.text('pin_error');
                  });
                  return;
                }

                final now = DateTime.now().millisecondsSinceEpoch;
                List<HistoricalPassword> history = [];

                if (_isEditing && _selectedType == 'logins' && widget.existingEntry != null) {
                  history = List<HistoricalPassword>.from(widget.existingEntry!.history);
                  if (widget.existingEntry!.password != password && password.isNotEmpty) {
                    history.insert(
                      0,
                      HistoricalPassword(
                        password: widget.existingEntry!.password,
                        changedAt: widget.existingEntry!.updatedAt,
                      ),
                    );
                  }
                }

                final catText = _categoryController.text.trim();
                final newEntry = PasswordEntry(
                  id: _isEditing ? widget.existingEntry!.id : now.toString(),
                  title: title,
                  username: username,
                  password: password,
                  category: catText.isEmpty
                      ? (_selectedType == 'cards'
                          ? 'Tarjetas'
                          : (_selectedType == 'notes' ? 'Notas' : 'General'))
                      : catText,
                  notes: _notesController.text.trim(),
                  entryType: _selectedType,
                  cardExpiry: _cardExpiryController.text.trim(),
                  cardCvv: _cardCvvController.text.trim(),
                  cardPin: _cardPinController.text.trim(),
                  totpSecret: _totpController.text.trim(),
                  isFavorite: widget.existingEntry?.isFavorite ?? false,
                  updatedAt: now,
                  history: history,
                );

                final currentList = List<PasswordEntry>.from(widget.vaultService.entries);
                if (_isEditing) {
                  final idx = currentList.indexWhere((e) => e.id == widget.existingEntry!.id);
                  if (idx != -1) currentList[idx] = newEntry;
                } else {
                  currentList.add(newEntry);
                }

                await widget.vaultService.saveEntries(currentList);
                if (context.mounted) {
                  widget.onSaved(catText);
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                _isEditing ? widget.loc.text('save_changes') : widget.loc.text('add_password'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
