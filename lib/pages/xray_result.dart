import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/interpretation_preset.dart';
import '../models/scan_result.dart';
import '../models/xray_scan.dart';
import '../services/database_service.dart';
import '../services/sharing_service.dart';
import '../services/email_service.dart';
import '../widgets/preset_picker_sheet.dart';
import '../pages/add_patient.dart';
class XrayResultPage extends StatefulWidget {
  final String patientId;
  final String scanId;

  const XrayResultPage({
    super.key,
    required this.patientId,
    required this.scanId,
  });

  @override
  State<XrayResultPage> createState() => _XrayResultPageState();
}

class _XrayResultPageState extends State<XrayResultPage> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white = Colors.white;
  static const Color fieldBg = Color(0xFFF0F0F0);


  final DatabaseService _db = DatabaseService();
  final TextEditingController _interpretationCtrl = TextEditingController();

  XrayScan? _scan;
  ScanResult? _result;
  String?     _camImageUrl;
  String?     _errorMessage;
  bool        _isLoading  = true;
  bool        _savingNote = false;
  List<InterpretationPreset> _presets = [];

  Patient? _selectedPatient;
  List<Patient> _allPatients = [];

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadScan();
    _loadPatients();
    _loadPresets();
  }

  @override
  void dispose() {
    _interpretationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadScan() async {
    try {
      final scan = await _db.getXrayScanById(widget.patientId, widget.scanId);
      if (mounted) {
        setState(() {
          _scan = scan;
          _result = scan.result;
          _camImageUrl = scan.result?.generatedImageUrls.isNotEmpty == true
              ? scan.result!.generatedImageUrls.first
              : null;
          if (_camImageUrl == null) _currentImageIndex = 0;
          _isLoading = false;
        });
        _interpretationCtrl.text = scan.result?.interpretation ?? '';
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

  Future<void> _loadPresets() async {
    try {
      final presets = await _db.getPresets();
      if (mounted) setState(() => _presets = presets);
    } catch (_) {}
  }

  void _showShareOptions() async {
    final patientDoc = await _db.getPatientById(widget.patientId);
    final patientEmail = patientDoc.email;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final hasEmail = patientEmail != null && patientEmail.trim().isNotEmpty;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                enabled: hasEmail,
                leading: Icon(Icons.email_outlined,
                    color: hasEmail ? Colors.black87 : Colors.grey),
                title: Text(
                  hasEmail
                      ? 'Send to patient email'
                      : 'No email available for this patient',
                  style: TextStyle(
                      color: hasEmail ? Colors.black87 : Colors.grey),
                ),
                onTap: hasEmail
                    ? () {
                        Navigator.pop(context);
                        _sendEmailToPatient(patientEmail);
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy link to clipboard'),
                onTap: () {
                  Navigator.pop(context);
                  _copyPublicLink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyPublicLink() async {
    final link = await SharingService().generateSecureLink(
      patientId: widget.patientId,
      scanId: widget.scanId,
    );
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  void _sendEmailToPatient(String email) async {
    try {
      final link = await SharingService().generateSecureLink(
        patientId: widget.patientId,
        scanId: widget.scanId,
      );
      await EmailService().sendEmailLink(email, link);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Email sent to $email')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send email: $e')));
    }
  }

  Future<void> _saveInterpretation() async {
    final text = _interpretationCtrl.text.trim();
    if (_result == null) return;
    setState(() => _savingNote = true);
    try {
      await _db.updateInterpretation(
        patientId: widget.patientId,
        scanId: widget.scanId,
        interpretation: text,
      );
      if (mounted) {
        setState(() {
          _result = _result!.copyWith(interpretation: text);
          _savingNote = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interpretation saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingNote = false);
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
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5.0,
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
                            child: _buildImageForIndex(_currentImageIndex),
                          ),
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
  Future<void> _loadPatients() async {
    try {
      final patients = await _db.getPatients();
      if (!mounted) return;
      setState(() {
        _allPatients = patients;
        if (_selectedPatient == null) {
          final match = patients.where((p) => p.id == widget.patientId);
          if (match.isNotEmpty) _selectedPatient = match.first;
        }
      });
    } catch (_) {}
  }

  Future<void> _showPatientPicker() async {
    final picked = await showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PatientPickerSheet(
        patients: _allPatients,
        currentPatientId: widget.patientId,
        onAddPatient: () async {
          Navigator.pop(ctx);
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddPatientPage()),
          );
          if (added == true) {
            await _loadPatients();
            if (mounted) _showPatientPicker();
          }
        },
      ),
    );
    if (picked == null) return;
    await _reassignPatient(picked);
  }

  Future<void> _reassignPatient(Patient newPatient) async {
    setState(() => _isLoading = true);
    try {
      final newScanId = await _db.reassignScan(
        oldPatientId: widget.patientId,
        scanId: widget.scanId,
        newPatientId: newPatient.id,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => XrayResultPage(
            patientId: newPatient.id,
            scanId: newScanId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reassign: $e')),
        );
      }
    }
  }
  Widget _buildImageForIndex(int index) {
    if (index == 0) return _buildNetworkImage();

    if (_camImageUrl != null) {
      return Image.network(
        _camImageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.broken_image_outlined,
                color: Colors.white38, size: 64),
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, color: Colors.white38, size: 64),
          SizedBox(height: 12),
          Text(
            'CAM overlay not available',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage() {
    final url = _scan?.imageUrl ?? '';
    if (url.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, color: Colors.white38, size: 64),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (context, error, stack) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.white38,
        size: 64,
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
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildTextResult() {
    final result = _result!;
    final isAbnormal = result.hasAbnormality;
    final label = isAbnormal
        ? 'ABNORMALITY DETECTED'
        : 'NO ABNORMALITY DETECTED';
    final confidenceText =
        '${(result.abnormalityConfidence * 100).toStringAsFixed(1)}% Abnormality Confidence';
    final topPrediction = result.topPredictions.isNotEmpty
        ? result.topPredictions.first
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isAbnormal ? Colors.red : primaryBlue,
              fontWeight: FontWeight.w500,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            confidenceText,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 24),
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
        if (topPrediction != null)
          _buildBonePart(
            topPrediction.bonePart.toUpperCase(),
            '${(topPrediction.confidence * 100).toStringAsFixed(1)}% Confidence',
          ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('INTERPRETATION',
                style: GoogleFonts.oswald(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.format_list_bulleted, size: 15),
              label: Text('Presets', style: GoogleFonts.poppins(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () async {
                final body = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PresetPickerSheet(presets: _presets),
                );
                await _loadPresets();
                if (body != null) _interpretationCtrl.text = body;
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _interpretationCtrl,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Add clinical notes or interpretation…',
            hintStyle:
                GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _savingNote ? null : _saveInterpretation,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkNavy,
              foregroundColor: white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _savingNote
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Save Note',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
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
          TextButton(
            onPressed: _showPatientPicker,
            child: Text('Change',
                style: GoogleFonts.poppins(fontSize: 12, color: primaryBlue)),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showPatientPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_search_rounded,
                color: Colors.black45, size: 22),
            const SizedBox(width: 12),
            Text('Select Patient',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black45)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }
  Future<void> _deleteScan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete scan?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete the scan and all associated images.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.deleteXrayScan(widget.patientId, widget.scanId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: white, size: 28),
          onPressed: () => Navigator.pop(context),
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
            icon: const Icon(Icons.share_outlined, color: white),
            tooltip: 'Share results',
            onPressed: _isLoading ? null : _showShareOptions,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: white),
            tooltip: 'Delete scan',
            onPressed: _isLoading ? null : _deleteScan,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: white,
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF1A73E9)),
              SizedBox(height: 16),
              Text('Loading scan…'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
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
                Text(
                  'Failed to load scan',
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
                    _loadScan();
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

    final dateStr = _scan != null
        ? DateFormat('MMMM d, y').format(_scan!.createdAt)
        : '';
    return Scaffold(
      backgroundColor: white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              '$dateStr Results',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height:10),
            Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _buildPatientSelector(),
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
                  child: _buildImageForIndex(_currentImageIndex),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Carousel navigation
            Row(
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
                ...List.generate(_camImageUrl != null ? 2 : 1, (i) {
                  final active = i == _currentImageIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _currentImageIndex = i),
                    child: Container(
                      width: active ? 12 : 10,
                      height: active ? 12 : 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? primaryBlue : const Color(0xFFCCCCCC),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_camImageUrl != null && _currentImageIndex < 1) {
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
            const SizedBox(height: 20),

            if (_result != null) _buildTextResult(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
// ── Patient picker bottom sheet ──────────────────────────────────────────────

class _PatientPickerSheet extends StatefulWidget {
  final List<Patient> patients;
  final String currentPatientId;
  final VoidCallback onAddPatient;

  const _PatientPickerSheet({
    required this.patients,
    required this.currentPatientId,
    required this.onAddPatient,
  });

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white       = Colors.white;

  final TextEditingController _search = TextEditingController();
  List<Patient> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.patients
        .where((p) => p.id != widget.currentPatientId)
        .toList();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _search.text.trim().toLowerCase();
    final base = widget.patients
        .where((p) => p.id != widget.currentPatientId)
        .toList();
    setState(() {
      _filtered = q.isEmpty
          ? base
          : base.where((p) => p.fullName.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Select Patient',
                      style: GoogleFonts.oswald(
                          fontSize: 18,
                          color: darkNavy,
                          letterSpacing: 1.2)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name…',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // List
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // Add new patient
                  ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryBlue.withValues(alpha: 0.12),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: primaryBlue, size: 20),
                    ),
                    title: Text('Add New Patient',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue)),
                    onTap: widget.onAddPatient,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No patients found.',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.black38)),
                      ),
                    )
                  else
                    ..._filtered.map((p) => ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: darkNavy,
                            child: Text(p.initials,
                                style: const TextStyle(
                                    color: white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p.fullName,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${p.age} yrs · ${p.sex}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.black54)),
                          onTap: () => Navigator.pop(context, p),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
