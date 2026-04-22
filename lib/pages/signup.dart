import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth.dart';
import 'dashboard.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static const Color darkNavy    = Color(0xFF0B2545);
  static const Color bgNavy      = Color(0xFF0B2545);
  static const Color white       = Colors.white;
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color hintGrey    = Color(0xFF8FA8C8);
  static const Color fieldBorder = Color(0xFFDDE6F0);

  final Auth _auth           = Auth();
  final _firstNameCtrl       = TextEditingController();
  final _lastNameCtrl        = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPassCtrl     = TextEditingController();

  bool _obscurePass          = true;
  bool _obscureConfirm       = true;
  bool _isLoading            = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName  = _lastNameCtrl.text.trim();
    final email     = _emailCtrl.text.trim();
    final password  = _passwordCtrl.text.trim();
    final confirm   = _confirmPassCtrl.text.trim();

    // Basic validation
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty ||
        password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.createUserWithEmailAndPassword(email, password);

      // Update the Firebase display name with first + last name
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName('$firstName $lastName');

      // TODO: Save additional user info (firstName, lastName) to Firestore

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Error: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),

              // Title
              Text(
                'Welcome',
                style: GoogleFonts.poppins(
                  color: white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your account',
                style: GoogleFonts.poppins(color: hintGrey, fontSize: 13),
              ),

              const SizedBox(height: 40),

              // Fields
              _buildInputField(
                controller: _firstNameCtrl,
                hint: 'First Name',
                icon: Icons.person_outlined,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _lastNameCtrl,
                hint: 'Last Name',
                icon: Icons.person_outlined,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _emailCtrl,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _passwordCtrl,
                hint: 'Password',
                icon: Icons.lock_outlined,
                obscure: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: darkNavy,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _confirmPassCtrl,
                hint: 'Confirm Password',
                icon: Icons.lock_outlined,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: darkNavy,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 14),

              // Terms
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(color: hintGrey, fontSize: 12),
                  children: [
                    const TextSpan(
                        text: 'By registering you are agreeing to our\n'),
                    TextSpan(
                      text: 'Terms of use and privacy policy.',
                      style: GoogleFonts.poppins(
                        color: white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Register button
              GestureDetector(
                onTap: _isLoading ? null : _register,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _isLoading
                          ? [Colors.grey.shade600, Colors.grey.shade700]
                          : const [Color(0xFF1A73E9), Color(0xFF0D3A8A)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Register',
                          style: GoogleFonts.poppins(
                            color: white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Already have account
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(color: white, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Already have an Account? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            color: white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fieldBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14, color: bgNavy),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: bgNavy, fontSize: 14),
          prefixIcon: Icon(icon, color: bgNavy, size: 24),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}