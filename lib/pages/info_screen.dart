import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  static const Color bgColor    = Color(0xFF0A1128);
  static const Color darkNavy   = Color(0xFF0B2545);
  static const Color boxColor   = Color(0xFF0B2545);
  static const Color boxBorder  = Color(0xFFB8D8D8);
  static const Color tealAccent = Color(0xFFB8D8D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Navy header bar
          Container(
            color: darkNavy,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'ABOUT',
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Logo + App name
                  Column(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'X-RAY READER',
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bone Abnormality Detector',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // WHAT IT DOES
                  _infoBox(
                    title: 'WHAT IT DOES',
                    child: Text(
                      'A clinical mobile tool designed for doctors and radiologists. It uses a '
                      'trained deep learning model to analyze bone X-rays and detect fractures '
                      'and structural abnormalities which helps physicians make faster, more '
                      'informed diagnostic decisions at the point of care.',
                      style: _bodyStyle(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // WHO IT IS FOR
                  _infoBox(
                    title: 'WHO IT IS FOR',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _featureRow('Licensed physicians and radiologists'),
                        const SizedBox(height: 8),
                        _featureRow('Orthopedic and emergency medicine doctors'),
                        const SizedBox(height: 8),
                        _featureRow('Medical professionals in clinical settings'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // KEY FEATURES
                  _infoBox(
                    title: 'KEY FEATURES',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _featureRow('AI-assisted X-ray abnormality detection'),
                        const SizedBox(height: 8),
                        _featureRow('Patient record and scan history management'),
                        const SizedBox(height: 8),
                        _featureRow('Heatmap visualization of detected regions'),
                        const SizedBox(height: 8),
                        _featureRow('Confidence score per prediction result'),
                        const SizedBox(height: 8),
                        _featureRow('Camera and gallery X-ray image capture'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // IMPORTANT NOTICE
                  _infoBox(
                    title: 'IMPORTANT NOTICE',
                    child: Text(
                      'This app is intended as a clinical decision support tool for use by '
                      'qualified medical professionals only. All AI-generated results must be '
                      'reviewed and confirmed by the attending physician. This tool does not '
                      'replace professional medical judgment and should not be used as a sole '
                      'basis for diagnosis or treatment decisions.',
                      style: _bodyStyle(),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorder, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.oswald(
              color: tealAccent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, color: tealAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: _bodyStyle())),
      ],
    );
  }

  TextStyle _bodyStyle() {
    return TextStyle(
      color: Colors.white.withOpacity(0.80),
      fontSize: 13.5,
      height: 1.55,
    );
  }
}