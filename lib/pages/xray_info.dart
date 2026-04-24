import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speedometer_chart/speedometer_chart.dart';

import '../models/patient.dart';
import '../models/scan_result.dart';
import '../services/database_service.dart';
import '../services/model_processing.dart';

class XrayInfo extends StatefulWidget {
  final File    imageFile;
  final String? patientId; // optional pre-selected patient

  const XrayInfo({super.key, required this.imageFile, this.patientId});

  @override
  State<XrayInfo> createState() => _XrayInfoState();
}

class _XrayInfoState extends State<XrayInfo> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color darkRed     = Color(0xFF450B0B);
  static const Color green       = Color(0xFF0B4518);
  static const Color grey        = Color(0xFF808080);
  static const Color white       = Colors.white;
  static const Color bgGrey      = Color(0xFFF0F0F0);

  final ModelProcessor            _processor     = ModelProcessor();
  final DatabaseService           _db            = DatabaseService();
  final TextEditingController     _searchCtrl    = TextEditingController();
  final FocusNode                 _searchFocus   = FocusNode();

  ScanResult?    _result;
  String?        _errorMessage;
  bool           _isLoading     = true;
  bool           _saving        = false;

  // Patient selector
  Patient?       _selectedPatient;
  List<Patient>  _allPatients   = [];
  List<Patient>  _searchResults = [];
  bool           _showDropdown  = false;

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

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _runAnalysis() async {
    try {
      final result = await _processor.analyzeImage(widget.imageFile);
      if (mounted) setState(() { _result = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _db.getPatients();
      if (!mounted) return;
      setState(() {
        _allPatients = patients;
        if (widget.patientId != null) {
          final matches = patients.where((p) => p.id == widget.patientId);
          if (matches.isNotEmpty) _selectedPatient = matches.first;
        }
      });
    } catch (_) {}
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() { _searchResults = []; _showDropdown = false; });
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
      _showDropdown    = false;
      _searchCtrl.clear();
    });
    _searchFocus.unfocus();
  }

  void _clearPatient() {
    setState(() => _selectedPatient = null);
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_result == null || _saving || _selectedPatient == null) return;
    setState(() => _saving = true);
    try {
      final pid    = _selectedPatient!.id;
      final scanId = await _db.createFullXrayScan(
        patientId: pid,
        imageFile: widget.imageFile,
      );
      await _db.updateXrayScanResult(
        patientId: pid,
        scanId: scanId,
        result: _result!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double get _speedometerValue {
    if (_result == null) return 0;
    final conf = _result!.abnormalityConfidence;
    return ((_result!.hasAbnormality ? conf : (1.0 - conf)) * 100).clamp(0.0, 100.0);
  }

  void _showImageViewer() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(ctx),
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(widget.imageFile, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 15), softWrap: true),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color bg) => AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Abnormality Detection Result',
            style: GoogleFonts.oswald(color: white, fontSize: 20, letterSpacing: 1.5)),
        centerTitle: true,
      );

  // ── Patient selector widget ───────────────────────────────────────────────

  Widget _buildPatientSelector() {
    return Container(
      color: white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assign to Patient',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: darkNavy)),
          const SizedBox(height: 6),

          // Selected patient chip
          if (_selectedPatient != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryBlue),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryBlue,
                    child: Text(_selectedPatient!.initials,
                        style: const TextStyle(
                            color: white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedPatient!.fullName,
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: darkNavy)),
                        Text('${_selectedPatient!.age} yrs · ${_selectedPatient!.sex}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                    onPressed: _clearPatient,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          else ...[
            // Search field
            TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'Search patient by name…',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black45),
                filled: true,
                fillColor: bgGrey,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),

            // Dropdown results
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
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: _searchResults.map((p) {
                    return InkWell(
                      onTap: () => _selectPatient(p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: primaryBlue,
                              child: Text(p.initials,
                                  style: const TextStyle(
                                      color: white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.fullName,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Text('${p.age} yrs · ${p.sex}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11, color: Colors.black54)),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('No patients found.',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45)),
              ),
          ],
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: darkNavy,
        appBar: _buildAppBar(darkNavy),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Analysing image…', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: bgGrey,
        appBar: _buildAppBar(darkNavy),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Analysis failed',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: darkNavy),
                  onPressed: () {
                    setState(() { _errorMessage = null; _isLoading = true; });
                    _runAnalysis();
                  },
                  child: Text('Retry', style: GoogleFonts.poppins(color: white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAbnormal  = _result!.hasAbnormality;
    final headerColor = isAbnormal ? darkRed : green;
    final canSave     = _selectedPatient != null && !_saving;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(headerColor),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header band ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    color: headerColor,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      children: [
                        Text(
                          isAbnormal
                              ? 'Abnormality Detected'
                              : 'No Abnormality Detected',
                          style: GoogleFonts.oswald(fontSize: 24, color: white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SpeedometerChart(
                          value: _speedometerValue,
                          minValue: 0,
                          maxValue: 100,
                          dimension: 240,
                          pointerColor: white,
                          graphColor: [Colors.green, Colors.yellow, Colors.red],
                          animationDuration: 1500,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_result!.abnormalityConfidence * 100).toStringAsFixed(1)}% Confidence',
                          style: GoogleFonts.inter(fontSize: 20, color: white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAbnormal
                              ? 'High abnormality detected. Please consult a specialist.'
                              : 'No significant abnormality detected.',
                          style: GoogleFonts.inter(fontSize: 15, color: white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // ── X-ray image ────────────────────────────────────
                  GestureDetector(
                    onTap: _showImageViewer,
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.black,
                      child: Image.file(widget.imageFile, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: grey, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'AI-generated result. Review required.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: darkNavy,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Bone part predictions ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bone Part Detected',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                color: primaryBlue,
                                letterSpacing: 1)),
                        const SizedBox(height: 12),
                        if (_result!.topPredictions.isEmpty)
                          Text('No predictions available.',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: grey))
                        else
                          ..._result!.topPredictions.map((p) => _buildInfoRow(
                                p.bonePart[0].toUpperCase() +
                                    p.bonePart.substring(1),
                                '${(p.confidence * 100).toStringAsFixed(1)}% Confidence',
                              )),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Patient selector + buttons ─────────────────────────────
          _buildPatientSelector(),
          Container(
            color: white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Retake',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    foregroundColor: white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: white, strokeWidth: 2),
                        )
                      : Text('Save',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
