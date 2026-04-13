import 'package:bone_abnormality_detector/pages/xray_history.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientInfoScreen extends StatefulWidget {
  final int patientId;

  const PatientInfoScreen({super.key, required this.patientId});

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  // Colors
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;

  // Replace with actual check from database
  bool hasXrayHistory = true;

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

  Widget _buildHistoryEntry({
    required String date,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.poppins(fontSize: 14, letterSpacing: 0.5),
          softWrap: true,
        ),
      ],
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
          'Patient Information',
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Patient info card
                ElevatedButton(
                  onPressed: () {
                    // Disabled
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0B2545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryBlue,
                        minRadius: 40.0,
                        child: const Text(
                          'JC',
                          style: TextStyle(
                            color: white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Juan de la Cruz Jr.',
                                style: GoogleFonts.oswald(
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Will implement edit functionality later, for now just print to console
                                  print('Edit patient info');
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '33, Male',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),

                  child: Column(
                    children: [
                      // -------------------- Personal Information --------------------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Personal Information',
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
                            _buildInfoRow('Name', 'Juan de la Cruz Jr.'),
                            _buildInfoRow('Age', '33'),
                            _buildInfoRow('Sex', 'Male'),
                            _buildInfoRow('Birthdate', 'January 1, 1990'),
                            _buildInfoRow('Contact Number', '09123456789'),
                            _buildInfoRow(
                              'Address',
                              '123 Main Street, City, Country',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // -------------------- Emergency Contact --------------------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Emergency Contact',
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
                            _buildInfoRow('Name', 'Rica J. de la Cruz'),
                            _buildInfoRow('Contact Number', '0921-112-3421'),
                            _buildInfoRow('Relationship', 'Wife'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // -------------------- Patient History --------------------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Patient History',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: primaryBlue,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 2,
                                decoration: BoxDecoration(
                                  color: primaryBlue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Will convert this to a ListView.builder when we have real data
                                    _buildHistoryEntry(
                                      date: '2023-10-01',
                                      description:
                                          'Initial consultation for bone abnormality detection.',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildHistoryEntry(
                                      date: '2023-10-15',
                                      description:
                                          'X-ray performed; results show potential fracture in femur.',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildHistoryEntry(
                                      date: '2023-11-01',
                                      description:
                                          'Follow-up appointment; treatment plan discussed.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // -------------------- Xray History --------------------
                      hasXrayHistory
                          ? Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => XrayHistory(
                                        patientId: widget.patientId,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 35,
                                    vertical: 30,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/images/xray_background.png',
                                      ),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.3),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'View Xray Results',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: white,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: null, // Disabled
                              style: ElevatedButton.styleFrom(
                                backgroundColor: grey,
                                foregroundColor: white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 35,
                                  vertical: 30,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'No Xray Results Available',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
      ),
    );
  }
}
