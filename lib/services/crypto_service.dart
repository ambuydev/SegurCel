import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  static final _aesGcm = AesGcm.with256bits();
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 65536,
    bits: 256,
  );

  /// Genera bytes aleatorios seguros.
  static Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Genera un Salt aleatorio de 16 bytes.
  static Uint8List generateSalt() => generateRandomBytes(16);

  /// Genera una Clave Maestra aleatoria de 256 bits.
  static Future<SecretKey> generateMasterKey() async {
    return _aesGcm.newSecretKey();
  }

  /// Deriva una clave AES-256 a partir del PIN/Contraseña usando PBKDF2.
  static Future<SecretKey> deriveKeyFromPassword(String password, Uint8List salt) async {
    final passwordKey = SecretKey(utf8.encode(password));
    return await _pbkdf2.deriveKey(
      secretKey: passwordKey,
      nonce: salt,
    );
  }

  /// Cifra datos en bruto usando AES-256-GCM.
  /// Retorna la concatenación [Nonce (12 bytes) + Cifrado + MAC (16 bytes)].
  static Future<Uint8List> encrypt(Uint8List plainText, SecretKey key) async {
    final secretBox = await _aesGcm.encrypt(
      plainText,
      secretKey: key,
    );
    return Uint8List.fromList(secretBox.concatenation());
  }

  /// Descifra datos en bruto usando AES-256-GCM.
  /// Lanza una excepción si la clave es incorrecta o los datos fueron alterados.
  static Future<Uint8List> decrypt(Uint8List encryptedWithIv, SecretKey key) async {
    final secretBox = SecretBox.fromConcatenation(
      encryptedWithIv,
      nonceLength: 12,
      macLength: 16,
    );
    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: key,
    );
    return Uint8List.fromList(decryptedBytes);
  }

  /// Genera un Código de Recuperación aleatorio de 24 caracteres legibles.
  /// Ejemplo: "A1B2-C3D4-E5F6-G7H8-I9J0-K1L2"
  static String generateRecoveryCode() {
    final randomBytes = generateRandomBytes(18);
    final base64Str = base64UrlEncode(randomBytes).replaceAll('=', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < base64Str.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(base64Str[i]);
    }
    return buffer.toString();
  }
}
