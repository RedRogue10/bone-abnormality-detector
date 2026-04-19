import 'scan_result.dart';

class XrayScan {
  final String id;
  final String imageUrl;
  final DateTime createdAt;
  final String analysisStatus; //"pending", "processing", "completed", "failed"
  final ScanResult? result;

  XrayScan({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.analysisStatus,
    required this.result,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'result': result,
    };
  }
}
