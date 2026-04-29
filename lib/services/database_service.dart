import 'dart:io';

// PACKAGES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// MODELS
import '../models/user.dart';
import '../models/patient.dart';
import '../models/xray_scan.dart';
import '../models/scan_result.dart';
import '../models/interpretation_preset.dart';

const String DOCTOR_COLLECTION_REF = "users";

class DatabaseService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Patient> get _getPatientCollectionRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return _firestore
        .collection(DOCTOR_COLLECTION_REF)
        .doc(user.uid)
        .collection('patients')
        .withConverter<Patient>(
          fromFirestore: (snapshots, _) =>
              Patient.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (patient, _) => patient.toMap(),
        );
  }

  Future<UserModel> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No user logged in');
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      throw Exception('User not found');
    }

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'firstName': firstName,
      'lastName': lastName,
      'updatedAt': Timestamp.now(),
    });
  }

  // ------------------- PATIENTS ----------------------
  Future<void> addPatient(Patient patient) async {
    try {
      await _getPatientCollectionRef.add(patient);
    } catch (e) {
      throw Exception('Failed to add patient: $e');
    }
  }

  Future<Patient> getPatientById(String patientId) async {
    try {
      DocumentSnapshot<Patient> snapshot = await _getPatientCollectionRef
          .doc(patientId)
          .get();
      if (!snapshot.exists) {
        throw Exception('Patient not found');
      }
      return snapshot.data()!;
    } catch (e) {
      throw Exception('Failed to fetch patient: $e');
    }
  }

  Future<List<Patient>> getPatients() async {
    try {
      QuerySnapshot<Patient> snapshot = await _getPatientCollectionRef.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch patients: $e');
    }
  }

  Stream<List<Patient>> getPatientsStream() {
    return _getPatientCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> updatePatient(Patient patient) async {
    try {
      await _getPatientCollectionRef.doc(patient.id).update(patient.toMap());
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  Future<void> deletePatient(String patientId) async {
    try {
      await _getPatientCollectionRef.doc(patientId).delete();
    } catch (e) {
      throw Exception('Failed to delete patient: $e');
    }
  }

  // ------------------- XRAY SCAN helping methods ----------------------
  Future<String> createXrayScan({required String patientId}) async {
    final patientDoc = await _getPatientCollectionRef.doc(patientId);

    final patientSnapshot = await patientDoc.get();

    String patientFullName = "Unknown Patient";

    if (patientSnapshot.exists) {
      final patientData = patientSnapshot.data();

      if (patientData != null) {
        patientFullName = patientData.fullName;
      }
    }

    final scanRef = _getPatientCollectionRef
        .doc(patientId)
        .collection('scans')
        .doc();

    await scanRef.set({
      'patientName': patientFullName,
      'imageUrl': '',
      'createdAt': Timestamp.now(),
      'analysisStatus': 'pending',
      'result': null,
    });

    return scanRef.id;
  }

  // Update result after AI generates it
  Future<void> updateXrayScanResult({
    required String patientId,
    required String scanId,
    required ScanResult result,
  }) async {
    await _getPatientCollectionRef
        .doc(patientId)
        .collection('scans')
        .doc(scanId)
        .update({'result': result.toMap(), 'analysisStatus': 'completed'});
  }

  // Update result interpretation
  Future<void> updateInterpretation({
    required String patientId,
    required String scanId,
    required String interpretation,
  }) async {
    try {
      await _getPatientCollectionRef
          .doc(patientId)
          .collection('scans')
          .doc(scanId)
          .update({'result.interpretation': interpretation});
    } catch (e) {
      print('Error updating interpretation: $e');
      rethrow;
    }
  }

  Future<XrayScan> getXrayScanById(String patientId, String scanId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _getPatientCollectionRef
              .doc(patientId)
              .collection('scans')
              .doc(scanId)
              .get();
      if (!snapshot.exists) {
        throw Exception('Scan not found');
      }
      return XrayScan.fromMap(snapshot.data()!, snapshot.id);
    } catch (e) {
      throw Exception('Failed to fetch x-ray scan: $e');
    }
  }

  Future<void> deleteXrayScan(String patientId, String scanId) async {
    try {
      await _getPatientCollectionRef
          .doc(patientId)
          .collection('scans')
          .doc(scanId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete x-ray scan: $e');
    }
  }

  Future<String> uploadScanImage({
    required String patientId,
    required String scanId,
    required File imageFile,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/${FirebaseAuth.instance.currentUser!.uid}/patients/$patientId/scans/$scanId/image.jpg',
      );
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload scan image: $e');
    }
  }

  Future<void> attachImageToScan({
    required String patientId,
    required String scanId,
    required String imageUrl,
  }) async {
    try {
      await _getPatientCollectionRef
          .doc(patientId)
          .collection('scans')
          .doc(scanId)
          .update({'imageUrl': imageUrl, 'analysisStatus': 'processing'});
    } catch (e) {
      throw Exception('Failed to attach image to scan: $e');
    }
  }

  // Upload EigenCAM image to Firestore
  Future<List<String>> uploadResultImages({
    required String patientId,
    required String scanId,
    required List<File> images,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;

    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final ref = FirebaseStorage.instance.ref().child(
        'users/${user.uid}/patients/$patientId/scans/$scanId/results/result_$i.jpg',
      );

      await ref.putFile(images[i]);

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // ------------------- RESULTS ----------------------
  Future<ScanResult> getLatestScanResult(String patientId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await _getPatientCollectionRef
              .doc(patientId)
              .collection('scans')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
      if (snapshot.docs.isEmpty) {
        throw Exception('No scans found for this patient');
      }
      Map<String, dynamic>? data = snapshot.docs.first.data();
      if (data['result'] == null) {
        throw Exception('Result not found');
      }
      return ScanResult.fromMap(data['result']);
    } catch (e) {
      throw Exception('Failed to fetch latest scan result: $e');
    }
  }

  Future<ScanResult> getScanResult(String patientId, String scanId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _getPatientCollectionRef
              .doc(patientId)
              .collection('scans')
              .doc(scanId)
              .get();
      if (!snapshot.exists) {
        throw Exception('Scan not found');
      }
      Map<String, dynamic>? data = snapshot.data();
      if (data == null || data['result'] == null) {
        throw Exception('Result not found');
      }
      return ScanResult.fromMap(data['result']);
    } catch (e) {
      throw Exception('Failed to fetch scan result: $e');
    }
  }

  Stream<List<XrayScan>> getPatientScansStream(String patientId) {
    return _getPatientCollectionRef
        .doc(patientId)
        .collection('scans')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => XrayScan.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<bool> hasXrayHistory(String patientId) async {
    final snapshot = await _getPatientCollectionRef
        .doc(patientId)
        .collection('scans')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Stream<int> xrayCountStream(String patientId) {
    return _getPatientCollectionRef
        .doc(patientId)
        .collection('scans')
        .snapshots()
        .map((s) => s.docs.length);
  }

  // -------------------- RETRIEVE SCANS ----------------------------
  Future<void> logRecentScanView({
    required String scanId,
    required String patientId,
    required String patientName,
    required String imageUrl,
    required DateTime scanDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    await _firestore
        .collection(DOCTOR_COLLECTION_REF)
        .doc(user.uid)
        .collection('recent_views')
        .doc(scanId)
        .set({
          'scanId': scanId,
          'patientId': patientId,
          'patientName': patientName,
          'imageUrl': imageUrl,
          'scanDate': Timestamp.fromDate(scanDate),
          'lastAccessed': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getRecentlyAccessedScansStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return FirebaseFirestore.instance
        .collection(DOCTOR_COLLECTION_REF)
        .doc(user.uid)
        .collection('recent_views')
        .orderBy('lastAccessed', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> fetchAllScans() async {
    List<Map<String, dynamic>> allDoctorScans = [];

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final patientsSnap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('patients')
        .get();

    for (var patientDoc in patientsSnap.docs) {
      final patientId = patientDoc.id;
      final scansSnap = await patientDoc.reference.collection('scans').get();

      for (var scanDoc in scansSnap.docs) {
        final scanId = scanDoc.id;
        final data = scanDoc.data();
        allDoctorScans.add({
          'name': data['patientName'] ?? 'Unknown Patient',
          'date': (data['createdAt'] as Timestamp).toDate(),
          'imageUrl': data['imageUrl'],
          'patientId': patientId,
          'scanId': scanId,
        });
      }
    }
    allDoctorScans.sort((a, b) => b['date'].compareTo(a['date']));
    return allDoctorScans;
  }

  // -------------------- FULL PIEPLINES TO CALL ----------------------
  Future<String> createFullXrayScan({
    required String patientId,
    required File imageFile,
    ScanResult? result, // if AI result is there na
  }) async {
    // Create scan document
    final scanId = await createXrayScan(patientId: patientId);

    // Upload image to Storage
    final imageUrl = await uploadScanImage(
      patientId: patientId,
      scanId: scanId,
      imageFile: imageFile,
    );

    // Save image URL
    await attachImageToScan(
      patientId: patientId,
      scanId: scanId,
      imageUrl: imageUrl,
    );
    return scanId;
  }

  Future<void> attachAIResultToScan({
    required String patientId,
    required String scanId,
    required List<File> generatedImages,
    required ScanResult resultData,
  }) async {
    // upload AI-generated images
    final imageUrls = await uploadResultImages(
      patientId: patientId,
      scanId: scanId,
      images: generatedImages,
    );

    // add URLs into result
    final updatedResult = resultData.copyWith(generatedImageUrls: imageUrls);

    // save to Firestore
    updateXrayScanResult(
      patientId: patientId,
      scanId: scanId,
      result: updatedResult,
    );
  }

  // ── Interpretation Presets ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _presetsRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore
        .collection(DOCTOR_COLLECTION_REF)
        .doc(uid)
        .collection('interpretation_presets');
  }

  Future<List<InterpretationPreset>> getPresets() async {
    final snap = await _presetsRef.orderBy('createdAt').get();
    return snap.docs
        .map((d) => InterpretationPreset.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> addPreset(String title, String body) async {
    await _presetsRef.add(InterpretationPreset(
      id:        '',
      title:     title,
      body:      body,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> updatePreset(String id, String title, String body) async {
    await _presetsRef.doc(id).update({'title': title, 'body': body});
  }

  Future<void> deletePreset(String id) async {
    await _presetsRef.doc(id).delete();
  }
}
