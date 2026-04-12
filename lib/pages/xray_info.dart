import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speedometer_chart/speedometer_chart.dart';

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
                        'Abnormality Detected',
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
                    const SizedBox(height: 16),
                    // Bone part detected
                    Text(
                      'Bone Part Detected: Humerus',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: primaryBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
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
                    Text(
                      '[Learn More]',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: primaryBlue,
                        decoration: TextDecoration.underline,
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
