import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/scan_result.dart';
import '../models/xray_scan.dart';
import '../services/database_service.dart';
import '../services/email_service.dart';
import '../services/sharing_service.dart';

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
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white       = Colors.white;

  final DatabaseService       _db                 = DatabaseService();
  final TextEditingController _interpretationCtrl = TextEditingController();

  XrayScan?   _scan;
  ScanResult? _result;
  Uint8List?  _camImageBytes;
  String?     _errorMessage;
  bool        _isLoading   = true;
  bool        _sharing     = false;
  bool        _savingNote  = false;

  int _currentImageIndex = 0;
  static const int _imageCount = 2;

  @override
  void initState() {
    super.initState();
    _loadScan();
  }

  @override
  void dispose() {
    _interpretationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadScan() async {
    try {
      final scan = await _db.getXrayScanById(widget.patientId, widget.scanId);
      Uint8List? camBytes;
      final camUrl = scan.result?.generatedImageUrls.isNotEmpty == true
          ? scan.result!.generatedImageUrls.first
          : null;
      if (camUrl != null) {
        try {
          final request = await HttpClient().getUrl(Uri.parse(camUrl));
          final response = await request.close();
          camBytes = await consolidateHttpClientResponseBytes(response);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _scan = scan;
          _result = scan.result;
          _camImageBytes = camBytes;
          _isLoading = false;
        });
        _interpretationCtrl.text = scan.result?.interpretation ?? '';
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
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

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final doctorId = FirebaseAuth.instance.currentUser!.uid;
      final link = await SharingService().generateSecureLink(
        doctorId: doctorId,
        patientId: widget.patientId,
        scanId: widget.scanId,
      );
      if (!mounted) return;
      _showShareSheet(link);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate link: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _showShareSheet(String link) {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Share Results',
                  style: GoogleFonts.oswald(
                      fontSize: 18,
                      color: darkNavy,
                      letterSpacing: 1.2)),
              const SizedBox(height: 16),

              // Link row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(link,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black54)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied.')),
                        );
                      },
                      child: const Icon(Icons.copy_rounded,
                          size: 18, color: primaryBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Send via email',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'patient@email.com',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.black38),
                        filled: true,
                        fillColor: const Color(0xFFF0F0F0),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkNavy,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        await EmailService().sendEmailLink(email, link);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Results sent to patient.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Email failed: $e')),
                          );
                        }
                      }
                    },
                    child: Text('Send',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                      color: Colors.black.withValues(alpha: 0.55)),
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
                          child: _buildNetworkImage(),
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

  Widget _buildImageForIndex(int index) {
    if (index == 0) return _buildNetworkImage();

    if (_camImageBytes != null) {
      return Image.memory(_camImageBytes!, fit: BoxFit.contain);
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, color: Colors.white38, size: 64),
          SizedBox(height: 12),
          Text('CAM overlay not available',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
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
      errorBuilder: (context, error, stack) =>
          const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
    );
  }

  Widget _buildBonePart(String label, String confidence) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
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
    final confidenceText = '${(result.abnormalityConfidence * 100).toStringAsFixed(1)}% Abnormality Confidence';
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
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.black87)),
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
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 16),
        Text('INTERPRETATION',
            style: GoogleFonts.oswald(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2)),
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
          if (_sharing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.share_outlined, color: white),
              tooltip: 'Share results',
              onPressed: _isLoading ? null : _share,
            ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: white),
            onPressed: () {},
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
                Text('Failed to load scan',
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
                    _loadScan();
                  },
                  child: Text('Retry',
                      style: GoogleFonts.poppins(color: white)),
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
            Text('$dateStr Results',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.black87)),
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
                  child: const Icon(Icons.chevron_left,
                      color: Colors.black54, size: 24),
                ),
                const SizedBox(width: 8),
                ...List.generate(_imageCount, (i) {
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
                    if (_currentImageIndex < _imageCount - 1) {
                      setState(() => _currentImageIndex++);
                    }
                  },
                  child: const Icon(Icons.chevron_right,
                      color: Colors.black54, size: 24),
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
