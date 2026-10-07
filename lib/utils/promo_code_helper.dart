import 'dart:math';

class PromoCodeHelper {
  // Vector de pesos oficial del algoritmo Módulo 10 de la Cédula de Identidad Uruguaya
  static const List<int> _weights = [2, 9, 8, 7, 6, 3];

  /// Calcula el Dígito Verificador Módulo 10 para una secuencia numérica de 6 dígitos
  static int calculateCheckDigit(String serialDigits) {
    if (serialDigits.length != 6) return -1;

    int sum = 0;
    for (int i = 0; i < 6; i++) {
      final digit = int.tryParse(serialDigits[i]);
      if (digit == null) return -1;
      sum += digit * _weights[i];
    }

    final mod = sum % 10;
    final checkDigit = (10 - mod) % 10;
    return checkDigit;
  }

  /// Verifica si una cadena formateada como 'SEG-123456-7' es matemáticamente válida
  static bool isValidPromoCodeFormat(String code) {
    final cleanCode = code.trim().toUpperCase();
    final parts = cleanCode.split('-');

    if (parts.length != 3) return false;
    if (parts[0] != 'SEG') return false;

    final serial = parts[1];
    final checkDigitStr = parts[2];

    if (serial.length != 6 || checkDigitStr.length != 1) return false;

    final checkDigitInput = int.tryParse(checkDigitStr);
    if (checkDigitInput == null) return false;

    final expectedCheckDigit = calculateCheckDigit(serial);
    return expectedCheckDigit == checkDigitInput;
  }

  /// Genera un nuevo código promocional Módulo 10 aleatorio con formato 'SEG-XXXXXX-V'
  static String generateRandomCode() {
    final random = Random.secure();
    final serial = List.generate(6, (_) => random.nextInt(10)).join();
    final checkDigit = calculateCheckDigit(serial);
    return 'SEG-$serial-$checkDigit';
  }
}
