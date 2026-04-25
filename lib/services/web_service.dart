// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import '../models/patient.dart';
// import '../models/xray_scan.dart';

// const String DOCTOR_COLLECTION_REF = "users";

// class WebService {
//   final _firestore = FirebaseFirestore.instance;

//   CollectionReference<Patient> get _getPatientCollectionRef {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       throw Exception('No user logged in');
//     }
//     return _firestore
//         .collection(DOCTOR_COLLECTION_REF)
//         .doc(user.uid)
//         .collection('patients')
//         .withConverter<Patient>(
//           fromFirestore: (snapshots, _) =>
//               Patient.fromMap(snapshots.data()!, snapshots.id),
//           toFirestore: (patient, _) => patient.toMap(),
//         );
//   }

//   Future<XrayScan?> _verifyAndFetch(
//     String patientId,
//     String scanId,
//     String token,
//   ) async {
//     final doc = await FirebaseFirestore.instance
//         .collection('patients')
//         .doc(patientId)
//         .collection('scans')
//         .doc(scanId)
//         .get();

//     if (!doc.exists) return null;

//     final data = doc.data()!;
//     final DateTime expiry = (data['shareExpiresAt'] as Timestamp).toDate();
//     final String storedToken = data['shareToken'];

//     // VALIDATION: Check token and check if current time is before expiry
//     if (storedToken == token && DateTime.now().isBefore(expiry)) {
//       return XrayScan.fromMap(data, doc.id);
//     }
//     return null;
//   }
// }
