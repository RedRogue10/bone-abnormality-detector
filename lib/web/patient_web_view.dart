import 'package:flutter/material.dart';

// import '../models/xray_scan.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class PatientWebView extends StatelessWidget {
  final String scanId, token, patientId;
  const PatientWebView({
    required this.scanId,
    required this.token,
    required this.patientId,
  });

  Future<DocumentSnapshot?> _verifyAndFetch() async {
    final doc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('scans')
        .doc(scanId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;

    // 1. Check token match
    if (data['shareToken'] != token) {
      throw Exception("Invalid link");
    }

    // 2. Check expiry
    final expiry = (data['shareExpiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiry)) {
      throw Exception("Link expired");
    }

    return doc;
  }

  @override
  Widget build(BuildContext context) {
    print("PatientWebView loaded");

    return Scaffold(
      body: FutureBuilder(
        future: _verifyAndFetch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text(snapshot.error.toString())),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Scaffold(
            appBar: AppBar(title: const Text("X-Ray Result")),
            body: Column(
              children: [
                Image.network(data['imageUrl']),
                const SizedBox(height: 20),
                const Text("This result is valid for 3 days only"),
              ],
            ),
          );
        },
      ),
    );
  }
}
