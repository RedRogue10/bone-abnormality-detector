import 'package:flutter/material.dart';
import '../services/web_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientWebView extends StatefulWidget {
  final String shortId;

  const PatientWebView({super.key, required this.shortId});

  @override
  State<PatientWebView> createState() => _PatientWebViewState();
}

class _PatientWebViewState extends State<PatientWebView> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          // Gets the scan using the id
          future: WebService().fetchByShortId(widget.shortId),
          builder: (context, snapshot) {
            // Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error State (Expired link, wrong token, or permission denied)
            if (snapshot.hasError || !snapshot.hasData) {
              print(snapshot.error);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_clock, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Access Denied",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "This link may have expired (valid for 3 days) or the security token is invalid. Please contact your clinic for a new link.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            final interpretation = data['result'] != null
                ? data['result']['interpretation'] ??
                      "No interpretation available."
                : "Analysis pending.";

            // Success State - The Result Dashboard
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),

                      // White Card Body
                      Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Patient + Scan Date
                            _buildMetaRow(
                              data['patientName'],
                              data['patientId'],
                              (data['createdAt'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  .split(' ')[0],
                              data['scanId'],
                            ),

                            const Divider(height: 1, color: Color(0xFFE5E5E5)),

                            // X-Ray Scan Result label
                            _buildSectionLabel('X-RAY SCAN RESULT'),

                            // X-Ray Image
                            _buildImageCarousel([
                              {'asset': data['imageUrl'], 'label': 'X-Ray'},
                            ]),

                            const SizedBox(height: 20),

                            // Doctor Interpretation label
                            _buildSectionLabel('DOCTOR INTERPRETATION'),

                            const SizedBox(height: 8),

                            // Interpretation box
                            _buildInterpretationBox(interpretation),

                            const SizedBox(height: 12),

                            // Doctor card
                            _buildDoctorCard(
                              data['doctorFullName'],
                              data['doctorInitials'],
                            ),

                            const SizedBox(height: 4),

                            // Expiry row (from backend: data['shareExpiresAt'])
                            _buildExpiryRow(
                              data['shareExpiresAt'].toDate().toString().split(
                                ' ',
                              )[0],
                            ),

                            const SizedBox(height: 16),

                            // Verified badge
                            _buildVerifiedBadge(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1C2B3A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'X-Ray Reader',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bone Abnormality Detector',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0x99FFFFFF),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Save as PDF button
          // GestureDetector(
          //   onTap: () {},
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //     decoration: BoxDecoration(
          //       color: Colors.white.withOpacity(0.1),
          //       border: Border.all(
          //         color: Colors.white.withOpacity(0.25),
          //         width: 1,
          //       ),
          //       borderRadius: BorderRadius.circular(6),
          //     ),
          //     child: const Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(
          //           Icons.picture_as_pdf_outlined,
          //           size: 15,
          //           color: Colors.white,
          //         ),
          //         SizedBox(width: 6),
          //         Text(
          //           'Save as PDF',
          //           style: TextStyle(
          //             fontSize: 12,
          //             fontWeight: FontWeight.w500,
          //             color: Colors.white,
          //             letterSpacing: 0.2,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Patient + Scan Date
  Widget _buildMetaRow(
    String patientName,
    String patientId,
    String createdAt,
    String scanId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaLabel(text: 'PATIENT'),
              SizedBox(height: 3),
              Text(
                patientName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              _MetaLabel(text: 'PATIENT ID'),
              SizedBox(height: 3),
              Text(
                patientId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MetaLabel(text: 'SCAN DATE'),
              SizedBox(height: 3),
              Text(
                createdAt,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              _MetaLabel(text: 'SCAN ID'),
              SizedBox(height: 3),
              Text(
                scanId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section label
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9E94),
        ),
      ),
    );
  }

  // Image carousel
  Widget _buildImageCarousel(List<Map<String, String>> scanImages) {
    if (scanImages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border.all(color: const Color(0xFFE2E2DC)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'No scan images available',
              style: TextStyle(fontSize: 12, color: Color(0xFF9E9E94)),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Image label + counter
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                scanImages[_currentPage]['label']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C2B3A),
                ),
              ),
              Text(
                '${_currentPage + 1} / ${scanImages.length}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E94)),
              ),
            ],
          ),
        ),

        // swipeable image
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  scanImages[_currentPage]['asset'] ?? '',
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    width: double.infinity,
                    height: 280,
                    color: const Color(0xFF0A0A0A),
                    child: const Center(
                      child: Text(
                        'Image unavailable',
                        style: TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // // Previous button
              // if (_currentPage > 0)
              //   Positioned(
              //     left: 8,
              //     child: GestureDetector(
              //       onTap: () => setState(() => _currentPage--),
              //       child: Container(
              //         width: 32,
              //         height: 32,
              //         decoration: BoxDecoration(
              //           color: const Color(0xFF1C2B3A).withOpacity(0.7),
              //           shape: BoxShape.circle,
              //         ),
              //         child: const Icon(
              //           Icons.chevron_left,
              //           color: Colors.white,
              //           size: 20,
              //         ),
              //       ),
              //     ),
              //   ),
              // // Next button
              // if (_currentPage < scanImages.length - 1)
              //   Positioned(
              //     right: 8,
              //     child: GestureDetector(
              //       onTap: () => setState(() => _currentPage++),
              //       child: Container(
              //         width: 32,
              //         height: 32,
              //         decoration: BoxDecoration(
              //           color: const Color(0xFF1C2B3A).withOpacity(0.7),
              //           shape: BoxShape.circle,
              //         ),
              //         child: const Icon(
              //           Icons.chevron_right,
              //           color: Colors.white,
              //           size: 20,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),

        // Dot indicators
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(scanImages.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1C2B3A)
                    : const Color(0xFFCDD8E3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Interpretation box
  Widget _buildInterpretationBox(String interpretation) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E2DC)),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(16),
        child: Text(
          interpretation,
          style: const TextStyle(
            fontSize: 13,
            height: 1.75,
            color: Color(0xFF2A2A2A),
          ),
        ),
      ),
    );
  }

  // Doctor card
  Widget _buildDoctorCard(String doctorName, String doctorInitials) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E2DC)),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFCDD8E3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  doctorInitials,
                  style: TextStyle(
                    color: Color(0xFF1C2B3A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $doctorName',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Radiologist',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9E94),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Expiry row
  Widget _buildExpiryRow(String expiryDate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          'This link will expire on: $expiryDate',
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFFB8860B).withOpacity(0.85),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // Verified badge
  Widget _buildVerifiedBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F0),
          border: Border.all(color: const Color(0xFFB2D8B2)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.verified_user, size: 16, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text(
              'Verified & Secured by Bone X-Ray Reader',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable small label
class _MetaLabel extends StatelessWidget {
  final String text;
  const _MetaLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9.5,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
        color: Color(0xFF9E9E94),
      ),
    );
  }
}
