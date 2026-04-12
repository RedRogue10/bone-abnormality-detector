import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientHistoryRecord {
  String date;
  String note;
  PatientHistoryRecord({required this.date, required this.note});
}

// Shared colors 
const _darkNavy    = Color(0xFF0B2545);
const _primaryBlue = Color(0xFF1A73E9);
const _lightBlue   = Color(0xFFB8D8F8);
const _fieldBg     = Color(0xFFF0F0F0);
const _fieldBorder = Color(0xFFCCCCCC);
const _grey        = Color(0xFF808080);
const _deleteRed   = Color(0xFF833838);

// Shared helper widgets
Widget _sectionTitle(String title) => Text(title,
    style: GoogleFonts.poppins(
        color: _primaryBlue, fontWeight: FontWeight.w700, fontSize: 14));

Widget _divider() =>
    const Divider(color: _lightBlue, thickness: 1.2, height: 1);

OutlineInputBorder _border({Color color = _fieldBorder}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: color, width: 1.2));

String _monthName(int m) =>
    ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];

Widget _buildField({
  required BuildContext context,
  required String label,
  required TextEditingController controller,
  required void Function(VoidCallback) setState,
  TextInputType keyboardType = TextInputType.text,
  bool isDate = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 118,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: isDate ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: _primaryBlue),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                controller.text =
                    '${_monthName(picked.month)} ${picked.day}, ${picked.year}';
                setState(() {});
              }
            } : null,
            child: AbsorbPointer(
              absorbing: isDate,
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _fieldBg,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  border: _border(),
                  enabledBorder: _border(),
                  focusedBorder: _border(color: _primaryBlue),
                  suffixIcon: isDate
                      ? const Icon(Icons.calendar_today, size: 14, color: _grey)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildHistoryTile(PatientHistoryRecord rec,
    {required VoidCallback onDelete}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _fieldBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _fieldBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Row(children: [
          Text('Date  ',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700)),
          Text(rec.date, style: GoogleFonts.poppins(fontSize: 12)),
        ])),
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.delete_outline, size: 18, color: _grey),
        ),
      ]),
      const SizedBox(height: 6),
      Text('Note',
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(rec.note,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
    ]),
  );
}

Widget _buildHistorySection({
  required BuildContext context,
  required List<PatientHistoryRecord> records,
  required TextEditingController dateCtrl,
  required TextEditingController noteCtrl,
  required VoidCallback onAdd,
  required void Function(VoidCallback) setState,
  required void Function(int) onDelete,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...records.asMap().entries.map((e) =>
          _buildHistoryTile(e.value, onDelete: () => onDelete(e.key))),
      _buildField(
          context: context,
          label: 'Date',
          controller: dateCtrl,
          setState: setState,
          isDate: true),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('Note',
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      Container(
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _fieldBorder),
        ),
        child: TextField(
          controller: noteCtrl,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.all(10),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryBlue,
            side: const BorderSide(color: _primaryBlue, width: 1.2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: Text('Add Record',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue)),
        ),
      ),
    ],
  );
}

Widget _buildPhotoWidget({required bool editable}) {
  return Center(
    child: GestureDetector(
      onTap: editable ? () {} : null,
      child: Column(children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _fieldBg,
            border: Border.all(color: _fieldBorder, width: 1.5),
          ),
          child: const Icon(Icons.person_outline, size: 48, color: _darkNavy),
        ),
        const SizedBox(height: 6),
        Text(editable ? 'Upload Photo' : 'Edit Photo',
            style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
      ]),
    ),
  );
}

AppBar _buildAppBar({
  required BuildContext context,
  required String title,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  return AppBar(
    backgroundColor: _darkNavy,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(title,
        style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.5)),
    centerTitle: true,
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 12),
        child: ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text(actionLabel,
              style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
      ),
    ],
  );
}

