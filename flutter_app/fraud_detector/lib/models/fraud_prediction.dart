/// Model representing fraud prediction response from API
/// Matches the API response format exactly
class FraudPrediction {
  final bool fraud;
  final double riskScore;
  final String? explanation;

  FraudPrediction({
    required this.fraud,
    required this.riskScore,
    this.explanation,
  });

  /// Create from JSON API response
  factory FraudPrediction.fromJson(Map<String, dynamic> json) {
    return FraudPrediction(
      fraud: json['fraud'] as bool,
      riskScore: (json['risk_score'] as num).toDouble(),
      explanation: json['explanation'] as String?,
    );
  }
}


