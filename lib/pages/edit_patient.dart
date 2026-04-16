import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bone_abnormality_detector/widgets/shared/patient_form_shared.dart';

class EditPatientPage extends StatefulWidget {
  final String firstName, lastName, middleName, sex, dob;
  final String contactNumber, address;
  final List<PatientHistoryRecord> historyRecords;
  final String ecName, ecContact, ecRelationship;

  const EditPatientPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.sex,
    required this.dob,
    required this.contactNumber,
    required this.address,
    required this.historyRecords,
    required this.ecName,
    required this.ecContact,
    required this.ecRelationship,
  });

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  // Placeholder, in real app it should get patient id
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

  static const _deleteRed = Color(0xFF450B0B);
  static const _primaryBlue = Color(0xFF1A73E9);
  static const _grey = Color(0xFF808080);

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.firstName);
    _lastNameCtrl = TextEditingController(text: widget.lastName);
    _middleNameCtrl = TextEditingController(text: widget.middleName);
    _sexCtrl = TextEditingController(text: widget.sex);
    _dobCtrl = TextEditingController(text: widget.dob);
    _contactCtrl = TextEditingController(text: widget.contactNumber);
    _addressCtrl = TextEditingController(text: widget.address);
    _ecNameCtrl = TextEditingController(text: widget.ecName);
    _ecContactCtrl = TextEditingController(text: widget.ecContact);
    _ecRelationshipCtrl = TextEditingController(text: widget.ecRelationship);
    _historyRecords = List.from(widget.historyRecords);
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _middleNameCtrl,
      _sexCtrl,
      _dobCtrl,
      _contactCtrl,
      _addressCtrl,
      _historyDateCtrl,
      _historyNoteCtrl,
      _ecNameCtrl,
      _ecContactCtrl,
      _ecRelationshipCtrl,
    ])
      c.dispose();
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
      title: Text(
        'Delete Patient',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Are you sure you want to delete this patient?',
        style: GoogleFonts.poppins(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins(color: _grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _deleteRed),
          child: Text(
            'Delete',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
    bool isDate = false,
  }) => buildField(
    context: context,
    label: label,
    controller: ctrl,
    setState: setState,
    keyboardType: keyboardType,
    isDate: isDate,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(
        context: context,
        title: Text(
          'Edit Patient Info',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        actionLabel: 'UPDATE',
        onAction: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient updated!', style: GoogleFonts.poppins()),
            backgroundColor: _primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            sectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _field('First Name*', _firstNameCtrl),
            _field('Last Name*', _lastNameCtrl),
            _field('Middle Name', _middleNameCtrl),
            _field('Sex*', _sexCtrl),
            _field('Date of Birth*', _dobCtrl, isDate: true),
            _field(
              'Contact Number',
              _contactCtrl,
              keyboardType: TextInputType.phone,
            ),
            _field('Address', _addressCtrl),
            const SizedBox(height: 12),
            sectionDivider(),
            const SizedBox(height: 20),
            sectionTitle('Patient History'),
            const SizedBox(height: 12),
            buildHistorySection(
              context: context,
              records: _historyRecords,
              dateCtrl: _historyDateCtrl,
              noteCtrl: _historyNoteCtrl,
              onAdd: _addRecord,
              setState: setState,
              onDelete: (i) => setState(() => _historyRecords.removeAt(i)),
            ),
            const SizedBox(height: 12),
            sectionDivider(),
            const SizedBox(height: 20),
            sectionTitle('Emergency Contact'),
            const SizedBox(height: 12),
            _field('Name', _ecNameCtrl),
            _field(
              'Contact Number',
              _ecContactCtrl,
              keyboardType: TextInputType.phone,
            ),
            _field('Relationship', _ecRelationshipCtrl),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _deletePatient,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  'DELETE PATIENT',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _deleteRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
