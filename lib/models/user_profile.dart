class UserProfile {
  final String uid;
  final String email;
  final bool isPremium;
  final String subscriptionType;
  final int? selfDestructedAt;
  final int? gracePeriodExpiresAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.isPremium = false,
    this.subscriptionType = 'free',
    this.selfDestructedAt,
    this.gracePeriodExpiresAt,
  });

  bool get isInGracePeriod {
    if (isPremium) return false;
    if (selfDestructedAt == null || gracePeriodExpiresAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < gracePeriodExpiresAt!;
  }

  bool get isGracePeriodExpired {
    if (isPremium) return false;
    if (selfDestructedAt == null || gracePeriodExpiresAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= gracePeriodExpiresAt!;
  }

  int get remainingGracePeriodMillis {
    if (gracePeriodExpiresAt == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = gracePeriodExpiresAt! - now;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'isPremium': isPremium,
      'subscriptionType': subscriptionType,
      'selfDestructedAt': selfDestructedAt,
      'gracePeriodExpiresAt': gracePeriodExpiresAt,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      isPremium: json['isPremium'] ?? false,
      subscriptionType: json['subscriptionType'] ?? 'free',
      selfDestructedAt: json['selfDestructedAt'],
      gracePeriodExpiresAt: json['gracePeriodExpiresAt'],
    );
  }
}
