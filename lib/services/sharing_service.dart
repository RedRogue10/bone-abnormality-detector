import 'dart:convert';
import 'dart:math';
// import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bone_abnormality_detector/models/patient.dart';

const String DOCTOR_COLLECTION_REF = "users";

class SharingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Patient> get _getPatientCollectionRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return _db
        .collection(DOCTOR_COLLECTION_REF)
        .doc(user.uid)
        .collection('patients')
        .withConverter<Patient>(
          fromFirestore: (snapshots, _) =>
              Patient.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (patient, _) => patient.toMap(),
        );
  }

  String generateToken() {
    final random = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(random);
  }

  Future<String> generateSecureLink({
    required String doctorId,
    required String patientId,
    required String scanId,
  }) async {
    final doc = await _getPatientCollectionRef
        .doc(patientId)
        .collection('scans')
        .doc(scanId)
        .get();

    print("Exists: ${doc.exists}");
    // 1. Generate a unique token
    final token = generateToken();

    // Generate random ID for link
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final String shortId = List.generate(
      10,
      (i) => chars[Random().nextInt(chars.length)],
    ).join();

    // 2. Set expiry for 3 days from now
    final expiry = DateTime.now().add(const Duration(days: 3));

    // Save to Scan docs
    await FirebaseFirestore.instance
        .collection('users')
        .doc(doctorId)
        .collection('patients')
        .doc(patientId)
        .collection('scans')
        .doc(scanId)
        .update({'shareToken': token, 'shareExpiresAt': expiry});

    // Save to Shared Links
    await FirebaseFirestore.instance
        .collection('shared_links')
        .doc(shortId)
        .set({
          'docId': doctorId,
          'pid': patientId,
          'scanId': scanId,
          'token': token,
          'expiresAt': expiry,
        });

    return "https://xrayreader.online/view-results?v=$shortId";
  }
}
