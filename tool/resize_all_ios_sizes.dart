import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final files = [
    'pantalla_principal.png',
    'ingreso_pin.png',
    'auditoria_boveda.png',
    'agregar_elementos.png',
  ];

  final sizes = {
    'mediana_1179x2556': {'w': 1179, 'h': 2556},
    'max_1290x2796': {'w': 1290, 'h': 2796},
  };

  for (final entry in sizes.entries) {
    final folderName = entry.key;
    final w = entry.value['w']!;
    final h = entry.value['h']!;

    final outDir = Directory('ios_screenshots/$folderName');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    print('=== RESIZING SCREENSHOTS FOR $folderName (${w}x${h}) ===');

    for (final filename in files) {
      final file = File('assets/html/$filename');
      if (!file.existsSync()) continue;

      final bytes = file.readAsBytesSync();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) continue;

      final resized = img.copyResize(
        originalImage,
        width: w,
        height: h,
        interpolation: img.Interpolation.cubic,
      );

      final outFile = File('ios_screenshots/$folderName/$filename');
      outFile.writeAsBytesSync(img.encodePng(resized));
      print('  ✅ ${outFile.path} (${w}x${h} px)');
    }
  }

  print('=== ALL APPLE SCREENSHOT SETS SUCCESSFULLY GENERATED! ===');
}