// Add Patient Page 
class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});
  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _firstNameCtrl      = TextEditingController();
  final _lastNameCtrl       = TextEditingController();
  final _middleNameCtrl     = TextEditingController();
  final _sexCtrl            = TextEditingController();
  final _dobCtrl            = TextEditingController();
  final _contactCtrl        = TextEditingController();
  final _addressCtrl        = TextEditingController();
  final _historyDateCtrl    = TextEditingController();
  final _historyNoteCtrl    = TextEditingController();
  final _ecNameCtrl         = TextEditingController();
  final _ecContactCtrl      = TextEditingController();
  final _ecRelationshipCtrl = TextEditingController();
  final List<PatientHistoryRecord> _historyRecords = [];

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _middleNameCtrl, _sexCtrl, _dobCtrl,
      _contactCtrl, _addressCtrl, _historyDateCtrl, _historyNoteCtrl,
      _ecNameCtrl, _ecContactCtrl, _ecRelationshipCtrl,
    ]) c.dispose();
    super.dispose();
  }

  void _addRecord() {
    final date = _historyDateCtrl.text.trim();
    final note = _historyNoteCtrl.text.trim();
    if (date.isEmpty && note.isEmpty) return;
    setState(() {
      _historyRecords.add(PatientHistoryRecord(date: date, note: note));
      _historyDateCtrl.clear();
      _historyNoteCtrl.clear();
    });
  }

  void _save() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => EditPatientPage(
        firstName:      _firstNameCtrl.text,
        lastName:       _lastNameCtrl.text,
        middleName:     _middleNameCtrl.text,
        sex:            _sexCtrl.text,
        dob:            _dobCtrl.text,
        contactNumber:  _contactCtrl.text,
        address:        _addressCtrl.text,
        historyRecords: List.from(_historyRecords),
        ecName:         _ecNameCtrl.text,
        ecContact:      _ecContactCtrl.text,
        ecRelationship: _ecRelationshipCtrl.text,
      ),
    ),
  );

  Widget _field(String label, TextEditingController ctrl,
          {TextInputType keyboardType = TextInputType.text,
          bool isDate = false}) =>
      _buildField(
          context: context,
          label: label,
          controller: ctrl,
          setState: setState,
          keyboardType: keyboardType,
          isDate: isDate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(
          context: context,
          title: 'Add Patient',
          actionLabel: 'SAVE',
          onAction: _save),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildPhotoWidget(editable: true),
          const SizedBox(height: 28),
          _sectionTitle('Personal Information'),
          const SizedBox(height: 12),
          _field('First Name*',    _firstNameCtrl),
          _field('Last Name*',     _lastNameCtrl),
          _field('Middle Name',    _middleNameCtrl),
          _field('Sex*',           _sexCtrl),
          _field('Date of Birth*', _dobCtrl, isDate: true),
          _field('Contact Number', _contactCtrl,
              keyboardType: TextInputType.phone),
          _field('Address',        _addressCtrl),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 20),
          _sectionTitle('Patient History(Optional)'),
          const SizedBox(height: 12),
          _buildHistorySection(
            context: context,
            records: _historyRecords,
            dateCtrl: _historyDateCtrl,
            noteCtrl: _historyNoteCtrl,
            onAdd: _addRecord,
            setState: setState,
            onDelete: (i) => setState(() => _historyRecords.removeAt(i)),
          ),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 20),
          _sectionTitle('Emergency Contact'),
          const SizedBox(height: 12),
          _field('Name',           _ecNameCtrl),
          _field('Contact Number', _ecContactCtrl,
              keyboardType: TextInputType.phone),
          _field('Relationship',   _ecRelationshipCtrl),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// Edit / View Patient Page 
class EditPatientPage extends StatefulWidget {
  final String firstName, lastName, middleName, sex, dob;
  final String contactNumber, address;
  final List<PatientHistoryRecord> historyRecords;
  final String ecName, ecContact, ecRelationship;

