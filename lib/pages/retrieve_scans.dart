import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllScansPage extends StatefulWidget {
  const AllScansPage({super.key});

  @override
  State<AllScansPage> createState() => _AllScansPageState();
}

class _AllScansPageState extends State<AllScansPage> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color bgGrey      = Color(0xFFF0F0F0);
  static const Color grey        = Color(0xFF808080);
  static const Color white       = Colors.white;

  static const List<String> _sortOptions = ['Newest', 'Oldest'];

  final _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _allScans = [
    {'name': 'Scan 1', 'date': DateTime(2026, 4, 23)},
    {'name': 'Scan 2', 'date': DateTime(2026, 3, 27)},
    {'name': 'Scan 3', 'date': DateTime(2026, 3, 27)},
    {'name': 'Scan 4', 'date': DateTime(2026, 3, 27)},
    {'name': 'Scan 5', 'date': DateTime(2026, 3, 27)},
  ];

  List<Map<String, dynamic>> _filtered = [];
  String _selectedSort   = 'Newest';
  bool _showSortDropdown = false;
  String _searchQuery    = '';

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Reusable text style
  TextStyle poppins({
    double size = 14,
    Color color = Colors.black87,
    FontWeight weight = FontWeight.normal,
  }) =>
      GoogleFonts.poppins(
          fontSize: size, color: color, fontWeight: weight);

  void _applyFilters() {
    var result = [..._allScans];

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((s) => (s['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    result.sort((a, b) => _selectedSort == 'Newest'
        ? (b['date'] as DateTime).compareTo(a['date'] as DateTime)
        : (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    setState(() => _filtered = result);
  }

  @override
  Widget build(BuildContext context) {
    final pinned  = _filtered.isNotEmpty ? _filtered.first : null;
    final theRest = _filtered.length > 1 ? _filtered.sublist(1) : [];

    return GestureDetector(
      onTap: () {
        if (_showSortDropdown) {
          setState(() => _showSortDropdown = false);
        }
      },
      child: Scaffold(
        backgroundColor: white,
        body: Stack(
          children: [
            Column(
              children: [
                // HEADER
                Container(
                  color: darkNavy,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'All Scans',
                                style: GoogleFonts.oswald(
                                  color: white,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH BAR
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
                          style: poppins(size: 14),
                          decoration: InputDecoration(
                            hintText: 'Search scans',
                            hintStyle:
                                poppins(size: 14, color: grey),
                            prefixIcon:
                                const Icon(Icons.search, color: grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // PINNED CARD 
                      if (pinned != null) ...[
                        _buildScanTile(pinned, isPinned: true),
                        const SizedBox(height: 20),
                      ],

                      // LABEL + SORT 
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Scans',
                            style: poppins(
                                size: 15,
                                weight: FontWeight.w600),
                          ),
                          _buildSortButton(),
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // LIST 
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No scans found.',
                            style: poppins(
                                size: 13, color: grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: theRest.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _buildScanTile(theRest[i]),
                        ),
                ),

                const SizedBox(height: 16),
              ],
            ),

            if (_showSortDropdown) _buildSortDropdown(),
          ],
        ),
      ),
    );
  }

  // Unified card
  Widget _buildScanTile(Map<String, dynamic> scan,
      {bool isPinned = false}) {
    final bgColor = isPinned ? darkNavy : bgGrey;
    final textColor =
        isPinned ? Colors.white : Colors.black87;
    final subTextColor = isPinned
        ? Colors.white60
        : Colors.grey.shade500;

    return Container(
      height: isPinned ? 80 : 72,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.circular(isPinned ? 14 : 12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: isPinned
                ? const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  )
                : BorderRadius.zero,
            child: Image.asset(
              'assets/photos/xray.png',
              width: isPinned ? 75 : 72,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  scan['name'],
                  style: poppins(
                    size: 14,
                    color: textColor,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(scan['date']),
                  style: poppins(
                    size: 12,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(right: 14),
            child: Icon(
              Icons.arrow_forward_ios,
              size: isPinned ? 14 : 13,
              color: isPinned
                  ? Colors.white
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: () =>
          setState(() => _showSortDropdown =
              !_showSortDropdown),
      child: Row(
        children: [
          const Icon(Icons.filter_list,
              color: grey, size: 18),
          const SizedBox(width: 4),
          Text(
            'Sort',
            style: poppins(
              size: 13,
              color: grey,
              weight: FontWeight.w500,
            ),
          ),
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
          padding:
              const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: white,
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _sortOptions.map((option) {
              final selected =
                  _selectedSort == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSort = option;
                    _showSortDropdown = false;
                  });
                  _applyFilters();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10),
                  child: Row(
                    children: [
                      selected
                          ? const Icon(Icons.check,
                              size: 16,
                              color: primaryBlue)
                          : const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: poppins(
                          size: 13,
                          color: selected
                              ? primaryBlue
                              : Colors.black87,
                          weight: selected
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

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}