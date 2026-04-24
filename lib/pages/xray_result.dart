import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/patient.dart';
import '../models/scan_result.dart';
import '../services/database_service.dart';
import '../services/model_processing.dart';

class XrayResultPage extends StatefulWidget {
  final File    imageFile;
  final String? patientId;

  const XrayResultPage({super.key, required this.imageFile, this.patientId});

  @override
  State<XrayResultPage> createState() => _XrayResultPageState();
}

class _XrayResultPageState extends State<XrayResultPage> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white       = Colors.white;
  static const Color fieldBg     = Color(0xFFF0F0F0);

  final ModelProcessor        _processor           = ModelProcessor();
  final DatabaseService       _db                  = DatabaseService();
  final TextEditingController _searchCtrl          = TextEditingController();
  final FocusNode             _searchFocus         = FocusNode();
  final TextEditingController _interpretationCtrl  = TextEditingController();

  ScanResult? _result;
  String?     _errorMessage;
  bool        _isLoading = true;
  bool        _saving    = false;
  bool        _editingInterpretation = false;

  Patient?      _selectedPatient;
  List<Patient> _allPatients   = [];
  List<Patient> _searchResults = [];
  bool          _showDropdown  = false;

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
    _interpretationCtrl.dispose();
    super.dispose();
  }

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
          final match = patients.where((p) => p.id == widget.patientId);
          if (match.isNotEmpty) _selectedPatient = match.first;
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

  void _clearPatient() => setState(() => _selectedPatient = null);

  Future<void> _save() async {
    if (_result == null || _saving || _selectedPatient == null) return;
    setState(() => _saving = true);
    try {
      final scanId = await _db.createFullXrayScan(
        patientId: _selectedPatient!.id,
        imageFile: widget.imageFile,
      );
      await _db.updateXrayScanResult(
        patientId: _selectedPatient!.id,
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

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildBonePart(String label, String confidence) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        Text(confidence,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTextResult() {
    final result = _result!;
    final isAbnormal = result.hasAbnormality;
    final label = isAbnormal ? 'ABNORMALITY DETECTED' : 'NO ABNORMALITY DETECTED';
    final confidenceText =
        '${((isAbnormal ? result.abnormalityConfidence : 1.0 - result.abnormalityConfidence) * 100).toStringAsFixed(1)}% Confidence';
    final topPrediction =
        result.topPredictions.isNotEmpty ? result.topPredictions.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: isAbnormal ? Colors.red : primaryBlue,
                  fontWeight: FontWeight.w500,
                  fontSize: 22,
                  letterSpacing: 1.2)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(confidenceText,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
        ),
        const SizedBox(height: 24),
        Text('BONE PART DETECTED',
            style: GoogleFonts.oswald(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        if (topPrediction != null)
          _buildBonePart(
            topPrediction.bonePart.toUpperCase(),
            '${(topPrediction.confidence * 100).toStringAsFixed(1)}% Confidence',
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
                Text(_selectedPatient!.fullName,
                    style: GoogleFonts.poppins(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text('${_selectedPatient!.age} Years Old',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                Text(_selectedPatient!.sex,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
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
        Text('Assign Patient',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: 'Search patient by name…',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black45),
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
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
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: _searchResults.map((p) {
                return InkWell(
                  onTap: () => _selectPatient(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                      fontSize: 13, fontWeight: FontWeight.w600)),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No patients found.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45)),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: white),
          onPressed: () {},
        ),
        title: Text('RESULTS',
            style: GoogleFonts.oswald(
                color: white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: white),
            onPressed: () {},
          ),
        ],
      );

  Widget _buildLoading() => Scaffold(
        backgroundColor: white,
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF1A73E9)),
              SizedBox(height: 16),
              Text('Analysing image…'),
            ],
          ),
        ),
      );

  Widget _buildError() => Scaffold(
        backgroundColor: white,
        appBar: _buildAppBar(),
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
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
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

  Widget _buildPage() {
    final dateStr = DateFormat('MMMM d, y').format(DateTime.now());

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + date
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left,
                          color: Colors.black87, size: 28),
                    ),
                    const SizedBox(width: 4),
                    Text('$dateStr Results',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 14),

                // X-ray image
                GestureDetector(
                  onTap: _showImageViewer,
                  child: Container(
                    width: double.infinity,
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(widget.imageFile, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nav dot
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildTextResult(),
                const SizedBox(height: 24),

                // Interpretation
                Row(
                  children: [
                    Text('INTERPRETATION',
                        style: GoogleFonts.oswald(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(
                          () => _editingInterpretation = !_editingInterpretation),
                      child: Text(
                          _editingInterpretation ? 'DONE' : 'EDIT',
                          style: const TextStyle(
                              color: Colors.blueAccent, fontSize: 16)),
                    ),
                  ],
                ),
                if (_editingInterpretation)
                  TextField(
                    controller: _interpretationCtrl,
                    maxLines: null,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Enter interpretation…',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black38),
                      filled: true,
                      fillColor: fieldBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  )
                else
                  Text(
                    _interpretationCtrl.text.isEmpty
                        ? 'No interpretation added.'
                        : _interpretationCtrl.text,
                    style: GoogleFonts.poppins(
                        color: _interpretationCtrl.text.isEmpty
                            ? Colors.black38
                            : Colors.black87,
                        fontSize: 13),
                  ),
                const SizedBox(height: 24),

                // Patient selector at the bottom
                const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 12),
                _buildPatientSelector(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Save / Retake ────────────────────────────────────────────
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
                onPressed: (_selectedPatient != null && _result != null && !_saving)
                    ? _save
                    : null,
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
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: white, strokeWidth: 2))
                    : Text('Save',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    return Scaffold(
      backgroundColor: white,
      appBar: _buildAppBar(),
      body: _buildPage(),
    );
  }
}
