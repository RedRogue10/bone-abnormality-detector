import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/scan_result.dart';
import '../models/xray_scan.dart';

import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/sharing_service.dart';
import '../services/email_service.dart';

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

  final DatabaseService _db = DatabaseService();
  final SharingService _ss = SharingService();

  XrayScan? _scan;
  ScanResult? _result;
  String? _errorMessage;
  bool _isLoading = true;

  int _currentImageIndex = 0;
  static const int _imageCount = 2;

  @override
  void initState() {
    super.initState();
    _loadScan();
  }

  Future<void> _loadScan() async {
    try {
      final scan = await _db.getXrayScanById(widget.patientId, widget.scanId);
      if (mounted) {
        setState(() {
          _scan = scan;
          _result = scan.result;
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

  void _showShareOptions() async {
    final patientDoc = await _db.getPatientById(widget.patientId);
    final patientEmail = patientDoc.email;
    print(patientEmail);

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
              // SEND TO EMAIL OPTION
              ListTile(
                enabled: hasEmail,
                leading: Icon(
                  Icons.email_outlined,
                  color: hasEmail ? Colors.black87 : Colors.grey,
                ),
                title: Text(
                  hasEmail
                      ? 'Send to patient email'
                      : 'No email available for this patient',
                  style: TextStyle(
                    color: hasEmail ? Colors.black87 : Colors.grey,
                  ),
                ),
                onTap: hasEmail
                    ? () {
                        Navigator.pop(context);
                        _sendEmailToPatient(patientEmail);
                      }
                    : null,
              ),

              // COPY LINK OPTION
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
    final link = await _ss.generateSecureLink(
      patientId: widget.patientId,
      scanId: widget.scanId,
    );
    await Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  void _sendEmailToPatient(String email) async {
    try {
      final link = await _ss.generateSecureLink(
        patientId: widget.patientId,
        scanId: widget.scanId,
      );
      await EmailService().sendEmailLink(email, link);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email sent to $email')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send email: $e')));
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
        '${((isAbnormal ? result.abnormalityConfidence : 1.0 - result.abnormalityConfidence) * 100).toStringAsFixed(1)}% Confidence';
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
    title: Text(
      'RESULTS',
      style: GoogleFonts.oswald(color: white, fontSize: 20, letterSpacing: 1.5),
    ),
    centerTitle: true,
    actions: [
      IconButton(
        icon: const Icon(Icons.ios_share, color: white),
        onPressed: _showShareOptions,
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
