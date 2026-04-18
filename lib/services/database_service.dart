import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient.dart';

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
}
