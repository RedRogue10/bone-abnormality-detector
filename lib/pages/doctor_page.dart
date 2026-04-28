import 'package:bone_abnormality_detector/models/user.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_doctor_info.dart';
import '../services/database_service.dart';
import 'package:bone_abnormality_detector/services/auth.dart';
import 'package:go_router/go_router.dart';

class DoctorPage extends StatefulWidget {
  final String userId;
  const DoctorPage({super.key, required this.userId});

  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);

  UserModel? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      await Auth().syncEmailIfChanged();
      final data = await DatabaseService().getUserData();
      setState(() {
        user = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error loading user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final fullName = user?.fullName ?? '';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER
          Container(
            color: darkNavy,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'DOCTOR PAGE',
                              style: GoogleFonts.oswald(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avatar + name + edit icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: Image.asset(
                          'assets/images/doctor_icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                size: 52,
                                color: Colors.white,
                              ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                lastName,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(width: 15),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditDoctorInfoPage(
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUser();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Profile updated'),
                                      ),
                                    );
                                  }
                                },
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── INFO ROWS ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _infoRow('Name', fullName),
                  _divider(),
                  _infoRow('Password', '••••••••••'),
                  _divider(),
                  _infoRow('Email Address', email, isLink: true),
                  const Spacer(),

                  ElevatedButton.icon(
                    onPressed: () async {
                      await Auth().signOut();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout, size: 17),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(160, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFE0E0E0));

  Widget _infoRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: isLink ? primaryBlue : Colors.black45,
                decoration: isLink
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
