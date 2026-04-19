import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scan_result.dart';
import '../services/model_processing.dart';

class ScanAnalysisPage extends StatefulWidget {
  final File imageFile;

  const ScanAnalysisPage({super.key, required this.imageFile});

  @override
  State<ScanAnalysisPage> createState() => _ScanAnalysisPageState();
}

class _ScanAnalysisPageState extends State<ScanAnalysisPage> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white       = Colors.white;

  final ModelProcessor _processor = ModelProcessor();
  ScanResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      final result = await _processor.analyzeImage(widget.imageFile);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ANALYSIS',
          style: GoogleFonts.oswald(
            color: white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _errorMessage != null
          ? _buildError()
          : _result == null
              ? _buildLoading()
              : _buildResult(),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _buildImagePreview(),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryBlue),
                SizedBox(height: 16),
                Text('Analysing image…'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
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
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() => _errorMessage = null);
                _runAnalysis();
              },
              style: ElevatedButton.styleFrom(backgroundColor: darkNavy),
              child: Text('Retry',
                  style: GoogleFonts.poppins(color: white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult() {
    final r = _result!;
    final abnormalityLabel =
        r.hasAbnormality ? 'ABNORMALITY DETECTED' : 'NO ABNORMALITY DETECTED';
    final confidencePct =
        '${(r.abnormalityConfidence * 100).toStringAsFixed(1)}% Confidence';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePreview(),
                const SizedBox(height: 20),

                // Abnormality verdict
                Center(
                  child: Text(
                    abnormalityLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: r.hasAbnormality ? Colors.red : primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    confidencePct,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 24),

                // Bone part predictions
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
                ...r.topPredictions.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            p.bonePart.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '${(p.confidence * 100).toStringAsFixed(1)}% Confidence',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: () {
                  // TODO: save scan to Firebase via DatabaseService
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkNavy,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Save',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        widget.imageFile,
        width: double.infinity,
        height: 280,
        fit: BoxFit.cover,
      ),
    );
  }
}
