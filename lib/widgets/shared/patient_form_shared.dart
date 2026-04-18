import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientHistoryRecord {
  String date;
  String note;

  PatientHistoryRecord({required this.date, required this.note});

  Map<String, dynamic> toMap() => {'date': date, 'note': note};

  factory PatientHistoryRecord.fromMap(Map<String, dynamic> map) =>
      PatientHistoryRecord(date: map['date'], note: map['note']);
}

const _darkNavy = Color(0xFF0B2545);
const _primaryBlue = Color(0xFF1A73E9);
const _lightBlue = Color(0xFFB8D8F8);
const _fieldBg = Color(0xFFF0F0F0);
const _fieldBorder = Color(0xFFCCCCCC);
const _grey = Color(0xFF808080);

Widget sectionTitle(String title) =>
    Text(title, style: GoogleFonts.inter(color: _primaryBlue, fontSize: 18));

Widget sectionDivider() =>
    const Divider(color: _lightBlue, thickness: 1.2, height: 1);

OutlineInputBorder _border({Color color = _fieldBorder}) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(6),
  borderSide: BorderSide(color: color, width: 1.2),
);

String _monthName(int m) => [
  '',
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
][m];

Widget buildField({
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
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: isDate
                ? () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _primaryBlue,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      controller.text =
                          '${_monthName(picked.month)} ${picked.day}, ${picked.year}';
                      setState(() {});
                    }
                  }
                : null,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
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

Widget buildHistoryTile(
  PatientHistoryRecord rec, {
  required VoidCallback onDelete,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _fieldBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _fieldBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Date  ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(rec.date, style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline, size: 18, color: _grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Note',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rec.note,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
        ),
      ],
    ),
  );
}

Widget buildHistorySection({
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
      ...records.asMap().entries.map(
        (e) => buildHistoryTile(e.value, onDelete: () => onDelete(e.key)),
      ),
      buildField(
        context: context,
        label: 'Date',
        controller: dateCtrl,
        setState: setState,
        isDate: true,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          'Note',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
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
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: Text(
            'Add Record',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryBlue,
            ),
          ),
        ),
      ),
    ],
  );
}

AppBar buildAppBar({
  required BuildContext context,
  required Widget title,
  required String actionLabel,
  required Function()? onAction,
}) {
  return AppBar(
    backgroundColor: _darkNavy,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
      onPressed: () => Navigator.pop(context),
    ),
    title: title,
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
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Text(
            actionLabel,
            style: GoogleFonts.inter(fontSize: 14, letterSpacing: 1),
          ),
        ),
      ),
    ],
  );
}
