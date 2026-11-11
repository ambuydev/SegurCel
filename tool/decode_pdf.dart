import 'dart:io';

void main() {
  final bytes = File('Propuesta Cirineos.pdf').readAsBytesSync();
  final content = String.fromCharCodes(bytes);
  
  final streamReg = RegExp(r'stream[\r\n]+([\s\S]*?)[\r\n]+endstream');
  final matches = streamReg.allMatches(content);
  int idx = 0;
  for (final m in matches) {
    idx++;
    final streamData = bytes.sublist(m.start + 7, m.end - 10);
    try {
      final decompressed = zlib.decode(streamData);
      final text = String.fromCharCodes(decompressed);
      print('--- STREAM $idx ---');
      // Print clean text lines
      final clean = text.replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\u00FF]'), ' ');
      if (clean.trim().isNotEmpty) {
        print(clean);
      }
    } catch (_) {}
  }
}
