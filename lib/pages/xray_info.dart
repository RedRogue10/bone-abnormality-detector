import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speedometer_chart/speedometer_chart.dart';

import '../models/patient.dart';
import '../models/scan_result.dart';
import '../services/database_service.dart';
import '../services/model_processing.dart';

class XrayInfo extends StatefulWidget {
  final File imageFile;
  final String? patientId;

  const XrayInfo({super.key, required this.imageFile, this.patientId});

  @override
  State<XrayInfo> createState() => _XrayInfoState();
}

class _XrayInfoState extends State<XrayInfo> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color darkRed = Color(0xFF450B0B);
  static const Color green = Color(0xFF0B4518);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;
  static const Color bgGrey = Color(0xFFF0F0F0);
  static const Color fieldBg = Color(0xFFF0F0F0);

  final ModelProcessor _processor = ModelProcessor();
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  ScanResult? _result;
  Uint8List? _camImage;
  String? _errorMessage;
  bool _isLoading = true;
  bool _saving = false;

  Patient? _selectedPatient;
  List<Patient> _allPatients = [];
  List<Patient> _searchResults = [];
  bool _showDropdown = false;

  int _currentImageIndex = 0;
  // 0 = original xray, 1 = CAM overlay (reserved for future integration)
  static const int _imageCount = 2;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
    _loadPatients();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    try {
      final output = await _processor.analyzeImage(widget.imageFile);
      if (mounted) {
        setState(() {
          _result = output.result;
          _camImage = output.camImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _db.getPatients();
      if (!mounted) return;
      setState(() {
        _allPatients = patients;
        if (widget.patientId != null) {
          final match = patients.where((p) => p.id == widget.patientId);
          if (match.isNotEmpty) _selectedPatient = match.first;
        }
      });
    } catch (_) {}
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
      });
      return;
    }
    setState(() {
      _searchResults = _allPatients
          .where((p) => p.fullName.toLowerCase().contains(q))
          .take(6)
          .toList();
      _showDropdown = true;
    });
  }

  void _selectPatient(Patient p) {
    setState(() {
      _selectedPatient = p;
      _showDropdown = false;
      _searchCtrl.clear();
    });
    _searchFocus.unfocus();
  }

  void _clearPatient() => setState(() => _selectedPatient = null);

  Future<void> _save() async {
    if (_result == null || _saving || _selectedPatient == null) return;
    setState(() => _saving = true);
    try {
      final scanId = await _db.createFullXrayScan(
        patientId: _selectedPatient!.id,
        imageFile: widget.imageFile,
      );

      if (_camImage != null) {
        // Write CAM bytes to a temp file, upload via attachAIResultToScan
        final tempFile = File(
          '${Directory.systemTemp.path}/cam_${scanId}_overlay.png',
        );
        await tempFile.writeAsBytes(_camImage!);
        await _db.attachAIResultToScan(
          patientId: _selectedPatient!.id,
          scanId: scanId,
          generatedImages: [tempFile],
          resultData: _result!,
        );
        await tempFile.delete();
      } else {
        await _db.updateXrayScanResult(
          patientId: _selectedPatient!.id,
          scanId: scanId,
          result: _result!,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print("SAVE ERROR: $e");
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  double get _speedometerValue {
    if (_result == null) return 0;
    return (_result!.abnormalityConfidence * 100).clamp(0.0, 100.0);
  }

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
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(color: Colors.black),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRect(
                            child: _buildImageForIndex(_currentImageIndex),
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

  Widget _buildImageForIndex(int index) {
    if (index == 0) {
      return Image.file(widget.imageFile, fit: BoxFit.contain);
    }
    if (_camImage != null) {
      return Image.memory(_camImage!, fit: BoxFit.contain);
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, color: Colors.white38, size: 64),
          SizedBox(height: 12),
          Text(
            'CAM overlay coming soon',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
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

  Widget _buildPatientSelector() {
    if (_selectedPatient != null) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPatient!.fullName,
                  style: GoogleFonts.poppins(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${_selectedPatient!.age} Years Old',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _selectedPatient!.sex,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.black45),
            onPressed: _clearPatient,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Patient',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: 'Search patient by name…',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: Colors.black45,
            ),
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        if (_showDropdown && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: _searchResults.map((p) {
                return InkWell(
                  onTap: () => _selectPatient(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: primaryBlue,
                          child: Text(
                            p.initials,
                            style: const TextStyle(
                              color: white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.fullName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${p.age} yrs · ${p.sex}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else if (_showDropdown && _searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No patients found.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: darkNavy,
        appBar: AppBar(
          backgroundColor: darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: white, size: 28),
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
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: white),
              SizedBox(height: 16),
              Text('Analysing image…', style: TextStyle(color: white)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: bgGrey,
        appBar: AppBar(
          backgroundColor: darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: white, size: 28),
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
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Analysis failed',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: darkNavy),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                    _runAnalysis();
                  },
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(color: white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAbnormal = _result?.hasAbnormality ?? false;
    final headerColor = isAbnormal ? darkRed : green;
    final displayConfidence = _result!.abnormalityConfidence * 100;

    return Scaffold(
      backgroundColor: headerColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: white, size: 28),
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
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: headerColor,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            isAbnormal
                                ? 'Abnormality Detected'
                                : 'No Abnormality Detected',
                            style: GoogleFonts.oswald(
                              fontSize: 24,
                              color: white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          SpeedometerChart(
                            value: _speedometerValue,
                            minValue: 0,
                            maxValue: 100,
                            dimension: 250,
                            pointerColor: white,
                            graphColor: [
                              Colors.green,
                              Colors.yellow,
                              Colors.red,
                            ],
                            animationDuration: 3000,
                          ),
                          Text(
                            '${displayConfidence.toStringAsFixed(1)}% Confidence',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              color: white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            isAbnormal
                                ? 'High abnormality detected. Please consult a specialist.'
                                : 'No significant abnormality detected.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    Container(
                      color: bgGrey,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showImageViewer(context),
                            child: Container(
                              width: double.infinity,
                              height: 350,
                              color: Colors.black,
                              child: _buildImageForIndex(_currentImageIndex),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Image navigation dots + arrows
                          Row(
                            children: [
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
                                        onTap: () => setState(
                                          () => _currentImageIndex = i,
                                        ),
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
                                        if (_currentImageIndex <
                                            _imageCount - 1) {
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
                                'This is an AI-generated result. Review required.',
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
                                builder: (BuildContext ctx) {
                                  return AlertDialog(
                                    title: const Text('AI-Generated Result'),
                                    content: const Text(
                                      'This result is generated by AI and must be '
                                      'reviewed and confirmed by a qualified '
                                      'radiologist before any medical decisions '
                                      'are made.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text('OK'),
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

                          // Bone part predictions
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    children:
                                        _result == null ||
                                            _result!.topPredictions.isEmpty
                                        ? [
                                            Text(
                                              'No predictions available.',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: grey,
                                              ),
                                            ),
                                          ]
                                        : _result!.topPredictions
                                              .map(
                                                (p) => _buildInfoRow(
                                                  p.bonePart[0].toUpperCase() +
                                                      p.bonePart.substring(1),
                                                  '${(p.confidence * 100).toStringAsFixed(1)}% Confidence',
                                                ),
                                              )
                                              .toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),

                          // Patient selector
                          const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _buildPatientSelector(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Retake / Save
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkNavy,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Retake',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        (_selectedPatient != null &&
                            _result != null &&
                            !_saving)
                        ? _save
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkNavy,
                      foregroundColor: white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
