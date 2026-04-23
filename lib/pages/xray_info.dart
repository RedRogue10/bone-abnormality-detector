import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speedometer_chart/speedometer_chart.dart';

class XrayInfo extends StatefulWidget {
  final String patientId;
  final String scanId;

  const XrayInfo({super.key, required this.patientId, required this.scanId});

  @override
  State<XrayInfo> createState() => _XrayInfoState();
}

class _XrayInfoState extends State<XrayInfo> {
  // Colors
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color darkRed = Color(0xFF450B0B);
  static const Color green = Color(0xFF0B4518);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;
  static const Color bgGrey = Color(0xFFF0F0F0);

  bool xrayAbnormal = false; // Placeholder for actual abnormality status
  int _currentImageIndex = 0;
  final int _imageCount = 2;

  void _showImageViewer(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(ctx),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred + dimmed background
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  // Enlarged image — inner tap does not dismiss
                  Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.black),
                        child: const AspectRatio(
                          aspectRatio: 1,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.white38,
                              size: 96,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align to top for multi-line values
      children: [
        SizedBox(
          width: 120, // Fixed width for labels to align them
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 16, letterSpacing: 0.5),
            softWrap: true, // Allow wrapping
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: xrayAbnormal ? darkRed : green,
      appBar: AppBar(
        backgroundColor: xrayAbnormal ? darkRed : green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Abnormality Detection Result',
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
          child: Column(
            children: [
              Container(
                color: xrayAbnormal ? darkRed : green,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        xrayAbnormal
                            ? 'Abnormality Detected'
                            : 'No Abnormality Detected',
                        style: GoogleFonts.oswald(fontSize: 24, color: white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      SpeedometerChart(
                        value: xrayAbnormal
                            ? 80
                            : 20, // Example: 80% abnormality if abnormal, 20% if normal
                        minValue: 0,
                        maxValue: 100,
                        dimension: 250,
                        pointerColor: white,
                        graphColor: [Colors.red, Colors.yellow, Colors.green],
                        animationDuration: 3000,
                      ),

                      Text(
                        '80% confidence',
                        style: GoogleFonts.inter(fontSize: 22, color: white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        xrayAbnormal
                            ? 'High abnormality detected. Please consult a specialist.'
                            : 'No significant abnormality detected.',
                        style: GoogleFonts.inter(fontSize: 16, color: white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: bgGrey,
                child: Column(
                  children: [
                    // X-ray image placeholder
                    GestureDetector(
                      onTap: () => _showImageViewer(context),
                      child: Container(
                        width: double.infinity,
                        height: 350,
                        decoration: BoxDecoration(color: Colors.black),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white38,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image navigation row
                    Row(
                      children: [
                        // Arrows + dots
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_currentImageIndex > 0) {
                                    setState(() => _currentImageIndex--);
                                  }
                                },
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.black54,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...List.generate(_imageCount, (i) {
                                final active = i == _currentImageIndex;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _currentImageIndex = i),
                                  child: Container(
                                    width: active ? 12 : 10,
                                    height: active ? 12 : 10,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: active
                                          ? primaryBlue
                                          : const Color(0xFFCCCCCC),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (_currentImageIndex < _imageCount - 1) {
                                    setState(() => _currentImageIndex++);
                                  }
                                },
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black54,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: grey, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          'This is an AI-generate result. Review required',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: darkNavy,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('AI-Generated Result'),
                              content: Text(
                                'This result is generated by AI and must be reviewed and confirmed by a qualified radiologist before any medical decisions are made.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        'Learn More',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: primaryBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),

                      child: Column(
                        children: [
                          // -------------------- Bone Part Detected --------------------
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Bone Part Detected',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: primaryBlue,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                _buildInfoRow('Humerus', '80% Confidence'),
                                _buildInfoRow('Forearm', '40% Confidence'),
                                _buildInfoRow('Wrist', '20% Confidence'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
