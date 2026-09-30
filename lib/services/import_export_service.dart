import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/password_entry.dart';

class ImportExportService {
  /// Selecciona un archivo CSV o JSON y devuelve la lista de PasswordEntry parsedas.
  static Future<List<PasswordEntry>> importFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
    );

    if (result.isEmpty) {
      return [];
    }

    final file = result.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return [];
    }

    final content = utf8.decode(bytes);
    final ext = file.extension?.toLowerCase() ?? '';

    if (ext == 'json' || content.trim().startsWith('[')) {
      return PasswordEntry.listFromJson(content);
    } else {
      return parseCsvPasswords(content);
    }
  }

  /// Parsea contenido CSV de Chrome, Edge, Bitwarden, 1Password o genérico.
  static List<PasswordEntry> parseCsvPasswords(String csvContent) {
    final List<List<dynamic>> rows = csv.decoder.convert(csvContent);
    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

    int titleIdx = _findHeaderIdx(headers, ['title', 'name', 'nombre', 'servicio', 'site']);
    int userIdx = _findHeaderIdx(headers, ['username', 'login_username', 'email', 'usuario', 'user']);
    int passIdx = _findHeaderIdx(headers, ['password', 'login_password', 'clave', 'contraseña', 'pass']);
    int catIdx = _findHeaderIdx(headers, ['category', 'folder', 'categoría', 'grupo']);
    int notesIdx = _findHeaderIdx(headers, ['notes', 'note', 'notas', 'comentarios']);

    final now = DateTime.now().millisecondsSinceEpoch;
    final List<PasswordEntry> entries = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String title = titleIdx != -1 && titleIdx < row.length ? row[titleIdx].toString().trim() : '';
      String username = userIdx != -1 && userIdx < row.length ? row[userIdx].toString().trim() : '';
      String password = passIdx != -1 && passIdx < row.length ? row[passIdx].toString().trim() : '';
      String category = catIdx != -1 && catIdx < row.length ? row[catIdx].toString().trim() : 'General';
      String notes = notesIdx != -1 && notesIdx < row.length ? row[notesIdx].toString().trim() : '';

      if (title.isEmpty && username.isEmpty && password.isEmpty) continue;
      if (title.isEmpty) title = 'Servicio $i';

      entries.add(PasswordEntry(
        id: '${now}_$i',
        title: title,
        username: username,
        password: password,
        category: category.isEmpty ? 'General' : category,
        notes: notes,
        updatedAt: now,
      ));
    }

    return entries;
  }

  static int _findHeaderIdx(List<String> headers, List<String> candidates) {
    for (final cand in candidates) {
      final idx = headers.indexOf(cand);
      if (idx != -1) return idx;
    }
    return -1;
  }

  /// Genera una cadena CSV con todas las contraseñas.
  static String exportToCsv(List<PasswordEntry> entries) {
    final List<List<dynamic>> rows = [
      ['Title', 'Username', 'Password', 'Category', 'Notes'],
    ];

    for (final e in entries) {
      rows.add([e.title, e.username, e.password, e.category, e.notes]);
    }

    return csv.encoder.convert(rows);
  }

  /// Genera un JSON exportable con todas las contraseñas.
  static String exportToJson(List<PasswordEntry> entries) {
    return PasswordEntry.listToJson(entries);
  }
}
