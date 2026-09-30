import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TotpResult {
  final String code; // ej. "482 910"
  final String rawCode; // ej. "482910"
  final int remainingSeconds; // 0 a 30
  final double progress; // 0.0 a 1.0

  TotpResult({
    required this.code,
    required this.rawCode,
    required this.remainingSeconds,
    required this.progress,
  });
}

class TotpService {
  /// Genera un código TOTP de 6 dígitos basado en RFC 6238 para una clave secreta Base32.
  static TotpResult? generateTotp(String secret) {
    final cleanSecret = secret.replaceAll(' ', '').toUpperCase();
    if (cleanSecret.isEmpty) return null;

    try {
      final keyBytes = _base32Decode(cleanSecret);
      if (keyBytes.isEmpty) return null;

      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeStep = 30;
      final currentCounter = nowSeconds ~/ timeStep;
      final remainingSeconds = timeStep - (nowSeconds % timeStep);
      final progress = remainingSeconds / timeStep;

      // Codificación del contador en 8 bytes en formato Big-Endian
      final counterBytes = Uint8List(8);
      var temp = currentCounter;
      for (int i = 7; i >= 0; i--) {
        counterBytes[i] = temp & 0xff;
        temp >>= 8;
      }

      // Cálculo HMAC-SHA1
      final hmac = Hmac(sha1, keyBytes);
      final digest = hmac.convert(counterBytes).bytes;

      // Truncado Dinámico RFC 4226
      final offset = digest[digest.length - 1] & 0x0f;
      final binary = ((digest[offset] & 0x7f) << 24) |
          ((digest[offset + 1] & 0xff) << 16) |
          ((digest[offset + 2] & 0xff) << 8) |
          (digest[offset + 3] & 0xff);

      final otp = binary % 1000000;
      final rawCode = otp.toString().padLeft(6, '0');
      final formattedCode = '${rawCode.substring(0, 3)} ${rawCode.substring(3)}';

      return TotpResult(
        code: formattedCode,
        rawCode: rawCode,
        remainingSeconds: remainingSeconds,
        progress: progress,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodifica una cadena en formato Base32 a bytes.
  static Uint8List _base32Decode(String input) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final clean = input.replaceAll('=', '').toUpperCase();
    final List<int> bytes = [];

    int buffer = 0;
    int bitsLeft = 0;

    for (int i = 0; i < clean.length; i++) {
      final char = clean[i];
      final val = base32Chars.indexOf(char);
      if (val == -1) continue;

      buffer = (buffer << 5) | val;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bytes.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }

    return Uint8List.fromList(bytes);
  }
}
