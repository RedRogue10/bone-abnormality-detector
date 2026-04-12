import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bone_abnormality_detector/pages/xray_info.dart';

class XrayHistory extends StatefulWidget {
  final int patientId;

  const XrayHistory({super.key, required this.patientId});

  @override
  State<XrayHistory> createState() => _XrayHistoryState();
}

class _XrayHistoryState extends State<XrayHistory> {
  // Colors
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;

  final List<Map<String, String>> xrayItems = [
    {
      'name': 'Humerus X-ray',
      'date': 'Apr 10, 2026',
      'id': 'Scan #001',
      'image': 'assets/images/xray_background.png',
    },
    {
      'name': 'Elbow X-ray',
      'date': 'Mar 22, 2026',
      'id': 'Scan #002',
      'image': 'assets/images/xray_background.png',
    },
    {
      'name': 'Finger X-ray',
      'date': 'Feb 15, 2026',
      'id': 'Scan #003',
      'image': 'assets/images/xray_background.png',
    },
    {
      'name': 'Humerus X-ray',
      'date': 'Apr 10, 2026',
      'id': 'Scan #001',
      'image': 'assets/images/xray_background.png',
    },
    {
      'name': 'Elbow X-ray',
      'date': 'Mar 22, 2026',
      'id': 'Scan #002',
      'image': 'assets/images/xray_background.png',
    },
  ];

  Widget _buildXrayButton(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 120,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      XrayInfo(xrayId: int.parse(item['id']!.split('#')[1])),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.only(left: 0, right: 16),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Image.asset(
                      item['image'] ?? '',
                      width: 120,
                      height: double.infinity, // Full height now
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['date'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['id'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'X-ray History',
          style: GoogleFonts.oswald(
            color: white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),

            child: IconButton(
              icon: const Icon(Icons.person_rounded, color: white, size: 22),
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) =>
                //         Null, // Replace with Doctor's profile() when implemented,
                //   ),
                // );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(color: darkNavy),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Juan de la Cruz Jr.: ${widget.patientId}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            color: white,
                            fontSize: 20,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '33 years old, Male',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            color: primaryBlue,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...xrayItems.map(_buildXrayButton).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
