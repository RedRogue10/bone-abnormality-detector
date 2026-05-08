import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bone_abnormality_detector/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'pages/dashboard.dart';
import 'pages/camera_capture.dart';
import 'pages/login.dart';
import 'web/patient_web_view.dart';

import 'services/database_service.dart';

import 'models/bone_prediction.dart';
import 'models/scan_result.dart';

import 'url_strategy_noop.dart' if (dart.library.html) 'url_strategy_web.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final GoRouter _router = GoRouter(
  observers: [routeObserver],
  initialLocation: '/login',

  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final path = state.uri.path;
    print("REDIRECTIONS: Target is ${state.uri.path}");
    if (path == '/') return '/login';
    // 1. ALWAYS allow the public route first, no matter what
    if (path == '/view-results') {
      return null;
    }

    final isLoggingIn = path == '/login';

    if (!loggedIn && !isLoggingIn) {
      // Not logged in and trying to access dashboard --> Go to login.
      return '/login';
    }

    if (loggedIn && isLoggingIn) {
      return '/dashboard';
    }

    return null;
  },

  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/login'),

    // Login
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

    // Dashboard
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // X-ray view page (EMAIL LINK TARGET)
    GoRoute(
      path: '/view-results',
      builder: (context, state) {
        final v = state.uri.queryParameters['v']!;

        print("Returning Web View");
        return PatientWebView(shortId: v);
      },
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  print("Firebase initialized successfully!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'X-ray Reader | Bone Abnormality Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E9)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraCapturePage(patientId: '1'),
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
            ],
          ),
        ),
      ),
    );
  }
}
