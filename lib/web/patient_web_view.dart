import 'package:flutter/material.dart';
import '../services/web_service.dart';

class PatientWebView extends StatelessWidget {
  final String shortId;

  const PatientWebView({super.key, required this.shortId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("X-Ray Scan Results"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        // Gets the scan
        future: WebService().fetchByShortId(shortId),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Change this line in your catch/error block
          if (snapshot.hasError) {
            print(
              "DEBUG ERROR: ${snapshot.error}",
            ); // Check F12 console for this!
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 2. Error State (Expired link, wrong token, or permission denied)
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_clock, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Access Denied",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "This link may have expired (valid for 3 days) or the security token is invalid. Please contact your clinic for a new link.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          final interpretation = data['result'] != null
              ? data['result']['interpretation'] ??
                    "No interpretation available."
              : "Analysis pending.";

          // 3. Success State - The Result Dashboard
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Secure Medical Record",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    "Scan ID: placedolder",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        child: Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Interpretation Section
                    const Text(
                      "Doctor's Interpretation",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(width: 4, color: Colors.blueAccent),
                        ),
                      ),
                      child: Text(
                        interpretation,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Expiry Warning
                    Center(
                      child: Text(
                        "This link will expire on: ${data['shareExpiresAt'].toDate().toString().split(' ')[0]}",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
