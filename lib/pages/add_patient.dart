import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bone_abnormality_detector/widgets/shared/patient_form_shared.dart';
import 'edit_patient.dart';

// Add Patient Page
class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});
  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _sexCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _historyDateCtrl = TextEditingController();
  final _historyNoteCtrl = TextEditingController();
  final _ecNameCtrl = TextEditingController();
  final _ecContactCtrl = TextEditingController();
  final _ecRelationshipCtrl = TextEditingController();
  final List<PatientHistoryRecord> _historyRecords = [];

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

  void _save() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => EditPatientPage(
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        middleName: _middleNameCtrl.text,
        sex: _sexCtrl.text,
        dob: _dobCtrl.text,
        contactNumber: _contactCtrl.text,
        address: _addressCtrl.text,
        historyRecords: List.from(_historyRecords),
        ecName: _ecNameCtrl.text,
        ecContact: _ecContactCtrl.text,
        ecRelationship: _ecRelationshipCtrl.text,
      ),
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
          'Add Patient',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        actionLabel: 'SAVE',
        onAction: _save,
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
            sectionTitle('Patient History(Optional)'),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

