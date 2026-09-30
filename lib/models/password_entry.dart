import 'dart:convert';

class HistoricalPassword {
  final String password;
  final int changedAt;

  HistoricalPassword({
    required this.password,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'changedAt': changedAt,
    };
  }

  factory HistoricalPassword.fromJson(Map<String, dynamic> json) {
    return HistoricalPassword(
      password: json['password'] ?? '',
      changedAt: json['changedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class PasswordEntry {
  final String id;
  final String title;
  final String username;
  final String password;
  final String category;
  final String notes;
  final String entryType; // 'logins', 'cards', 'notes'
  final String cardExpiry;
  final String cardCvv;
  final String cardPin;
  final bool isFavorite;
  final int updatedAt;
  final List<HistoricalPassword> history;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.category = 'General',
    this.notes = '',
    this.entryType = 'logins',
    this.cardExpiry = '',
    this.cardCvv = '',
    this.cardPin = '',
    this.isFavorite = false,
    int? updatedAt,
    List<HistoricalPassword>? history,
  })  : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
        history = history ?? [];

  PasswordEntry copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? category,
    String? notes,
    String? entryType,
    String? cardExpiry,
    String? cardCvv,
    String? cardPin,
    bool? isFavorite,
    int? updatedAt,
    List<HistoricalPassword>? history,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      entryType: entryType ?? this.entryType,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardCvv: cardCvv ?? this.cardCvv,
      cardPin: cardPin ?? this.cardPin,
      isFavorite: isFavorite ?? this.isFavorite,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      history: history ?? List.from(this.history),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'category': category,
      'notes': notes,
      'entryType': entryType,
      'cardExpiry': cardExpiry,
      'cardCvv': cardCvv,
      'cardPin': cardPin,
      'isFavorite': isFavorite,
      'updatedAt': updatedAt,
      'history': history.map((e) => e.toJson()).toList(),
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    var rawHistory = json['history'] as List<dynamic>?;
    List<HistoricalPassword> historyList = rawHistory != null
        ? rawHistory.map((e) => HistoricalPassword.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return PasswordEntry(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      category: json['category'] ?? 'General',
      notes: json['notes'] ?? '',
      entryType: json['entryType'] ?? 'logins',
      cardExpiry: json['cardExpiry'] ?? '',
      cardCvv: json['cardCvv'] ?? '',
      cardPin: json['cardPin'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      updatedAt: json['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      history: historyList,
    );
  }

  static List<PasswordEntry> listFromJson(String jsonStr) {
    if (jsonStr.trim().isEmpty) return [];
    try {
      final List<dynamic> parsed = jsonDecode(jsonStr);
      return parsed.map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<PasswordEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }
}
