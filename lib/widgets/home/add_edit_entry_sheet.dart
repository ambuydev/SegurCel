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
        backgroundColor: Colors.transparent,
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
      _selectedCategoryOption = 'General';
      _isCreatingNewCategory = false;
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
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : (isDark ? const Color(0xFF10141D) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : (isDark ? Colors.white24 : Colors.black12)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black87)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
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

  Widget _buildCategorySection(bool isDark, Color textColor, Color textSubColor, Color inputFillColor, Color accentAmber) {
    final categories = _getExistingCategories();
    const newCategoryKey = '__NEW_CATEGORY__';

    final dropdownItems = <DropdownMenuItem<String>>[];
    for (final cat in categories) {
      dropdownItems.add(
        DropdownMenuItem<String>(
          value: cat,
          child: Text(
            cat,
            style: TextStyle(color: textColor, fontSize: 14),
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
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
      );
    }

    dropdownItems.add(
      DropdownMenuItem<String>(
        value: newCategoryKey,
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: accentAmber, size: 18),
            const SizedBox(width: 8),
            Text(
              widget.loc.text('new_category_option'),
              style: TextStyle(color: accentAmber, fontWeight: FontWeight.bold, fontSize: 14),
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
          dropdownColor: isDark ? const Color(0xFF1E2538) : Colors.white,
          decoration: InputDecoration(
            labelText: widget.loc.text('category_label'),
            labelStyle: TextStyle(color: textSubColor),
            prefixIcon: const Icon(Icons.folder_outlined, color: Color(0xFF6C63FF), size: 20),
            filled: true,
            fillColor: inputFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
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
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: widget.loc.text('new_category_label'),
              labelStyle: TextStyle(color: accentAmber),
              hintText: 'Ej. Trabajo, Personal...',
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
              prefixIcon: Icon(Icons.create_new_folder_outlined, color: accentAmber, size: 20),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentAmber),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentAmber),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _saveEntry() async {
    final title = _titleController.text.trim();
    var category = _categoryController.text.trim();

    if (title.isEmpty) {
      setState(() => _dialogError = widget.loc.text('title_required'));
      return;
    }

    if (category.isEmpty) {
      if (_selectedType == 'cards') {
        category = 'Tarjetas';
      } else if (_selectedType == 'notes') {
        category = 'Notas';
      } else {
        category = 'General';
      }
    }

    final now = DateTime.now().toIso8601String();

    final entry = PasswordEntry(
      id: widget.existingEntry?.id ?? now,
      title: title,
      username: _selectedType == 'cards'
          ? _usernameController.text.trim()
          : (_selectedType == 'notes' ? '' : _usernameController.text.trim()),
      password: _selectedType == 'notes' ? '' : _passwordController.text.trim(),
      category: category,
      notes: _notesController.text.trim(),
      totpSecret: _totpController.text.trim().replaceAll(' ', ''),
      cardExpiry: _selectedType == 'cards' ? _cardExpiryController.text.trim() : '',
      cardCvv: _selectedType == 'cards' ? _cardCvvController.text.trim() : '',
      cardPin: _selectedType == 'cards' ? _cardPinController.text.trim() : '',
      isFavorite: widget.existingEntry?.isFavorite ?? false,
      entryType: _selectedType,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final currentList = List<PasswordEntry>.from(widget.vaultService.entries);
    final idx = currentList.indexWhere((e) => e.id == entry.id);

    if (idx != -1) {
      currentList[idx] = entry;
    } else {
      currentList.insert(0, entry);
    }

    await widget.vaultService.saveEntries(currentList);
    widget.onSaved(category);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final inputFillColor = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);
    final accentAmber = isDark ? Colors.amberAccent : const Color(0xFFD97706);

    InputDecoration buildInputDecoration(String label, {String? hintText, Widget? prefixIcon}) {
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: inputFillColor,
        labelStyle: TextStyle(color: textSubColor),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      );
    }

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsetsBottom > 0
        ? viewInsetsBottom + 20
        : viewPaddingBottom + 24;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (_selectedType == 'logins') ...[
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('title_label')),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('username_label')),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          style: TextStyle(color: textColor),
                          decoration: buildInputDecoration(widget.loc.text('password_label')),
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
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(
                      widget.loc.text('totp_label'),
                      hintText: widget.loc.text('totp_hint'),
                      prefixIcon: Icon(Icons.security, color: isDark ? Colors.cyanAccent : Colors.cyan.shade800, size: 20),
                    ),
                  ),
                ] else if (_selectedType == 'cards') ...[
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('card_title')),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('card_holder')),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passwordController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('card_number')),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cardExpiryController,
                          keyboardType: TextInputType.datetime,
                          style: TextStyle(color: textColor),
                          decoration: buildInputDecoration(widget.loc.text('card_expiry'), hintText: 'MM/AA'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cardCvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          decoration: buildInputDecoration(widget.loc.text('card_cvv'), hintText: '123'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cardPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          decoration: buildInputDecoration(widget.loc.text('card_pin'), hintText: '1234'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('note_title')),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('note_content')),
                  ),
                ],

                const SizedBox(height: 12),
                _buildCategorySection(isDark, textColor, textSubColor, inputFillColor, accentAmber),

                if (_selectedType == 'logins' || _selectedType == 'cards') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: TextStyle(color: textColor),
                    decoration: buildInputDecoration(widget.loc.text('notes_label')),
                  ),
                ],

                if (_dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _dialogError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(widget.loc.text('cancel'), style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saveEntry,
                      child: Text(
                        _isEditing ? widget.loc.text('save_changes') : widget.loc.text('save_password'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
