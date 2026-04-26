import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bone_abnormality_detector/widgets/shared/patient_form_shared.dart';
import '../services/database_service.dart';
import '../models/patient.dart';
import '../models/emergency_contact.dart';

class EditPatientPage extends StatefulWidget {
  final String patientId;

  const EditPatientPage({super.key, required this.patientId});

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  Patient? _patient;
  bool _isLoading = true;

  late final TextEditingController _firstNameCtrl = TextEditingController();
  late final TextEditingController _lastNameCtrl = TextEditingController();
  late final TextEditingController _middleNameCtrl = TextEditingController();
  String selectedGender = 'Male';
  late final TextEditingController _dobCtrl = TextEditingController();
  late final TextEditingController _contactCtrl = TextEditingController();
  late final TextEditingController _emailCtrl = TextEditingController();
  late final TextEditingController _addressCtrl = TextEditingController();
  late final TextEditingController _ecNameCtrl = TextEditingController();
  late final TextEditingController _ecContactCtrl = TextEditingController();
  late final TextEditingController _ecRelationshipCtrl =
      TextEditingController();
  final _historyDateCtrl = TextEditingController();
  final _historyNoteCtrl = TextEditingController();
  late List<PatientHistoryRecord> _historyRecords;

  static const _deleteRed = Color(0xFF450B0B);
  static const _grey = Color(0xFF808080);

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    print('Loading patient with ID: ${widget.patientId}');
    try {
      _patient = await DatabaseService().getPatientById(widget.patientId);
      _firstNameCtrl.text = _patient!.firstName;
      _lastNameCtrl.text = _patient!.lastName;
      _middleNameCtrl.text = _patient!.middleName ?? '';
      selectedGender = _patient!.sex;
      _dobCtrl.text = _formatDate(_patient!.birthDate);
      _contactCtrl.text = _patient!.contactNumber ?? '';
      _addressCtrl.text = _patient!.address ?? '';
      _ecNameCtrl.text = _patient!.emergencyContact?.name ?? '';
      _ecContactCtrl.text = _patient!.emergencyContact?.contactNumber ?? '';
      _ecRelationshipCtrl.text = _patient!.emergencyContact?.relationship ?? '';
      _historyRecords = List.from(_patient!.historyRecords);
      setState(() => _isLoading = false);
    } catch (e) {
      // Handle error, perhaps show snackbar and pop
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load patient: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _middleNameCtrl,
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

  String _formatDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final patient = Patient(
        id: widget.patientId,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim().isEmpty
            ? null
            : _middleNameCtrl.text.trim(),
        sex: selectedGender,
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
        createdAt: _patient!.createdAt,
        updatedAt: DateTime.now(),
      );
      await DatabaseService().updatePatient(patient);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update patient: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
            DatabaseService().deletePatient(widget.patientId);
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

  Widget _buildGenderField() {
    const Color darkNavy    = Color(0xFF0B2545);
    const Color primaryBlue = Color(0xFF1A73E9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sex*',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['Male', 'Female'].map((option) {
              final selected = selectedGender == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedGender = option),
                  child: Container(
                    margin: EdgeInsets.only(right: option == 'Male' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryBlue.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? primaryBlue : const Color(0xFFDDE6F0),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: selected ? primaryBlue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected ? primaryBlue : darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(
        context: context,
        title: Text(
          'Edit Patient Info',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actionLabel: 'UPDATE',
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
              _buildGenderField(),
              _field('Date of Birth*', _dobCtrl, isDate: true),
              _field(
                'Contact Number',
                _contactCtrl,
                keyboardType: TextInputType.phone,
              ),
              _field(
                'Email',
                _emailCtrl,
                keyboardType: TextInputType.emailAddress,
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
      ),
    );
  }
}