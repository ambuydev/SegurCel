import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class FileHelperImpl {
  static Future<String?> pickFileContent() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
    );

    if (result.isEmpty) {
      return null;
    }

    final file = result.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    return utf8.decode(bytes);
  }

  static Future<void> saveFile(String content, String fileName) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    await FilePicker.saveFile(
      dialogTitle: 'Guardar respaldo de contraseñas',
      fileName: fileName,
      bytes: bytes,
    );
  }

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
