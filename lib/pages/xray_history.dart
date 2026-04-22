import 'package:bone_abnormality_detector/pages/info_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bone_abnormality_detector/pages/xray_info.dart';
import '../services/database_service.dart';
import '../models/xray_scan.dart';
import '../models/patient.dart';
import 'package:intl/intl.dart';

class XrayHistory extends StatefulWidget {
  final String patientId;

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

  Patient? _patient;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  String formatDate(DateTime date) {
    return DateFormat('MMMM d, y hh:mm a').format(date);
  }

  Future<void> _loadPatient() async {
    try {
      Patient patient = await DatabaseService().getPatientById(
        widget.patientId,
      );
      setState(() {
        _patient = patient;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load patient data: $e')),
      );
    }
  }

  Widget _buildScanButton(XrayScan scan) {
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
                      XrayInfo(patientId: widget.patientId, scanId: scan.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.only(left: 0, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Image.network(
                      scan.imageUrl,
                      width: 120,
                      height: double.infinity,
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
                            "X-ray Scan",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatDate(scan.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Scan ID: ${scan.id}",
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
              icon: const Icon(
                Icons.info_outline_rounded,
                color: white,
                size: 22,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InfoScreen()),
                );
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryBlue,
                      minRadius: 40.0,
                      child: Text(
                        _patient?.initials ?? '',
                        style: TextStyle(
                          color: white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _patient?.fullName ?? '',
                          style: GoogleFonts.inter(
                            color: primaryBlue,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "${_patient?.age ?? ''} years old",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _patient?.sex ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                StreamBuilder<List<XrayScan>>(
                  stream: DatabaseService().getPatientScansStream(
                    widget.patientId,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final scans = snapshot.data!;

                    if (scans.isEmpty) {
                      return const Center(child: Text("No scans found"));
                    }

                    return Column(
                      children: scans.map(_buildScanButton).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
