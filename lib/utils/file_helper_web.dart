// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class FileHelperImpl {
  static Future<String?> pickFileContent() async {
    final Completer<String?> completer = Completer();
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
      ..accept = '.csv,.json';

    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }

      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        try {
          final content = reader.result as String?;
          completer.complete(content);
        } catch (_) {
          completer.complete(null);
        }
      });

      reader.readAsText(file);
    });

    return completer.future;
  }

  static Future<void> saveFile(String content, String fileName) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..setAttribute("download", fileName);
    anchor.click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> openUrl(String url) async {
    html.window.open(url, '_blank');
  }
}
