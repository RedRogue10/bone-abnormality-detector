import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditDoctorInfoPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const EditDoctorInfoPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  State<EditDoctorInfoPage> createState() => _EditDoctorInfoPageState();
}

class _EditDoctorInfoPageState extends State<EditDoctorInfoPage> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color fieldFill   = Color(0xFFEEF0F2);
  static const Color fieldBorder = Color(0xFFCDD1D6);

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.firstName);
    _lastNameCtrl  = TextEditingController(text: widget.lastName);
    _passwordCtrl  = TextEditingController(text: widget.password);
    _emailCtrl     = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() {
    Navigator.pop(context, {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName':  _lastNameCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'password':  _passwordCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayName = '${widget.firstName} ${widget.lastName}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Navy header 
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  color: darkNavy,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left,
                                    color: Colors.white, size: 28),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'EDIT INFO',
                                    style: GoogleFonts.oswald(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _onUpdate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(78, 32),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'UPDATE',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // Avatar overlapping
                Positioned(
                  bottom: -45,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD9DCE1),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 52,
                      color: darkNavy,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 58),

            // Doctor name
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 28),

            // Form fields 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('First name'),
                  _inputField(_firstNameCtrl),
                  const SizedBox(height: 16),

                  _fieldLabel('Last name'),
                  _inputField(_lastNameCtrl),
                  const SizedBox(height: 16),

                  _fieldLabel('Password'),
                  _inputField(_passwordCtrl),
                  const SizedBox(height: 16),

                  _fieldLabel('Email Address'),
                  _inputField(_emailCtrl,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          filled: true,
          fillColor: fieldFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: fieldBorder, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: fieldBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: Color(0xFF1A73E9), width: 1.5),
          ),
        ),
      ),
    );
  }
}