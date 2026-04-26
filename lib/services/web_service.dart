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

  // Fetch actual data using hidden ids
  Future<Map<String, dynamic>?> _internalFetch({
    required String doctorId,
    required String patientId,
    required String scanId,
    required String token,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(doctorId)
        .collection('patients')
        .doc(patientId)
        .collection('scans')
        .doc(scanId)
        .get();

    if (!doc.exists) throw Exception("Record not found.");

    final data = doc.data() as Map<String, dynamic>;

    if (data['shareToken'] != token) {
      throw Exception("Security token mismatch.");
    }

    return data;
  }
}
