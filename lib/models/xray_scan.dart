import 'scan_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class XrayScan {
  final String id;
  final String patientName;
  final String imageUrl;
  final DateTime createdAt;
  final String analysisStatus; //"pending", "processing", "completed", "failed"
  final ScanResult? result;

  XrayScan({
    required this.id,
    required this.patientName,
    required this.imageUrl,
    required this.createdAt,
    required this.analysisStatus,
    required this.result,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'analysisStatus': analysisStatus,
      'result': result?.toMap(),
    };
  }

  // READ FROM FIRESTORE
  factory XrayScan.fromMap(
    Map<String, dynamic> map,
    String id, {
    String? patientIdFromPath,
  }) {
    return XrayScan(
      id: id,
      patientName: map['patientName'],
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      analysisStatus: map['analysisStatus'],
      result: map['result'] != null ? ScanResult.fromMap(map['result']) : null,
    );
  }
}
