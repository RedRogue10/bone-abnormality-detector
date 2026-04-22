// import 'package:bone_abnormality_detector/pages/patient_info.dart';
import 'package:bone_abnormality_detector/pages/patient_info.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_patient.dart';
import '../services/database_service.dart';
import '../models/patient.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  // Colors
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  // static const Color altBlue = Color(0xFF276ED1);
  // static const Color darkRed = Color(0xFF833838);
  // static const Color orange = Color(0xFFD16227);
  static const Color gold = Color(0xFFD19527);
  // static const Color purple = Color(0xFF463883);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;
  static const Color bgGrey = Color(0xFFF0F0F0);

  // Sort Options
  static const List<String> _sortOptions = ['Name (A-Z)', 'Age', 'Date added'];
  String _selectedSort = 'Name (A-Z)';
  bool _showSortDropdown = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Patient> _applyFilters(List<Patient> list) {
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (_selectedSort == 'Name (A-Z)') {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else if (_selectedSort == 'Age') {
      list.sort((a, b) => a.age.compareTo(b.age));
    }

    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss dropdown when tapping elsewhere
      onTap: () {
        if (_showSortDropdown) {
          setState(() => _showSortDropdown = false);
        }
      },
      child: Scaffold(
        backgroundColor: white,
        // AppBar
        appBar: AppBar(
          backgroundColor: darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Patient List',
            style: GoogleFonts.oswald(
              color: white,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              width: 35,
              height: 35,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: white, size: 20),
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPatientPage()),
                  );
                  if (result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Patient successfully added"),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),

        // Body
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  // Recent / pinned patient card
                  StreamBuilder<List<Patient>>(
                    stream: DatabaseService().getPatientsStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox();
                      }

                      final patients = snapshot.data!;
                      return _buildRecentCard(patients.last);
                    },
                  ),
                  const SizedBox(height: 20),

                  // "All Patients" header + Sort button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Patients',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      _buildSortButton(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Patient list
                  Expanded(
                    child: StreamBuilder<List<Patient>>(
                      stream: DatabaseService().getPatientsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text("No patients found"));
                        }

                        final patients = snapshot.data!;
                        final filtered = _applyFilters(patients);

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _buildPatientCard(filtered[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Sort dropdown overlay
            if (_showSortDropdown) _buildSortDropdown(),
          ],
        ),
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search patient name',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: grey),
          prefixIcon: const Icon(Icons.search, color: grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  // Highlighted recent card
  Widget _buildRecentCard(Patient patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientInfoScreen(patientId: patient.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: darkNavy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: gold,
              child: Text(
                patient.initials,
                style: GoogleFonts.poppins(
                  color: white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: GoogleFonts.poppins(
                      color: white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${patient.age} years, ${patient.gender}',
                    style: GoogleFonts.poppins(
                      color: primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Today',
                  style: GoogleFonts.poppins(color: white, fontSize: 11),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.arrow_forward_ios, size: 14, color: white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Regular patient card
  Widget _buildPatientCard(Patient patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientInfoScreen(patientId: patient.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  primaryBlue, // You can customize color based on patient
              child: Text(
                patient.initials,
                style: GoogleFonts.poppins(
                  color: white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${patient.age} years, ${patient.gender}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Today', // You can calculate date added
                  style: GoogleFonts.poppins(color: grey, fontSize: 11),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.arrow_forward_ios, size: 13, color: grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sort button
  Widget _buildSortButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _showSortDropdown = !_showSortDropdown);
      },
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: grey, size: 18),
          const SizedBox(width: 4),
          Text(
            'Sort',
            style: GoogleFonts.poppins(
              color: grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Sort dropdown
  Widget _buildSortDropdown() {
    return Positioned(
      top: 230,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        color: white,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _sortOptions.map((option) {
              final bool selected = _selectedSort == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSort = option;
                    _showSortDropdown = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      if (selected)
                        const Icon(Icons.check, size: 16, color: primaryBlue)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: selected ? primaryBlue : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
