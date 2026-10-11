/**
 * SegurCel Browser Extension - Crypto Module (Zero-Knowledge)
 * 100% Interoperable con CryptoService (Dart/Flutter)
 * Usa la API nativa de navegadores: Web Crypto API (crypto.subtle)
 */

export class SegurCelCrypto {
  /**
   * Convierte una cadena Base64 en Uint8Array.
   */
  static base64ToUint8Array(base64) {
    const binaryString = atob(base64);
    const len = binaryString.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
  }

  /**
   * Convierte un Uint8Array en una cadena Base64.
   */
  static uint8ArrayToBase64(bytes) {
    let binary = '';
    const len = bytes.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }

  /**
   * Deriva una clave AES-GCM (256 bits) a partir del PIN o contraseña usando PBKDF2-HMAC-SHA256 (65,536 iteraciones).
   */
  static async deriveKeyFromPassword(password, saltUint8Array) {
    const encoder = new TextEncoder();
    const passwordBytes = encoder.encode(password);

    const baseKey = await crypto.subtle.importKey(
      'raw',
      passwordBytes,
      { name: 'PBKDF2' },
      false,
      ['deriveKey']
    );

    const derivedKey = await crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: saltUint8Array,
        iterations: 65536,
        hash: 'SHA-256',
      },
      baseKey,
      { name: 'AES-GCM', length: 256 },
      true, // exportable para envoltorio si fuese necesario
      ['encrypt', 'decrypt']
    );

    return derivedKey;
  }

  /**
   * Descifra el buffer concatenado [IV (12 bytes) + Ciphertext + MAC Tag (16 bytes)] usando AES-256-GCM.
   */
  static async decrypt(encryptedWithIvBytes, key) {
    if (encryptedWithIvBytes.length < 28) {
      throw new Error('Payload cifrado demasiado corto.');
    }

    const iv = encryptedWithIvBytes.slice(0, 12);
    const ciphertextAndTag = encryptedWithIvBytes.slice(12);

    const decryptedBuffer = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      ciphertextAndTag
    );

    return new Uint8Array(decryptedBuffer);
  }

  /**
   * Cifra datos planos usando AES-256-GCM.
   * Retorna concatenación [IV (12 bytes) + Ciphertext + MAC Tag (16 bytes)].
   */
  static async encrypt(plainBytes, key) {
    const iv = crypto.getRandomValues(new Uint8Array(12));

    const encryptedBuffer = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      plainBytes
    );

    const ciphertextAndTag = new Uint8Array(encryptedBuffer);
    const combined = new Uint8Array(iv.length + ciphertextAndTag.length);
    combined.set(iv, 0);
    combined.set(ciphertextAndTag, iv.length);

    return combined;
  }

  /**
   * Importa bytes en bruto (Uint8Array de 32 bytes) como CryptoKey AES-GCM.
   */
  static async importRawMasterKey(masterKeyBytes) {
    return await crypto.subtle.importKey(
      'raw',
      masterKeyBytes,
      { name: 'AES-GCM' },
      true,
      ['encrypt', 'decrypt']
    );
  }

  /**
   * Genera una contraseña segura aleatoria.
   */
  static generateSecurePassword(length = 16, options = { uppercase: true, lowercase: true, numbers: true, symbols: true }) {
    let chars = '';
    if (options.lowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (options.uppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (options.numbers) chars += '0123456789';
    if (options.symbols) chars += '!@#$%^&*()_+-=[]{}|;:,.<>?';

    if (!chars) chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()';

    const randomValues = new Uint32Array(length);
    crypto.getRandomValues(randomValues);

    let password = '';
    for (let i = 0; i < length; i++) {
      password += chars[randomValues[i] % chars.length];
    }
    return password;
  }

  /**
   * Generador de códigos TOTP 2FA (RFC 6238).
   */
  static async generateTOTP(secretBase32, period = 30, digits = 6) {
    try {
      if (!secretBase32) return '';
      const cleanSecret = secretBase32.replace(/[\s-]/g, '').toUpperCase();
      const keyBytes = SegurCelCrypto._base32ToUint8Array(cleanSecret);

      const epoch = Math.floor(Date.now() / 1000);
      const counter = Math.floor(epoch / period);

      const counterBuffer = new ArrayBuffer(8);
      const counterView = new DataView(counterBuffer);
      counterView.setBigUint64(0, BigInt(counter), false); // Big endian

      const cryptoKey = await crypto.subtle.importKey(
        'raw',
        keyBytes,
        { name: 'HMAC', hash: { name: 'SHA-1' } },
        false,
        ['sign']
      );

      const signature = await crypto.subtle.sign('HMAC', cryptoKey, counterBuffer);
      const signatureBytes = new Uint8Array(signature);

      const offset = signatureBytes[signatureBytes.length - 1] & 0xf;
      const binary =
        ((signatureBytes[offset] & 0x7f) << 24) |
        ((signatureBytes[offset + 1] & 0xff) << 16) |
        ((signatureBytes[offset + 2] & 0xff) << 8) |
        (signatureBytes[offset + 3] & 0xff);

      let otp = (binary % Math.pow(10, digits)).toString();
      while (otp.length < digits) {
        otp = '0' + otp;
      }
      return otp;
    } catch (e) {
      console.error('Error calculando TOTP:', e);
      return '------';
    }
  }

  static _base32ToUint8Array(base32) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    let bits = 0;
    let value = 0;
    let output = [];

    for (let i = 0; i < base32.length; i++) {
      const c = base32.charAt(i);
      const index = alphabet.indexOf(c);
      if (index === -1) continue;

      value = (value << 5) | index;
      bits += 5;

      if (bits >= 8) {
        output.push((value >>> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    return new Uint8Array(output);
  }
}
