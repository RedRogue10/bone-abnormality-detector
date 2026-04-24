import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speedometer_chart/speedometer_chart.dart';

import '../models/scan_result.dart';
import '../models/xray_scan.dart';
import '../services/database_service.dart';

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
  static const Color darkRed     = Color(0xFF450B0B);
  static const Color green       = Color(0xFF0B4518);
  static const Color grey        = Color(0xFF808080);
  static const Color white       = Colors.white;
  static const Color bgGrey      = Color(0xFFF0F0F0);

  final DatabaseService _db = DatabaseService();

  XrayScan?   _scan;
  ScanResult? _result;
  String?     _errorMessage;
  bool        _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScan();
  }

  Future<void> _loadScan() async {
    try {
      final scan = await _db.getXrayScanById(widget.patientId, widget.scanId);
      if (mounted) setState(() { _scan = scan; _result = scan.result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

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

  Widget _buildNetworkImage() {
    final url = _scan?.imageUrl ?? '';
    if (url.isEmpty) {
      return const Icon(Icons.image_outlined, color: Colors.white38, size: 64);
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
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
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
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
        title: Text(
          'Scan Result',
          style: GoogleFonts.oswald(color: white, fontSize: 20, letterSpacing: 1.5),
        ),
        centerTitle: true,
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: darkNavy,
        appBar: _buildAppBar(darkNavy),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
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
                Text('Failed to load scan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: darkNavy),
                  onPressed: () {
                    setState(() { _errorMessage = null; _isLoading = true; });
                    _loadScan();
                  },
                  child: Text('Retry', style: GoogleFonts.poppins(color: white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAbnormal  = _result?.hasAbnormality ?? false;
    final headerColor = isAbnormal ? darkRed : green;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(headerColor),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header band ──────────────────────────────────────────
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                children: [
                  Text(
                    isAbnormal ? 'Abnormality Detected' : 'No Abnormality Detected',
                    style: GoogleFonts.oswald(fontSize: 24, color: white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_result != null) ...[
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
                ],
              ),
            ),

            // ── X-ray image ──────────────────────────────────────────
            GestureDetector(
              onTap: _showImageViewer,
              child: Container(
                width: double.infinity,
                height: 300,
                color: Colors.black,
                child: _buildNetworkImage(),
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
                    fontSize: 12, color: darkNavy, fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Bone part predictions ────────────────────────────────
            if (_result != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bone Part Detected',
                      style: GoogleFonts.inter(
                        fontSize: 18, color: primaryBlue, letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_result!.topPredictions.isEmpty)
                      Text('No predictions available.',
                          style: GoogleFonts.poppins(fontSize: 14, color: grey))
                    else
                      ..._result!.topPredictions.map((p) => _buildInfoRow(
                            p.bonePart[0].toUpperCase() + p.bonePart.substring(1),
                            '${(p.confidence * 100).toStringAsFixed(1)}% Confidence',
                          )),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
