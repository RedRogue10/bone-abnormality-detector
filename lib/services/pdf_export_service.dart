import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/patient.dart';
import '../models/scan_result.dart';
import '../models/xray_scan.dart';

class PdfExportService {
  // Match the app's colour palette
  static const _navy = PdfColor(0.043, 0.145, 0.271); // #0B2545
  static const _bg   = PdfColor(0.941, 0.941, 0.961); // #F0F0F5

  Future<({Uint8List bytes, String filename})> exportScanReport({
    required XrayScan scan,
    required ScanResult result,
    required Patient? patient,
  }) async {
    final doc = pw.Document();

    pw.MemoryImage? xrayImage;
    if (scan.imageUrl.isNotEmpty) {
      try {
        xrayImage = pw.MemoryImage(await _download(scan.imageUrl));
      } catch (_) {}
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (_) => _header(scan),
        footer: (ctx) => _footer(ctx),
        build: (_) => [
          if (patient != null) ...[
            _sectionLabel('PATIENT INFORMATION'),
            pw.SizedBox(height: 6),
            _patientBlock(patient),
            pw.SizedBox(height: 20),
          ],
          if (xrayImage != null) ...[
            _sectionLabel('X-RAY IMAGE'),
            pw.SizedBox(height: 6),
            _imageBlock(xrayImage),
            pw.SizedBox(height: 20),
          ],
          _sectionLabel('AI CLASSIFICATION REPORT'),
          pw.SizedBox(height: 6),
          _resultsBlock(result),
          if (result.interpretation.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionLabel('INTERPRETATION'),
            pw.SizedBox(height: 6),
            _interpretationBlock(result.interpretation),
          ],
        ],
      ),
    );

    final dateStr = DateFormat('yyyyMMdd').format(scan.createdAt);
    final namePart = patient != null
        ? patient.lastName.toLowerCase().replaceAll(' ', '_')
        : 'scan';
    final filename = 'xray_report_${namePart}_$dateStr.pdf';
    final bytes = await doc.save();
    return (bytes: bytes, filename: filename);
  }

  Future<String> savePdfToDownloads(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<Uint8List> _download(String url) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      return await consolidateHttpClientResponseBytes(res);
    } finally {
      client.close();
    }
  }

  // ── Page chrome ─────────────────────────────────────────────────────────────

  pw.Widget _header(XrayScan scan) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'XR-AID',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                ),
              ),
              pw.Text(
                'AI Radiology Report',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date of Scan',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                DateFormat('MMMM d, yyyy').format(scan.createdAt),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'AI-generated report. Must be reviewed by a qualified radiologist '
              'before any medical decisions are made.',
              style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey500,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────────

  pw.Widget _sectionLabel(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Patient block ────────────────────────────────────────────────────────────

  pw.Widget _patientBlock(Patient p) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          _row('Full Name', p.fullName),
          _row('Age', '${p.age} years old'),
          _row('Sex', p.sex),
          if (p.contactNumber?.isNotEmpty == true)
            _row('Contact', p.contactNumber!),
          if (p.address?.isNotEmpty == true) _row('Address', p.address!),
          if (p.email?.isNotEmpty == true) _row('Email', p.email!),
        ],
      ),
    );
  }

  pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(': ',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ── X-ray image block ────────────────────────────────────────────────────────

  pw.Widget _imageBlock(pw.MemoryImage img) {
    return pw.Center(
      child: pw.Container(
        constraints: const pw.BoxConstraints(maxHeight: 280),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Image(img, fit: pw.BoxFit.contain),
      ),
    );
  }

  // ── Results block ────────────────────────────────────────────────────────────

  pw.Widget _resultsBlock(ScanResult result) {
    final abnormalityPct =
        '${(result.abnormalityConfidence * 100).toStringAsFixed(1)}%';
    final top = result.topPredictions.isNotEmpty
        ? result.topPredictions.first
        : null;
    final boneName = top != null
        ? top.bonePart[0].toUpperCase() + top.bonePart.substring(1)
        : null;
    final bonePct = top != null
        ? '${(top.confidence * 100).toStringAsFixed(1)}%'
        : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _reportRow('Probability of Abnormality', abnormalityPct),
          if (boneName != null) ...[
            pw.SizedBox(height: 6),
            _reportRow('Bone Part Detected', boneName),
          ],
          if (boneName != null && bonePct != null) ...[
            pw.SizedBox(height: 6),
            _reportRow('Probability of "$boneName"', bonePct),
          ],
        ],
      ),
    );
  }

  pw.Widget _reportRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Text(
          ':  ',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── Interpretation block ─────────────────────────────────────────────────────

  pw.Widget _interpretationBlock(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
