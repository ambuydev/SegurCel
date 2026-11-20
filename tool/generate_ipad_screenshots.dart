import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final files = [
    'pantalla_principal.png',
    'ingreso_pin.png',
    'auditoria_boveda.png',
    'agregar_elementos.png',
  ];

  final outDir = Directory('ios_screenshots/ipad_13_2048x2732');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  print('=== GENERATING EXPORT FOR APPLE IPAD 13" DISPLAY (2048 x 2732 px) ===');

  for (final filename in files) {
    final file = File('assets/html/$filename');
    if (!file.existsSync()) continue;

    final bytes = file.readAsBytesSync();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) continue;

    final resized = img.copyResize(
      originalImage,
      width: 2048,
      height: 2732,
      interpolation: img.Interpolation.cubic,
    );

    final outFile = File('ios_screenshots/ipad_13_2048x2732/$filename');
    outFile.writeAsBytesSync(img.encodePng(resized));
    print('  ✅ ${outFile.path} (2048x2732 px)');
  }

  print('=== IPAD 13" SCREENSHOTS SUCCESSFULLY GENERATED! ===');
}
