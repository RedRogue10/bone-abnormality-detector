import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/interpretation_preset.dart';
import '../services/database_service.dart';

class ManagePresetsPage extends StatefulWidget {
  const ManagePresetsPage({super.key});

  @override
  State<ManagePresetsPage> createState() => _ManagePresetsPageState();
}

class _ManagePresetsPageState extends State<ManagePresetsPage> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color white = Colors.white;

  final DatabaseService _db = DatabaseService();

  List<InterpretationPreset> _presets = [];
  bool _loading = true;
  bool _deleteMode = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final presets = await _db.getPresets();
    if (mounted)
      setState(() {
        _presets = presets;
        _loading = false;
      });
  }

  Future<void> _showForm({InterpretationPreset? preset}) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PresetFormSheet(preset: preset, db: _db),
    );
    if (result == true || result == 'deleted') {
      if (result == 'deleted' && preset != null) {
        await _db.deletePreset(preset.id);
      }
      await _load();
    }
  }

  void _enterDeleteMode() => setState(() {
    _deleteMode = true;
    _selected.clear();
  });

  void _exitDeleteMode() => setState(() {
    _deleteMode = false;
    _selected.clear();
  });

  void _toggleSelect(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete $count preset${count > 1 ? 's' : ''}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently remove the selected preset${count > 1 ? 's' : ''}.',
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
    for (final id in _selected) {
      await _db.deletePreset(id);
    }
    _exitDeleteMode();
    await _load();
  }

  Future<void> _delete(InterpretationPreset preset) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete preset?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '"${preset.title}" will be permanently removed.',
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
    if (confirm == true) {
      await _db.deletePreset(preset.id);
      await _load();
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
          icon: Icon(
            _deleteMode ? Icons.close : Icons.chevron_left,
            color: white,
            size: 28,
          ),
          onPressed: _deleteMode
              ? _exitDeleteMode
              : () => Navigator.pop(context),
        ),
        title: Text(
          _deleteMode
              ? '${_selected.length} selected'
              : 'Interpretation Presets',
          style: GoogleFonts.oswald(
            color: white,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_deleteMode && _presets.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: white),
              tooltip: 'Delete presets',
              onPressed: _enterDeleteMode,
            ),
          if (_deleteMode)
            TextButton(
              onPressed: _selected.isEmpty ? null : _deleteSelected,
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: _selected.isEmpty
                      ? Colors.white38
                      : Colors.red.shade300,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _deleteMode
          ? null
          : FloatingActionButton(
              backgroundColor: darkNavy,
              foregroundColor: white,
              onPressed: () => _showForm(),
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A73E9)),
            )
          : _presets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 56,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No presets yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to create your first template.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = _presets[i];
                final isSelected = _selected.contains(p.id);

                if (_deleteMode) {
                  return GestureDetector(
                    onTap: () => _toggleSelect(p.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.shade50
                            : const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.red.shade300
                              : Colors.black12,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.red
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? Colors.red : Colors.black38,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: white,
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _delete(p);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: darkNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.black45,
                          ),
                          onPressed: () => _showForm(preset: p),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Form sheet ───────────────────────────────────────────────────────────────
// StatefulWidget owns controllers so Flutter disposes them after the dismiss
// animation finishes — avoids "controller used after disposed" crashes.

class _PresetFormSheet extends StatefulWidget {
  final InterpretationPreset? preset;
  final DatabaseService db;

  const _PresetFormSheet({this.preset, required this.db});

  @override
  State<_PresetFormSheet> createState() => _PresetFormSheetState();
}

class _PresetFormSheetState extends State<_PresetFormSheet> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color white = Colors.white;
  static const Color bgGrey = Color(0xFFF0F0F0);

  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.preset?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.preset?.body ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // Future<void> _delete() async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: Text('Delete preset?',
  //           style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
  //       content: Text('"${widget.preset!.title}" will be permanently removed.',
  //           style: GoogleFonts.poppins(fontSize: 13)),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, false),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, true),
  //           child: const Text('Delete', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  //   if (confirm == true && mounted) Navigator.pop(context, 'deleted');
  // }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.preset == null) {
        await widget.db.addPreset(title, body);
      } else {
        await widget.db.updatePreset(widget.preset!.id, title, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read keyboard inset from this widget's own context — always accurate.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.preset == null ? 'New Preset' : 'Edit Preset',
              style: GoogleFonts.oswald(
                fontSize: 18,
                color: darkNavy,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Title',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Normal — No Findings',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black38,
                ),
                filled: true,
                fillColor: bgGrey,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),

            Text(
              'Template Text',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _bodyCtrl,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write the default interpretation text…',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black38,
                ),
                filled: true,
                fillColor: bgGrey,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkNavy,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
