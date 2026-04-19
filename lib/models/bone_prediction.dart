class BonePrediction {
  final String bonePart;
  final double confidence;

  BonePrediction({required this.bonePart, required this.confidence});

  Map<String, dynamic> toMap() {
    return {'bonePart': bonePart, 'confidence': confidence};
  }

  factory BonePrediction.fromMap(Map<String, dynamic> map) {
    return BonePrediction(
      bonePart: map['bonePart'] ?? '',
      confidence: (map['confidence'] as num).toDouble(),
    );
  }
}
