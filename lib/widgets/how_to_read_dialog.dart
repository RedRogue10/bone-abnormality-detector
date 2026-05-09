import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/bone_thresholds.dart';

void showHowToReadDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How to Read This Report',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B2545),
              ),
            ),
            const SizedBox(height: 20),

            // ── Likelihood Score ─────────────────────────────────────────
            Text(
              'Likelihood Score',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The percentage is the AI\'s raw confidence that a bone '
              'abnormality is present. Each bone type has its own detection '
              'threshold — if the score meets or exceeds that threshold, the '
              'scan is flagged as showing possible signs of abnormality.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            _thresholdTable(),
            const SizedBox(height: 10),
            Text(
              'A score below the threshold is classified as no signs detected. '
              'At or above the threshold, signs of abnormality may be present.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black45,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 14),

            // ── Heatmap Legend ───────────────────────────────────────────
            Text(
              'Heat Map Legend',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The heat map overlaid on the X-ray shows which regions the AI '
              'focused on when making its classification.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            _heatmapScale(),

            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 10),

            // ── Disclaimer ───────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 15, color: Colors.black38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This is an AI-generated result and must be reviewed by a '
                    'qualified radiologist before any medical decisions are made.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Got it',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Threshold table ──────────────────────────────────────────────────────────

Widget _thresholdTable() {
  // Sorted by threshold ascending so the reader can see the range of values.
  final sorted = boneConfidenceThresholds.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(8),
    ),
    clipBehavior: Clip.antiAlias,
    child: Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
      },
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFEEF2F7)),
          children: [
            _cell('Bone Type', header: true),
            _cell('Detection Threshold', header: true),
          ],
        ),
        // Data rows
        ...sorted.map(
          (e) => TableRow(
            children: [
              _cell(e.key[0].toUpperCase() + e.key.substring(1)),
              _cell('${(e.value * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _cell(String text, {bool header = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: header ? FontWeight.w600 : FontWeight.normal,
        color: header ? Colors.black87 : Colors.black54,
      ),
    ),
  );
}

// ── Heatmap gradient scale ────────────────────────────────────────────────────

Widget _heatmapScale() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Gradient bar (jet colormap: blue → cyan → green → yellow → red)
      Container(
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0000C8), // dark blue  (low activation)
              Color(0xFF00FFFF), // cyan
              Color(0xFF00FF00), // green
              Color(0xFFFFFF00), // yellow
              Color(0xFFFF0000), // red        (high activation)
            ],
          ),
        ),
      ),
      const SizedBox(height: 5),
      // Axis labels
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Low',
              style:
                  GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
          Text('Moderate',
              style:
                  GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
          Text('High',
              style:
                  GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        'Warmer colors (yellow → red) mark the regions the AI focused on most '
        'when making its decision. Cooler colors (blue → green) indicate areas '
        'of lower interest.',
        style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
      ),
    ],
  );
}
