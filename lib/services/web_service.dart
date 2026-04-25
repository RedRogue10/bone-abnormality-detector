import 'package:cloud_firestore/cloud_firestore.dart';

const String DOCTOR_COLLECTION_REF = "users";

class WebService {
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> fetchScanData(
    String token,
    String patientId,
    String scanId,
  ) async {
    // if (useMockData) {
    //   await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    //   return {
    //     'imageUrl':
    //         'https://picsum.photos/seed/xray/600/800', // A placeholder X-ray
    //     'interpretation':
    //         'AI Analysis: No major abnormalities detected in the distal radius. Recommended: Clinical correlation by a specialist.',
    //     'shareExpiresAt': Timestamp.fromDate(
    //       DateTime.now().add(const Duration(days: 3)),
    //     ),
    //     'createdAt': Timestamp.now(),
    //   };
    // }

    final doc = await _firestore
        .collection('users')
        .doc('Lh2WuYR8UjUAOWOUXRh20mfAFLJ2')
        .collection('patients')
        .doc(patientId)
        .collection('scans')
        .doc(scanId)
        .get();

    if (!doc.exists) throw Exception("Record not found.");

    final data = doc.data() as Map<String, dynamic>;
    print("URL Token: $token");
    print("DB Token: ${data['shareToken']}");

    // Check if tokens match
    if (data['shareToken'] != token) throw Exception("Invalid security token.");

    // Check token expiry
    final expiry = (data['shareExpiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiry)) throw Exception("Link has expired.");

    return data;
  }
}