  const EditPatientPage({
    super.key,
    required this.firstName, required this.lastName, required this.middleName,
    required this.sex, required this.dob, required this.contactNumber,
    required this.address, required this.historyRecords,
    required this.ecName, required this.ecContact, required this.ecRelationship,
  });

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _middleNameCtrl;
  late final TextEditingController _sexCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _ecNameCtrl;
  late final TextEditingController _ecContactCtrl;
  late final TextEditingController _ecRelationshipCtrl;
  final _historyDateCtrl = TextEditingController();
  final _historyNoteCtrl = TextEditingController();
  late List<PatientHistoryRecord> _historyRecords;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl      = TextEditingController(text: widget.firstName);
    _lastNameCtrl       = TextEditingController(text: widget.lastName);
    _middleNameCtrl     = TextEditingController(text: widget.middleName);
    _sexCtrl            = TextEditingController(text: widget.sex);
    _dobCtrl            = TextEditingController(text: widget.dob);
    _contactCtrl        = TextEditingController(text: widget.contactNumber);
    _addressCtrl        = TextEditingController(text: widget.address);
    _ecNameCtrl         = TextEditingController(text: widget.ecName);
    _ecContactCtrl      = TextEditingController(text: widget.ecContact);
    _ecRelationshipCtrl = TextEditingController(text: widget.ecRelationship);
    _historyRecords     = List.from(widget.historyRecords);
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _middleNameCtrl, _sexCtrl, _dobCtrl,
      _contactCtrl, _addressCtrl, _historyDateCtrl, _historyNoteCtrl,
      _ecNameCtrl, _ecContactCtrl, _ecRelationshipCtrl,
    ]) c.dispose();
    super.dispose();
  }

  void _addRecord() {
    final date = _historyDateCtrl.text.trim();
    final note = _historyNoteCtrl.text.trim();
    if (date.isEmpty && note.isEmpty) return;
    setState(() {
      _historyRecords.add(PatientHistoryRecord(date: date, note: note));
      _historyDateCtrl.clear();
      _historyNoteCtrl.clear();
    });
  }

  void _deletePatient() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Delete Patient',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Text('Are you sure you want to delete this patient?',
          style: GoogleFonts.poppins(fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins(color: _grey)),
        ),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: _deleteRed),
          child: Text('Delete',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  Widget _field(String label, TextEditingController ctrl,
          {TextInputType keyboardType = TextInputType.text,
          bool isDate = false}) =>
      _buildField(
          context: context,
          label: label,
          controller: ctrl,
          setState: setState,
          keyboardType: keyboardType,
          isDate: isDate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(
        context: context,
        title: 'Edit Patient',
        actionLabel: 'UPDATE',
        onAction: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Patient updated!', style: GoogleFonts.poppins()),
          backgroundColor: _primaryBlue,
          duration: const Duration(seconds: 2),
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildPhotoWidget(editable: false),
          const SizedBox(height: 28),
          _sectionTitle('Personal Information'),
          const SizedBox(height: 12),
          _field('First Name*',    _firstNameCtrl),
          _field('Last Name*',     _lastNameCtrl),
          _field('Middle Name',    _middleNameCtrl),
          _field('Sex*',           _sexCtrl),
          _field('Date of Birth*', _dobCtrl, isDate: true),
          _field('Contact Number', _contactCtrl,
              keyboardType: TextInputType.phone),
          _field('Address',        _addressCtrl),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 20),
          _sectionTitle('Patient History'),
          const SizedBox(height: 12),
          _buildHistorySection(
            context: context,
            records: _historyRecords,
            dateCtrl: _historyDateCtrl,
            noteCtrl: _historyNoteCtrl,
            onAdd: _addRecord,
            setState: setState,
            onDelete: (i) => setState(() => _historyRecords.removeAt(i)),
          ),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 20),
          _sectionTitle('Emergency Contact'),
          const SizedBox(height: 12),
          _field('Name',           _ecNameCtrl),
          _field('Contact Number', _ecContactCtrl,
              keyboardType: TextInputType.phone),
          _field('Relationship',   _ecRelationshipCtrl),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: _deletePatient,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text('DELETE PATIENT',
                  style: GoogleFonts.oswald(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _deleteRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}