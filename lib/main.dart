import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bone_abnormality_detector/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'pages/dashboard.dart';
import 'pages/xray_result.dart';
import 'pages/camera_capture.dart';
import 'pages/splash_screen.dart';
import 'pages/reset_password.dart';
import 'pages/login.dart';
import 'web/patient_web_view.dart';

import 'services/database_service.dart';
import 'services/sharing_service.dart';
// import 'services/email_service.dart';

import 'models/bone_prediction.dart';
import 'models/scan_result.dart';

import 'url_strategy_noop.dart' if (dart.library.html) 'url_strategy_web.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',

  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final path = state.uri.path;
    print("REDIRECTIONS: Target is ${state.uri.path}");

    // 1. ALWAYS allow the public route first, no matter what
    if (path == '/view-results') {
      return null;
    }

    // 2. Auth Logic for the Doctor App
    final isLoggingIn = path == '/';

    if (!loggedIn && !isLoggingIn) {
      // Not logged in and trying to access dashboard? Go to login.
      return '/';
    }

    if (loggedIn && isLoggingIn) {
      // Already logged in? Skip the login page.
      return '/dashboard';
    }

    return null;
  },

  routes: [
    // Login
    GoRoute(path: '/', builder: (context, state) => const LoginPage()),

    // Dashboard
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // X-ray view page (EMAIL LINK TARGET)
    GoRoute(
      path: '/view-results',
      builder: (context, state) {
        final scanId = state.uri.queryParameters['scanId']!;
        final token = state.uri.queryParameters['token']!;
        final pid = state.uri.queryParameters['pid']!;

        print("Returning Web View");
        return PatientWebView(scanId: scanId, token: token, patientId: pid);
      },
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Firebase initialized successfully!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bone abnormality detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E9)),
        useMaterial3: true,
      ),
      routerConfig: _router,

      // Uncomment line below to show the login page if no user is logged in
      // home: StreamBuilder<User?>(
      //   stream: FirebaseAuth.instance.authStateChanges(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Scaffold(
      //         body: Center(child: CircularProgressIndicator()),
      //       );
      //     }

      //     if (snapshot.hasData) {
      //       return const DashboardPage();
      //     } else {
      //       return const LoginPage();
      //     }
      //   },
      // ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _testAddScan() async {
    try {
      await DatabaseService().createXrayScan(patientId: 'FmnTTC426eN34O1mhSta');

      print('Test scan added successfully!');
    } catch (e) {
      print('Error adding test scan: $e');
    }
  }

  Future<void> _testStorage() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final testFileRef = storageRef.child('test_upload.txt');

      // Upload file
      await testFileRef.putString('This is a test file for Firebase Storage.');

      // Get the download URL
      final downloadUrl = await testFileRef.getDownloadURL();
      print('File uploaded successfully! Download URL: $downloadUrl');
    } catch (e) {
      print('Error testing Firebase Storage: $e');
    }
  }

  Future<void> _testXrayPipeline() async {
    try {
      // pick image
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      final file = File(picked.path);

      // call pipeline
      final scanId = await DatabaseService().createFullXrayScan(
        patientId: 'FmnTTC426eN34O1mhSta',
        imageFile: file,
      );

      print("Scan created: $scanId");
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<void> _testAIUpdate() async {
    final result = ScanResult(
      generatedImageUrls: ["https://example.com/heatmap.jpg"],
      hasAbnormality: true,
      abnormalityConfidence: 0.91,
      topPredictions: [
        BonePrediction(bonePart: "Hand", confidence: 0.97),
        BonePrediction(bonePart: "Finger", confidence: 0.52),
        BonePrediction(bonePart: "Hand", confidence: 0.97),
      ],
      generatedAt: DateTime.now(),
      interpretation: '',
    );

    await DatabaseService().updateXrayScanResult(
      patientId: 'FmnTTC426eN34O1mhSta',
      scanId: "i1tyaiyv904tPBj6DS1R",
      result: result,
    );

    print("AI Result Updated Successfully");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dashboard button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  String interpretation = 'Doctor\'s interpretation';
                  DatabaseService().updateInterpretation(
                    patientId: 'FmnTTC426eN34O1mhSta',
                    scanId: 'i1tyaiyv904tPBj6DS1R',
                    interpretation: interpretation,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Update Interpretation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Results Page button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const XrayResultPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Go to Results Page',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraCapturePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Go to Camera Page',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _testAddScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Add Xray Scan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _testStorage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Test Storage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _testXrayPipeline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Test Xray Pipeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _testAIUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Test AI Update',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Information Page button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Go to Splash Screen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResetPasswordPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Go to Reset Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  final sharingService = SharingService();

                  // 1. Generate the link
                  String secureLink = await sharingService.generateSecureLink(
                    patientId: 'FmnTTC426eN34O1mhSta',
                    scanId: 'i1tyaiyv904tPBj6DS1R',
                  );
                  // final emailservice = EmailService();

                  // // 2. Pass this link to your email function
                  // await emailservice.sendEmailLink(
                  //   'aimeeraebayle@gmail.com',
                  //   secureLink,
                  // );
                  print('LINK: ${secureLink}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Secure link sent to patient!"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Send Email Link',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
