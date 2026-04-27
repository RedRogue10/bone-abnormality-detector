import 'package:bone_abnormality_detector/pages/retrieve_scans.dart';
import 'package:flutter/material.dart';
import 'package:bone_abnormality_detector/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// SERVICES
import 'package:bone_abnormality_detector/services/auth.dart';
import 'package:bone_abnormality_detector/services/database_service.dart';

// PAGES
import 'patient_list.dart';
import 'info_screen.dart';
import '../pages/doctor_page.dart';
import '../pages/camera_capture.dart';
import '../pages/xray_result.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? user = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;

  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white = Colors.white;
  static const Color cameraRing = Color(0xFFB8D8D8);
  static const Color cameraIcon = Color(0xFF001F54);

  final List<Map<String, dynamic>> recentPatients = const [
    {
      'name': 'Juan de la Cruz Jr.',
      'details': '33 years, Male',
      'color': Color(0xFFD19527),
    },
    {
      'name': 'Juan de la Cruz Jr.',
      'details': '33 years, Male',
      'color': Color(0xFFD19527),
    },
    {
      'name': 'Juan de la Cruz Jr.',
      'details': '33 years, Male',
      'color': Color(0xFFD19527),
    },
  ];

  @override
  void initState() {
    super.initState();
    _syncEmail();
  }

  Future<void> _syncEmail() async {
    await Auth().syncEmailIfChanged();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_circle_outlined, color: white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DoctorPage(userId: user!.uid)),
            );
          },
        ),
        title: Text(
          'DASHBOARD',
          style: GoogleFonts.oswald(color: white, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InfoScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TEMPORARY BUTTON
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      },
                      child: const Text("Testing buttons"),
                    ),

                    // SCAN AN IMAGE
                    _buildScanButton(context),
                    const SizedBox(height: 16),

                    // PATIENTS | RECENT SCANS
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridButton(
                            icon: Icons.person_outline,
                            label: 'PATIENTS',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PatientListPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGridButton(
                            icon: Icons.document_scanner_outlined,
                            label: 'RECENT SCANS',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllScansPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AllScansPage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        splashColor: primaryBlue.withOpacity(0.15),
                        highlightColor: primaryBlue.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Recent',
                                style: GoogleFonts.poppins(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                  decorationColor: primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                color: primaryBlue,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 300, // Fixed height for the list
                      child: StreamBuilder<QuerySnapshot>(
                        stream: DatabaseService()
                            .getRecentlyAccessedScansStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'No Recently Accessed Scans',
                                style: GoogleFonts.poppins(
                                  color: Colors.blueGrey,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No recent scans',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final recentScans = snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {
                              'scanId': data['scanId'] ?? '',
                              'patientId': data['patientId'] ?? '',
                              'name': data['patientName'] ?? 'Unknown Patient',
                              'imageUrl': data['imageUrl'] ?? '',
                              'date': data['scanDate'] != null
                                  ? (data['scanDate'] as Timestamp).toDate()
                                  : DateTime.now(),
                              'lastAccessed': data['lastAccessed'] != null
                                  ? (data['lastAccessed'] as Timestamp).toDate()
                                  : DateTime.now(),
                            };
                          }).toList();

                          return ListView.separated(
                            itemCount: recentScans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final scan = recentScans[index];

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    await DatabaseService().logRecentScanView(
                                      scanId: scan['scanId'],
                                      patientId: scan['patientId'],
                                      patientName: scan['name'],
                                      imageUrl: scan['imageUrl'],
                                      scanDate: scan['date'],
                                    );

                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => XrayResultPage(
                                          scanId: scan['scanId'],
                                          patientId: scan['patientId'],
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            scan['imageUrl'],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                        : null,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                scan['name'],
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Scanned: ${_formatDate(scan['date'])}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'Viewed: ${_formatRelativeTime(scan['lastAccessed'])}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildBottomBar(context),
        ],
      ),
    );
  }

  // SCAN AN IMAGE button
  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CameraCapturePage(patientId: '1'),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: darkNavy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: white, size: 40),
            const SizedBox(width: 12),
            Text(
              'SCAN AN IMAGE',
              style: GoogleFonts.oswald(color: white, fontSize: 25),
            ),
          ],
        ),
      ),
    );
  }

  // PATIENTS / RECENT SCANS grid tile
  Widget _buildGridButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: darkNavy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: white, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.oswald(
                color: white,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom dark-navy bar
  Widget _buildBottomBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dark navy bar with camera button
        Container(
          width: double.infinity,
          color: darkNavy,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraCapturePage(patientId: '1'),
                  ),
                );
              },
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cameraRing,
                  border: Border.all(color: cameraRing, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: cameraRing.withOpacity(0.45),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: cameraIcon,
                  size: 35,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
