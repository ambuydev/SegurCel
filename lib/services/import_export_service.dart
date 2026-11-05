import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/password_entry.dart';
import '../utils/file_helper.dart';
import 'crypto_service.dart';

class ImportExportService {
  /// Selecciona un archivo y devuelve el contenido en bruto.
  static Future<String?> pickRawFileContent() async {
    return await FileHelper.pickFileContent();
  }

  /// Verifica si el contenido pertenece a un Respaldo Cifrado de SegurCel (.segurcel).
  static bool isEncryptedBackup(String content) {
    final trimmed = content.trim();
    return trimmed.contains('"format"') && trimmed.contains('segurcel_backup');
  }

  /// Descifra e importa un archivo .segurcel usando la contraseña de respaldo.
  static Future<List<PasswordEntry>> importFromEncryptedBackup(
    String content,
    String backupPassword,
  ) async {
    final Map<String, dynamic> data = jsonDecode(content);
    final String saltBase64 = data['salt'] as String;
    final String payloadBase64 = data['data'] as String;

    final Uint8List salt = base64Decode(saltBase64);
    final Uint8List encryptedData = base64Decode(payloadBase64);

    final key = await CryptoService.deriveKeyFromPassword(backupPassword, salt);
    final decryptedBytes = await CryptoService.decrypt(encryptedData, key);
    final jsonStr = utf8.decode(decryptedBytes);

    return PasswordEntry.listFromJson(jsonStr);
  }

  /// Parsea contenido en texto plano (JSON o CSV).
  static List<PasswordEntry> parsePlainContent(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('[')) {
      return PasswordEntry.listFromJson(trimmed);
    } else {
      return parseCsvPasswords(trimmed);
    }
  }

  /// Selecciona un archivo CSV o JSON y devuelve la lista de PasswordEntry parsedas.
  static Future<List<PasswordEntry>> importFromFile() async {
    final content = await FileHelper.pickFileContent();
    if (content == null || content.trim().isEmpty) {
      return [];
    }

    if (isEncryptedBackup(content)) {
      throw const FormatException('ENCRYPTED_BACKUP_REQUIRED');
    }

    return parsePlainContent(content);
  }

  /// Genera un respaldo local cifrado (.segurcel) protegido con contraseña.
  static Future<String> exportToEncryptedBackup(
    List<PasswordEntry> entries,
    String backupPassword,
  ) async {
    final salt = CryptoService.generateSalt();
    final key = await CryptoService.deriveKeyFromPassword(backupPassword, salt);
    final jsonStr = PasswordEntry.listToJson(entries);
    final plainBytes = Uint8List.fromList(utf8.encode(jsonStr));

    final encryptedBytes = await CryptoService.encrypt(plainBytes, key);

    final Map<String, dynamic> payload = {
      'format': 'segurcel_backup',
      'version': 1,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'salt': base64Encode(salt),
      'data': base64Encode(encryptedBytes),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
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
