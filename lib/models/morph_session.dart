class MorphSessionReservation {
  const MorphSessionReservation({
    required this.sessionId,
    required this.reservedCredits,
    required this.balance,
  });

  final String sessionId;
  final int reservedCredits;
  final int balance;

  factory MorphSessionReservation.fromJson(Map<String, dynamic> json) {
    return MorphSessionReservation(
      sessionId: json['session_id'] as String,
      reservedCredits: json['reserved_credits'] as int,
      balance: json['balance'] as int,
    );
  }
}

class DecartClientToken {
  const DecartClientToken({
    required this.apiKey,
    required this.expiresAt,
    required this.model,
  });

  final String apiKey;
  final DateTime expiresAt;
  final String model;

  factory DecartClientToken.fromJson(Map<String, dynamic> json) {
    return DecartClientToken(
      apiKey: json['apiKey'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      model: json['model'] as String,
    );
  }
}
