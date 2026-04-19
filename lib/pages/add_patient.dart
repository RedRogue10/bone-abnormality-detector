import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bone_abnormality_detector/widgets/shared/patient_form_shared.dart';
import '../services/database_service.dart';
import '../models/patient.dart';
import '../models/emergency_contact.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});
  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _sexCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _historyDateCtrl = TextEditingController();
  final _historyNoteCtrl = TextEditingController();
  final _ecNameCtrl = TextEditingController();
  final _ecContactCtrl = TextEditingController();
  final _ecRelationshipCtrl = TextEditingController();
  final List<PatientHistoryRecord> _historyRecords = [];

  // Default
  String selectedSex = "Male";
  DateTime selectedDate = DateTime.now();

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split(' ');
    final month = parts[0];
    final day = int.parse(parts[1].replaceAll(',', ''));
    final year = int.parse(parts[2]);
    final monthNum = _monthNames.indexOf(month) + 1;
    return DateTime(year, monthNum, day);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final patient = Patient(
        id: '',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim().isEmpty
            ? null
            : _middleNameCtrl.text.trim(),
        sex: _sexCtrl.text.trim(),
        birthDate: _parseDate(_dobCtrl.text.trim()),
        contactNumber: _contactCtrl.text.trim().isEmpty
            ? null
            : _contactCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        emergencyContact:
            (_ecNameCtrl.text.trim().isEmpty &&
                _ecContactCtrl.text.trim().isEmpty &&
                _ecRelationshipCtrl.text.trim().isEmpty)
            ? null
            : EmergencyContact(
                name: _ecNameCtrl.text.trim(),
                contactNumber: _ecContactCtrl.text.trim(),
                relationship: _ecRelationshipCtrl.text.trim(),
              ),
        historyRecords: _historyRecords,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseService().addPatient(patient);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient added successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add patient: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

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
        onAction: _isSaving ? null : _save,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
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
              _field('Email', _emailCtrl),
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
      ),
    );
  }
}
