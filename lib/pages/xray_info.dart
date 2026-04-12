import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class XrayInfo extends StatefulWidget {
  final int xrayId;

  const XrayInfo({super.key, required this.xrayId});

  @override
  State<XrayInfo> createState() => _XrayInfoState();
}

class _XrayInfoState extends State<XrayInfo> {
  // Colors
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color altBlue = Color(0xFF276ED1);
  static const Color darkRed = Color(0xFF450B0B);
  static const Color green = Color(0xFF0B4518);
  static const Color orange = Color(0xFFD16227);
  static const Color gold = Color(0xFFD19527);
  static const Color purple = Color(0xFF463883);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;
  static const Color bgGrey = Color(0xFFF0F0F0);

  bool xrayAbnormal = true; // Placeholder for actual abnormality status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: xrayAbnormal ? darkRed : green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Xray Information',
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
      body: const Center(child: Text('Details for X-ray ')),
    );
  }
}
