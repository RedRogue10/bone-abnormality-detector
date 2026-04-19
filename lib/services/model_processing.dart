import 'dart:io';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../models/bone_prediction.dart';
import '../models/scan_result.dart';

// Must match the output label order of the bone-part classifier.
enum BonePart {
  elbow,
  finger,
  forearm,
  hand,
  humerus,
  shoulder,
  wrist;

  String get assetPath => 'flutter_assets/assets/models/$name.tflite';
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class ModelProcessor {
  static const String _classifierPath = 'flutter_assets/assets/models/bone_classifier.tflite';

  YOLO? _classifier;
  YOLO? _abnormalityModel;
  BonePart? _loadedBonePart;

  // Initialization 

  Future<void> initClassifier() async {
    _classifier = YOLO(modelPath: _classifierPath, task: YOLOTask.classify);
    await _classifier!.loadModel();
  }

  Future<void> _loadAbnormalityModel(BonePart part) async {
    if (_loadedBonePart == part && _abnormalityModel != null) return;
    _abnormalityModel = YOLO(modelPath: part.assetPath, task: YOLOTask.classify);
    await _abnormalityModel!.loadModel();
    _loadedBonePart = part;
  }

  // Stage 1 – bone-part classification

  /// Runs the single classifier across all 7 bone parts and returns predictions
  Future<List<BonePrediction>> classifyBonePart(File imageFile) async {
    if (_classifier == null) await initClassifier();
    final imageBytes = await imageFile.readAsBytes();
    final results = await _classifier!.predict(imageBytes);

    final raw = (results['classifications'] as List<dynamic>?) ?? [];
    final predictions =
        raw
            .map<BonePrediction>(
              (c) => BonePrediction(
                bonePart: (c['label'] as String?) ?? '',
                confidence: (c['confidence'] as num).toDouble(),
              ),
            )
            .toList();

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions;
  }

  // Stage 2 – bone-specific abnormality detection 

  Future<Map<String, dynamic>> detectAbnormality(
    File imageFile,
    BonePart part,
  ) async {
    await _loadAbnormalityModel(part);
    final imageBytes = await imageFile.readAsBytes();
    final results = await _abnormalityModel!.predict(imageBytes);

    final raw = (results['classifications'] as List<dynamic>?) ?? [];

    // Labels expected from MURA-trained model: 'positive' (abnormal) / 'negative' (normal)
    final abnormal = raw.firstWhere(
      (c) {
        final label = (c['label'] as String).toLowerCase();
        return label.contains('positive') || label.contains('abnormal');
      },
      orElse: () => {'label': 'negative', 'confidence': 0.0},
    );

    final confidence = (abnormal['confidence'] as num).toDouble();
    return {
      'hasAbnormality': confidence >= 0.5,
      'confidence': confidence,
    };
  }


  Future<ScanResult> analyzeImage(File imageFile) async {
    // Stage 1
    final predictions = await classifyBonePart(imageFile);

    final topLabel =
        predictions.isNotEmpty ? predictions.first.bonePart.toLowerCase() : '';
    final bonePart = BonePart.values.firstWhere(
      (b) => topLabel.contains(b.name),
      orElse: () => BonePart.wrist, // fallback; should not happen in practice
    );

    // Stage 2
    final abnormality = await detectAbnormality(imageFile, bonePart);

    return ScanResult(
      generatedImageUrls: [], // filled later by DatabaseService.attachAIResultToScan
      topPredictions: predictions.take(3).toList(),
      hasAbnormality: abnormality['hasAbnormality'] as bool,
      abnormalityConfidence: abnormality['confidence'] as double,
      generatedAt: DateTime.now(),
    );
  }
}
