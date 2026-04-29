import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/interpretation_preset.dart';
import '../pages/manage_presets.dart';
import '../services/database_service.dart';

class PresetPickerSheet extends StatefulWidget {
  const PresetPickerSheet({super.key});

  @override
  State<PresetPickerSheet> createState() => _PresetPickerSheetState();
}

class _PresetPickerSheetState extends State<PresetPickerSheet> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color white       = Colors.white;

  final DatabaseService _db = DatabaseService();
  List<InterpretationPreset> _presets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final presets = await _db.getPresets();
    if (mounted) setState(() { _presets = presets; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Interpretation Presets',
                      style: GoogleFonts.oswald(
                          fontSize: 18, color: darkNavy, letterSpacing: 1.2)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('Manage',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: primaryBlue),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManagePresetsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1A73E9)))
                  : _presets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.article_outlined,
                                  size: 48, color: Colors.black26),
                              const SizedBox(height: 10),
                              Text('No presets yet.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: Colors.black45)),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ManagePresetsPage()),
                                  );
                                },
                                child: Text('Create a preset',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: primaryBlue)),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _presets.length,
                          separatorBuilder: (_, _) => const Divider(
                              height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (_, i) {
                            final p = _presets[i];
                            return ListTile(
                              title: Text(p.title,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: darkNavy)),
                              subtitle: Text(p.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.black54)),
                              onTap: () => Navigator.pop(context, p.body),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
