import 'dart:io';

void main() {
  final bytes = File('segurcel_production.pdf').readAsBytesSync();
  final latin1Str = String.fromCharCodes(bytes);
  
  // Extract FlateDecode streams
  final streamReg = RegExp(r'stream[\r\n]+([\s\S]*?)[\r\n]+endstream');
  final matches = streamReg.allMatches(latin1Str);
  int idx = 0;
  for (final m in matches) {
    idx++;
    final streamData = bytes.sublist(m.start + 7, m.end - 10);
    try {
      final decompressed = zlib.decode(streamData);
      final text = String.fromCharCodes(decompressed);
      print('=== STREAM $idx ===');
      final clean = text.replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\u00FF\n\r]'), ' ');
      print(clean);
    } catch (_) {}
  }
}
