import 'bone_prediction.dart';

class ScanResult {
  final String id;
  final String generatedImageUrl;

  final List<BonePrediction> topPredictions;

  final bool hasAbnormality;
  final double abnormalityConfidence;

  final DateTime generatedAt;

  ScanResult({
    required this.id,
    required this.generatedImageUrl,
    required this.topPredictions,
    required this.hasAbnormality,
    required this.abnormalityConfidence,
    required this.generatedAt,
  });
}
