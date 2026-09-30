import '../models/password_entry.dart';

class PasswordHealthReport {
  final int overallScore; // 0 a 100
  final List<PasswordEntry> weakEntries;
  final List<PasswordEntry> reusedEntries;
  final List<PasswordEntry> oldEntries;
  final List<PasswordEntry> strongEntries;
  final int totalEntries;

  PasswordHealthReport({
    required this.overallScore,
    required this.weakEntries,
    required this.reusedEntries,
    required this.oldEntries,
    required this.strongEntries,
    required this.totalEntries,
  });
}

class PasswordHealthService {
  /// Analiza la lista de contraseñas de la bóveda y genera un informe de salud completo.
  static PasswordHealthReport analyzeVault(List<PasswordEntry> entries) {
    if (entries.isEmpty) {
      return PasswordHealthReport(
        overallScore: 100,
        weakEntries: [],
        reusedEntries: [],
        oldEntries: [],
        strongEntries: [],
        totalEntries: 0,
      );
    }

    final List<PasswordEntry> weak = [];
    final List<PasswordEntry> reused = [];
    final List<PasswordEntry> old = [];
    final List<PasswordEntry> strong = [];

    // Mapeo de frecuencias de contraseña para detectar reutilización
    final Map<String, int> passCounts = {};
    for (final e in entries) {
      final p = e.password;
      if (p.isNotEmpty) {
        passCounts[p] = (passCounts[p] ?? 0) + 1;
      }
    }

    final oneYearAgoMillis = DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch;
    double totalPoints = 0;

    for (final e in entries) {
      final pass = e.password;
      double entryPoints = 100;

      // 1. Evaluación de Fuerza
      final isWeak = _isPasswordWeak(pass);
      if (isWeak) {
        weak.add(e);
        entryPoints -= 40;
      }

      // 2. Evaluación de Reutilización
      final isReused = (passCounts[pass] ?? 0) > 1;
      if (isReused) {
        reused.add(e);
        entryPoints -= 35;
      }

      // 3. Evaluación de Antigüedad (> 1 año)
      final isOld = e.updatedAt < oneYearAgoMillis;
      if (isOld) {
        old.add(e);
        entryPoints -= 25;
      }

      if (!isWeak && !isReused && !isOld) {
        strong.add(e);
      }

      if (entryPoints < 0) entryPoints = 0;
      totalPoints += entryPoints;
    }

    final overallScore = (totalPoints / entries.length).round().clamp(0, 100);

    return PasswordHealthReport(
      overallScore: overallScore,
      weakEntries: weak,
      reusedEntries: reused,
      oldEntries: old,
      strongEntries: strong,
      totalEntries: entries.length,
    );
  }

  /// Evalúa si una contraseña es débil (menos de 8 caracteres, o sólo letras/números simples).
  static bool _isPasswordWeak(String password) {
    if (password.length < 8) return true;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int criteria = 0;
    if (hasUpper) criteria++;
    if (hasLower) criteria++;
    if (hasDigits) criteria++;
    if (hasSpecial) criteria++;

    return criteria < 3;
  }
}
