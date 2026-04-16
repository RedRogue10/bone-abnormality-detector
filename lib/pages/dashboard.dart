import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'patient_list.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color accentOrange = Color(0xFFD19527);
  static const Color grey = Color(0xFF808080);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      // Appbar
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: white),
          onPressed: () {},
        ),
        title: Text(
          'DASHBOARD',
          style: GoogleFonts.oswald(color: white, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: white),
            onPressed: () {},
          ),
        ],
      ),
      // Body
      body: Column(
        children: [
          // scrollable content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SCAN AN IMAGE
                  _buildScanButton(context),
                  const SizedBox(height: 16),

                  // PATIENTS  |  RECENT SCANS
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
                            // TODO: Navigator.push → RecentScansPage
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent →
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Navigator.push → full recent list
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

                  // Patient list
                  Expanded(
                    child: ListView.separated(
                      itemCount: recentPatients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildPatientCard(context, recentPatients[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Camera Bar
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // SCAN AN IMAGE button
  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigator.push → ScanPage
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

  // Patient list card
  Widget _buildPatientCard(BuildContext context, Map<String, dynamic> patient) {
    final Color avatarColor = patient['color'] as Color;
    final String name = patient['name'] as String;
    final String details = patient['details'] as String;

    return GestureDetector(
      onTap: () {
        // TODO: Navigator.push → PatientDetailPage
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarColor,
              child: Text(
                'JC',
                style: GoogleFonts.poppins(
                  color: white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: primaryBlue, // 1A73E9
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: grey),
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
                // TODO: Navigator.push → ScanPage
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
