import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class XrayResultPage extends StatefulWidget {
  const XrayResultPage({super.key});

  @override
  State<XrayResultPage> createState() => _XrayResultPageState();
}

class _XrayResultPageState extends State<XrayResultPage> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white       = Colors.white;
  static const Color fieldBg     = Color(0xFFF0F0F0);

  int _currentImageIndex = 0;
  final int _imageCount = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: white),
          onPressed: () {},
        ),
        title: Text(
          'RESULTS',
          style: GoogleFonts.oswald(
            color: white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + Date header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.black87, size: 28),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'March 30, 2026 Results',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Patient info row
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fieldBg,
                          border: Border.all(
                              color: const Color(0xFFCCCCCC), width: 1.5),
                        ),
                        child: const Icon(Icons.person_outline,
                            size: 36, color: darkNavy),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Juan Dela Cruz',
                            style: GoogleFonts.poppins(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '33 Years Old',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Male',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // X-ray image placeholder
                  Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          color: Colors.white38, size: 64),
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
                                  setState(
                                      () => _currentImageIndex--);
                                }
                              },
                              child: const Icon(Icons.chevron_left,
                                  color: Colors.black54, size: 24),
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
                                      horizontal: 4),
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
                                  setState(
                                      () => _currentImageIndex++);
                                }
                              },
                              child: const Icon(Icons.chevron_right,
                                  color: Colors.black54, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Result
                  Center(
                    child: Text(
                      'NO ABNORMALITY DETECTED',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: primaryBlue,
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '90% Confidence',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bone Part Detected section
                  Text(
                    'BONE PART DETECTED',
                    style: GoogleFonts.oswald(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBonePart('ELBOW', '80% Confidence'),
                  const SizedBox(height: 8),
                  _buildBonePart('FOREARM', '5% Confidence'),
                  const SizedBox(height:10),
                  Row(
                    children: [
                      Text(
                        'INTERPRETATION',
                        style: GoogleFonts.oswald(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Spacer(),
                      TextButton(onPressed: (){}, child: Text("EDIT",style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                      ),))
                    ],
                  ),
                  Text(
                    'Lorem ipsum lorem ipsum, lorem ipsum',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Retake',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonePart(String label, String confidence) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          confidence,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
