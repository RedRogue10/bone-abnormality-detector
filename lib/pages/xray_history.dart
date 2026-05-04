import 'package:bone_abnormality_detector/pages/info_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bone_abnormality_detector/pages/xray_result.dart';
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
  static const Color lightBlue = Color(0xFF7EB8F7);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;

  Patient? _patient;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  String formatDate(DateTime date) {
    return DateFormat('MMMM d, y  •  hh:mm a').format(date);
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

  Widget _buildScanCard(XrayScan scan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 95),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          color: white,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => XrayResultPage(
                    patientId: widget.patientId,
                    scanId: scan.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Image.network(
                      scan.imageUrl,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Image.asset(
                        'assets/images/xray.png',
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "X-ray Scan",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatDate(scan.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Scan ID: ${scan.id}",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrow
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'X-RAY HISTORY',
          style: GoogleFonts.oswald(color: white, fontSize: 20),
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
      body: Column(
        children: [
          // ── Navy Patient Header
          Container(
            width: double.infinity,
            color: darkNavy,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: primaryBlue,
                  radius: 46,
                  child: Text(
                    _patient?.initials ?? '',
                    style: const TextStyle(
                      color: white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _patient?.fullName ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: white,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_patient?.age ?? '-'} years old,  ${_patient?.sex ?? '-'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: lightBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scan List
          Expanded(
            child: StreamBuilder<List<XrayScan>>(
              stream: DatabaseService().getPatientScansStream(widget.patientId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final scans = snapshot.data!;

                if (scans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_search_rounded,
                          size: 64,
                          color: grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No scans found',
                          style: GoogleFonts.poppins(fontSize: 15, color: grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: scans.length,
                  itemBuilder: (context, index) => _buildScanCard(scans[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
