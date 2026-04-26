import 'bone_prediction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResult {
  final List<String> generatedImageUrls;

  final List<BonePrediction> topPredictions;

  final bool hasAbnormality;
  final double abnormalityConfidence;

  final DateTime generatedAt;

  final String interpretation;

  ScanResult({
    required this.generatedImageUrls,
    required this.topPredictions,
    required this.hasAbnormality,
    required this.abnormalityConfidence,
    required this.generatedAt,
    required this.interpretation,
  });

  Map<String, dynamic> toMap() {
    return {
      'generatedImageUrls': generatedImageUrls,

      'topPredictions': topPredictions.map((p) => p.toMap()).toList(),

      'hasAbnormality': hasAbnormality,

      'abnormalityDetectionConfidence': abnormalityConfidence,

      'generatedAt': Timestamp.fromDate(generatedAt),

      'interpretation': interpretation,
    };
  }

  // READ FROM FIRESTORE
  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      generatedImageUrls: List<String>.from(map['generatedImageUrls'] ?? []),

      topPredictions:
          (map['topPredictions'] as List<dynamic>?)
              ?.map((e) => BonePrediction.fromMap(e))
              .toList() ??
          [],

      hasAbnormality: map['hasAbnormality'] ?? false,

      abnormalityConfidence: (map['abnormalityDetectionConfidence'] as num)
          .toDouble(),

      generatedAt: (map['generatedAt'] as Timestamp).toDate(),

      interpretation: map['interpretation'],
    );
  }

  ScanResult copyWith({
    List<String>? generatedImageUrls,
    bool? hasAbnormality,
    double? abnormalityDetectionConfidence,
    List<BonePrediction>? topPredictions,
    DateTime? generatedAt,
    String? interpretation,
  }) {
    return ScanResult(
      generatedImageUrls: generatedImageUrls ?? this.generatedImageUrls,
      hasAbnormality: hasAbnormality ?? this.hasAbnormality,
      abnormalityConfidence:
          abnormalityDetectionConfidence ?? this.abnormalityConfidence,
      topPredictions: topPredictions ?? this.topPredictions,
      generatedAt: generatedAt ?? this.generatedAt,
      interpretation: interpretation ?? this.interpretation,
    );
  }
}
