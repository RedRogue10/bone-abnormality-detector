import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../pages/xray_result.dart';

class AllScansPage extends StatefulWidget {
  const AllScansPage({super.key});

  @override
  State<AllScansPage> createState() => _AllScansPageState();
}

class _AllScansPageState extends State<AllScansPage> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color bgGrey = Color(0xFFF0F0F0);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;

  static const List<String> _sortOptions = ['Newest', 'Oldest'];

  final _searchCtrl = TextEditingController();

  final Future<List<Map<String, dynamic>>> _scansFuture = DatabaseService()
      .fetchAllScans();
  List<Map<String, dynamic>> _allScans = [];
  List<Map<String, dynamic>> _filtered = [];

  String _selectedSort = 'Newest';
  bool _showSortDropdown = false;
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  TextStyle poppins({
    double size = 14,
    Color color = Colors.black87,
    FontWeight weight = FontWeight.normal,
  }) => GoogleFonts.poppins(fontSize: size, color: color, fontWeight: weight);

  void _applyFilters() {
    setState(() {
      var result = [..._allScans];

      if (_searchQuery.isNotEmpty) {
        result = result
            .where(
              (s) => (s['name'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();
      }

      result.sort((a, b) {
        final dateA = a['date'] as DateTime;
        final dateB = b['date'] as DateTime;
        return _selectedSort == 'Newest'
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      });

      _filtered = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showSortDropdown) setState(() => _showSortDropdown = false);
      },
      child: Scaffold(
        backgroundColor: white,
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _scansFuture,
          builder: (context, snapshot) {
            // Handle Loading
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: primaryBlue),
              );
            }

            // Handle Error
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: poppins()),
              );
            }

            // Handle Success & Data Population
            if (snapshot.hasData && !_isInitialized) {
              _allScans = snapshot.data!;
              _filtered = [..._allScans];
              // Initial Sort
              _filtered.sort(
                (a, b) =>
                    (b['date'] as DateTime).compareTo(a['date'] as DateTime),
              );
              _isInitialized = true;
            }

            final pinned = _filtered.isNotEmpty ? _filtered.first : null;
            final theRest = _filtered.length > 1
                ? List<Map<String, dynamic>>.from(_filtered.sublist(1))
                : <Map<String, dynamic>>[];
            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    _buildControlsAndPinned(pinned),
                    _buildScanList(theRest),
                  ],
                ),
                if (_showSortDropdown) _buildSortDropdown(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: darkNavy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'All Scans',
                    style: GoogleFonts.oswald(color: white, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsAndPinned(Map<String, dynamic>? pinned) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search scans',
                prefixIcon: const Icon(Icons.search, color: grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (pinned != null) ...[
            _buildScanTile(pinned, isPinned: true),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'History',
                style: poppins(size: 15, weight: FontWeight.w600),
              ),
              _buildSortButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanList(List<Map<String, dynamic>> theRest) {
    return Expanded(
      child: _filtered.isEmpty
          ? Center(
              child: Text('No scans found.', style: poppins(color: grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: theRest.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildScanTile(theRest[i]),
            ),
    );
  }

  Widget _buildScanTile(Map<String, dynamic> scan, {bool isPinned = false}) {
    final bgColor = isPinned ? darkNavy : bgGrey;
    final textColor = isPinned ? white : Colors.black87;

    return InkWell(
      onTap: () async {
        await DatabaseService().logRecentScanView(
          scanId: scan['scanId'],
          patientId: scan['patientId'],
          patientName: scan['name'],
          imageUrl: scan['imageUrl'],
          scanDate: scan['date'],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => XrayResultPage(
              patientId: scan['patientId'],
              scanId: scan['scanId'],
            ),
          ),
        );
      },
      child: Container(
        height: isPinned ? 80 : 72,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            SizedBox(
              width: isPinned ? 75 : 72,
              child: scan['imageUrl'] != null && scan['imageUrl'] != ''
                  ? Image.network(scan['imageUrl'], fit: BoxFit.cover)
                  : Image.asset('assets/images/xray.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    scan['name'],
                    style: poppins(
                      size: 14,
                      color: textColor,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(scan['date']),
                    style: poppins(
                      size: 12,
                      color: isPinned ? Colors.white60 : grey,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.arrow_forward_ios, size: 13, color: grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: () => setState(() => _showSortDropdown = !_showSortDropdown),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: grey, size: 18),
          const SizedBox(width: 4),
          Text(_selectedSort, style: poppins(size: 13, color: grey)),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Positioned(
      top: 310,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 160,
          color: white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _sortOptions
                .map(
                  (opt) => ListTile(
                    title: Text(opt, style: poppins(size: 13)),
                    onTap: () {
                      setState(() {
                        _selectedSort = opt;
                        _showSortDropdown = false;
                      });
                      _applyFilters();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  const months = [
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
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
