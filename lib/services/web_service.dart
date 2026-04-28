import 'package:cloud_firestore/cloud_firestore.dart';

const String DOCTOR_COLLECTION_REF = "users";

class WebService {
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> fetchByShortId(String shortId) async {
    final linkDoc = await _firestore
        .collection('shared_links')
        .doc(shortId)
        .get();

    if (!linkDoc.exists) throw Exception("Invalid or expired link.");

    final linkData = linkDoc.data()!;

    // Expiry check
    final expiry = (linkData['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiry)) throw Exception("Link expired.");

    return await _internalFetch(
      doctorId: linkData['docId'],
      patientId: linkData['pid'],
      scanId: linkData['scanId'],
      token: linkData['token'],
    );
  }

  Future<Map<String, dynamic>?> _internalFetch({
    required String doctorId,
    required String patientId,
    required String scanId,
    required String token,
  }) async {
    // 1. Fetch scan
    final scanDoc = await _firestore
        .collection('users')
        .doc(doctorId)
        .collection('patients')
        .doc(patientId)
        .collection('scans')
        .doc(scanId)
        .get();

    if (!scanDoc.exists) throw Exception("Record not found.");

    final scanData = scanDoc.data() as Map<String, dynamic>;

    // Token validation
    if (scanData['shareToken'] != token) {
      throw Exception("Security token mismatch.");
    }

    // Fetch doctor profile
    final doctorDoc = await _firestore.collection('users').doc(doctorId).get();

    final doctorData = doctorDoc.exists ? (doctorDoc.data() ?? {}) : {};
    final first = (doctorData['firstName'] ?? '').toString();
    final last = (doctorData['lastName'] ?? '').toString();
    final fullName = "$first $last".trim();
    final initials =
        "${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}"
            .toUpperCase();
    // Merge everything + add doctorId/patientId/scanId
    return {
      'doctorId': doctorId,
      'doctorFullName': fullName,
      'doctorInitials': initials,
      'patientId': patientId,
      'scanId': scanId,

      ...scanData,
    };
  }
}
