import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/password_health_service.dart';
import '../services/vault_service.dart';
import '../utils/file_helper.dart';
import '../widgets/home/about_app_sheet.dart';
import '../widgets/home/add_edit_entry_sheet.dart';
import '../widgets/home/onboarding_sheet.dart';
import '../widgets/home/password_entry_tile.dart';
import '../widgets/home/vault_health_audit_sheet.dart';
import 'login_screen.dart';
import 'my_devices_screen.dart';
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
  Timer? _totpTimer;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkOnboarding();
    _selectedCategory = _loc.text('all_categories');
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingSheet.shouldShow();
    if (shouldShow && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          OnboardingSheet.show(context, _loc);
        }
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await widget.vaultService.fetchUserProfile();
    if (mounted) {
      setState(() => _userProfile = profile);
    }
  }

  @override
  void dispose() {
    _totpTimer?.cancel();
    super.dispose();
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

  Future<void> _deleteEntry(PasswordEntry entry) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
        title: Text(_loc.text('delete_password'), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF10141D))),
        content: Text('${_loc.text("delete_confirm")} (${entry.title})', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4A5568))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_loc.text('cancel'), style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_loc.text('delete'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildLanguagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIconColor = isDark ? Colors.amberAccent : const Color(0xFFD97706);
    final languages = [
      {'code': 'es', 'name': '🇪🇸 Español'},
      {'code': 'en', 'name': '🇺🇸 English'},
      {'code': 'pt', 'name': '🇧🇷 Português'},
      {'code': 'zh', 'name': '🇨🇳 中文'},
      {'code': 'fr', 'name': '🇫🇷 Français'},
      {'code': 'hi', 'name': '🇮🇳 हिन्दी'},
      {'code': 'de', 'name': '🇩🇪 Deutsch'},
      {'code': 'ja', 'name': '🇯🇵 日本語'},
      {'code': 'ko', 'name': '🇰🇷 한국어'},
      {'code': 'ru', 'name': '🇷🇺 Русский'},
      {'code': 'it', 'name': '🇮🇹 Italiano'},
    ];

    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: primaryIconColor, size: 24),
      tooltip: _loc.text('language'),
      color: isDark ? const Color(0xFF1E2538) : Colors.white,
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
                    color: isSelected ? primaryIconColor : (isDark ? Colors.white : const Color(0xFF10141D)),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: primaryIconColor, size: 18),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF10141D) : const Color(0xFFF0F4F8);
    final appBarBg = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final cardBg = isDark ? const Color(0xFF1E2538) : Colors.white;

    final amberAccentColor = isDark ? Colors.amberAccent : const Color(0xFFD97706);
    final settingsIconColor = isDark ? Colors.white70 : const Color(0xFF10141D);

    Color healthColor = isDark ? Colors.greenAccent : const Color(0xFF137333);
    if (healthReport.overallScore < 50) {
      healthColor = isDark ? Colors.redAccent : Colors.red.shade800;
    } else if (healthReport.overallScore < 80) {
      healthColor = amberAccentColor;
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
          e.category.toLowerCase().contains(q) ||
          e.notes.toLowerCase().contains(q);
    }).toList();

    searchFiltered.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        elevation: 2,
        titleSpacing: 12,
        title: GestureDetector(
          onTap: () => AboutAppSheet.show(context, _loc),
          child: Text(
            _loc.text('app_title'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: amberAccentColor, size: 22),
            tooltip: _loc.text('user_guide'),
            onPressed: () {
              FileHelper.openUrl('https://segurcel.app/guide.html');
            },
          ),
          _buildLanguagePicker(),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.phonelink_lock, color: Color(0xFF6C63FF)),
              tooltip: _loc.text('my_devices_title'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyDevicesScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: settingsIconColor),
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
            icon: Icon(Icons.lock_outline, color: amberAccentColor),
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
                color: isDark ? const Color(0xFF6C63FF).withAlpha(51) : const Color(0xFFEEF2FF),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined, color: amberAccentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _loc.text('local_mode_banner'),
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF3730A3), fontSize: 13, fontWeight: FontWeight.w500),
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
                color: isDark ? Colors.green.withAlpha(38) : const Color(0xFFE6F4EA),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done_outlined, color: isDark ? Colors.greenAccent : const Color(0xFF137333), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_loc.text("cloud_active_banner")} (${AuthService().currentUser?.email})',
                        style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF137333), fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Tarjeta de Indicador de Salud de la Bóveda
            if (widget.vaultService.entries.isNotEmpty)
              GestureDetector(
                onTap: () => VaultHealthAuditSheet.show(
                  context,
                  widget.vaultService,
                  _loc,
                  (newCat) {
                    setState(() {
                      if (newCat != null && newCat.isNotEmpty && !_availableCategories.contains(newCat)) {
                        _selectedCategory = newCat;
                      }
                    });
                  },
                ),
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
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
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
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
                style: TextStyle(color: textColor),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: _loc.text('search_placeholder'),
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Pestañas de Categorías
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = cat.toLowerCase() == _selectedCategory.toLowerCase();

                    IconData catIcon = Icons.folder_outlined;
                    Color catIconColor = isSelected ? const Color(0xFF6C63FF) : (isDark ? Colors.white54 : Colors.black54);

                    if (cat == allCatText) {
                      catIcon = Icons.folder_copy_outlined;
                    } else if (cat == favCatText) {
                      catIcon = Icons.star;
                      catIconColor = amberAccentColor;
                    } else if (cat == 'Tarjetas') {
                      catIcon = Icons.credit_card;
                      catIconColor = amberAccentColor;
                    } else if (cat == 'Notas') {
                      catIcon = Icons.note_alt_outlined;
                      catIconColor = isDark ? Colors.tealAccent : Colors.teal.shade800;
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? cardBg : (isDark ? const Color(0xFF141A28) : const Color(0xFFE2E8F0)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          border: Border(
                            top: BorderSide(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.black12,
                              width: isSelected ? 2.5 : 1,
                            ),
                            left: BorderSide(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.black12,
                              width: isSelected ? 1.5 : 1,
                            ),
                            right: BorderSide(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.black12,
                              width: isSelected ? 1.5 : 1,
                            ),
                            bottom: BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              catIcon,
                              size: 16,
                              color: catIconColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? textColor : (isDark ? Colors.white60 : Colors.black87),
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

            // Cuerpo de la Categoría Activa
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                decoration: BoxDecoration(
                  color: cardBg,
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
                          return PasswordEntryTile(
                            item: item,
                            index: index,
                            userProfile: _userProfile,
                            visiblePasswordIds: _visiblePasswordIds,
                            vaultService: widget.vaultService,
                            loc: _loc,
                            onToggleVisibility: _togglePasswordVisibility,
                            onToggleFavorite: _toggleFavorite,
                            onDeleteEntry: _deleteEntry,
                            onEntryUpdated: (newCat) {
                              setState(() {
                                if (newCat != null && newCat.isNotEmpty && !_availableCategories.contains(newCat)) {
                                  _selectedCategory = newCat;
                                }
                              });
                            },
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
        onPressed: () => AddEditEntrySheet.show(
          context,
          widget.vaultService,
          _loc,
          (newCat) {
            setState(() {
              if (newCat != null && newCat.isNotEmpty && !_availableCategories.contains(newCat)) {
                _selectedCategory = newCat;
              }
            });
          },
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
