import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_patient.dart';
import '../services/database_service.dart';
import '../models/patient.dart';
import '../pages/xray_history.dart';
import '../pages/info_screen.dart';
import '../pages/camera_capture.dart';

class PatientInfoScreen extends StatefulWidget {
  final String patientId;

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

  Patient? _patient;
  bool _hasXrayHistory = false;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      Patient patient = await DatabaseService().getPatientById(
        widget.patientId,
      );
      final hasXray = await DatabaseService().hasXrayHistory(widget.patientId);

      setState(() {
        _patient = patient;
        _hasXrayHistory = hasXray;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load patient data: $e')),
      );
    }
  }

  String get fullName {
    if (_patient == null) return 'Loading...';
    return '${_patient!.firstName} ${_patient!.middleName ?? ''} ${_patient!.lastName}'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String get age {
    if (_patient == null) return '-';
    final today = DateTime.now();
    final birth = _patient!.birthDate;
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age.toString();
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
            softWrap: true,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CameraCapturePage(patientId: widget.patientId),
            ),
          ).then((_) => _loadPatient());
        },
        backgroundColor: darkNavy,
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
        label: Text(
          'Add Scan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                        child: Text(
                          _patient?.initials ?? '',
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
                                fullName,
                                style: GoogleFonts.oswald(
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditPatientPage(
                                        patientId: widget.patientId,
                                      ),
                                    ),
                                  ).then((_) => _loadPatient());
                                },
                                icon: const Icon(
                                  Icons.edit_square,
                                  size: 16,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_patient?.age ?? '-'}, ${_patient?.sex ?? '-'}',
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
                            _buildInfoRow('Name', fullName),
                            _buildInfoRow('Age', age),
                            _buildInfoRow('Sex', _patient?.sex ?? '-'),
                            _buildInfoRow(
                              'Birthdate',
                              _patient != null
                                  ? '${_patient!.birthDate.month}/${_patient!.birthDate.day}/${_patient!.birthDate.year}'
                                  : '-',
                            ),
                            _buildInfoRow(
                              'Contact Number',
                              _patient?.contactNumber ?? '-',
                            ),
                            _buildInfoRow('Address', _patient?.address ?? '-'),
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
                            _buildInfoRow(
                              'Name',
                              _patient?.emergencyContact?.name ?? '-',
                            ),
                            _buildInfoRow(
                              'Contact Number',
                              _patient?.emergencyContact?.contactNumber ?? '-',
                            ),
                            _buildInfoRow(
                              'Relationship',
                              _patient?.emergencyContact?.relationship ?? '-',
                            ),
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
                                    if (_patient?.historyRecords.isEmpty ??
                                        true)
                                      Text(
                                        'No patient history records available.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: grey,
                                        ),
                                      )
                                    else
                                      ..._patient!.historyRecords.map(
                                        (record) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: _buildHistoryEntry(
                                            date: record.date,
                                            description: record.note,
                                          ),
                                        ),
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
                      _hasXrayHistory
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
