import 'dart:developer';
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

  Future<void> _initClassifier() async {
    _classifier = YOLO(modelPath: _classifierPath, task: YOLOTask.classify, useGpu: true, useMultiInstance: true);
    await _classifier!.loadModel();
  }

  Future<void> _initAbnormalityModel(BonePart part) async {
    if (_loadedBonePart == part && _abnormalityModel != null) return;
    _abnormalityModel = YOLO(modelPath: part.assetPath, task: YOLOTask.classify, useGpu: true, useMultiInstance: true);
    await _abnormalityModel!.loadModel();
    _loadedBonePart = part;
  }

  // ── Stage 1 – bone-part classification ──────────────────────────────────

  Future<List<BonePrediction>> classifyBonePart(File imageFile) async {
    if (_classifier == null) await _initClassifier();
    final imageBytes = await imageFile.readAsBytes();
    final results = await _classifier!.predict(imageBytes);

    final raw = (results['detections'] as List<dynamic>?) ?? [];
    final predictions = raw.map<BonePrediction>((d) {
      final idx = (d['classIndex'] as num).toInt();
      final bonePart = idx < BonePart.values.length
          ? BonePart.values[idx].name
          : 'unknown';
      return BonePrediction(
        bonePart: bonePart,
        confidence: (d['confidence'] as num).toDouble(),
      );
    }).toList();

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions;
  }

  // ── Stage 2 – bone-specific abnormality classification ───────────────────

  Future<Map<String, dynamic>> detectAbnormality(
    File imageFile,
    BonePart part,
  ) async {
    await _initAbnormalityModel(part);
    final imageBytes = await imageFile.readAsBytes();
    final results = await _abnormalityModel!.predict(imageBytes);

    final raw = (results['detections'] as List<dynamic>?) ?? [];
    if (raw.isEmpty) return {'hasAbnormality': false, 'confidence': 0.0};

    final top = raw.first;
    final classIndex = (top['classIndex'] as num).toInt();
    final confidence = (top['confidence'] as num).toDouble();

    // Always store P(abnormal): if class 0 (normal) won, abnormality probability = 1 - P(normal)
    return {
      'hasAbnormality': classIndex == 1,
      'confidence': classIndex == 1 ? confidence : 1.0 - confidence,
    };
  }

  // ── Full pipeline ────────────────────────────────────────────────────────

  Future<ScanResult> analyzeImage(File imageFile) async {
    final predictions = await classifyBonePart(imageFile);

    final topLabel =
        predictions.isNotEmpty ? predictions.first.bonePart.toLowerCase() : '';
    final bonePart = BonePart.values.firstWhere(
      (b) => topLabel.contains(b.name),
      orElse: () => BonePart.wrist,
    );

    final abnormality = await detectAbnormality(imageFile, bonePart);

    log('[Classifier] bone=${predictions.isNotEmpty ? predictions.first.bonePart : "none"} conf=${predictions.isNotEmpty ? predictions.first.confidence : 0.0}');
    log('[Abnormality] hasAbnormality=${abnormality['hasAbnormality']} conf=${abnormality['confidence']}');

    return ScanResult(
      generatedImageUrls: [],
      topPredictions: predictions.take(3).toList(),
      hasAbnormality: abnormality['hasAbnormality'] as bool,
      abnormalityConfidence: abnormality['confidence'] as double,
      generatedAt: DateTime.now(),
    );
  }
}
