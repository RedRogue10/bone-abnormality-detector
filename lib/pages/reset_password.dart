import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color white = Colors.white;
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color hintGrey = Color(0xFF8FA8C8);
  static const Color fieldBorder = Color(0xFFDDE6F0);

  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
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

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() => _isSuccess = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkNavy,
      body: Column(
        children: [
          // TOP BAR
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // ICON
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: white.withOpacity(0.08),
                      border: Border.all(
                        color: white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.lock_outlined,
                      color: white,
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TITLE
                  Text(
                    _isSuccess ? 'Password Reset!' : 'Reset Password',
                    style: GoogleFonts.poppins(
                      color: white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _isSuccess
                        ? 'Your password has been successfully reset.'
                        : 'Enter your new password below.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: hintGrey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // SUCCESS STATE
                  if (_isSuccess) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_outlined,
                              color: primaryBlue, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'You can now log in with your new password.',
                              style: GoogleFonts.poppins(
                                color: white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    GestureDetector(
                      onTap: _goToLogin,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A73E9),
                              Color(0xFF0D3A8A)
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Go to Login',
                          style: GoogleFonts.poppins(
                            color: white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ]

                  // FORM STATE
                  else ...[
                    _buildInputField(
                      controller: _passwordCtrl,
                      hint: 'New Password',
                      icon: Icons.lock_outlined,
                      obscure: _obscurePass,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: darkNavy,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildInputField(
                      controller: _confirmPassCtrl,
                      hint: 'Confirm New Password',
                      icon: Icons.lock_outlined,
                      obscure: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: darkNavy,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),

                    const SizedBox(height: 44),

                    GestureDetector(
                      onTap: _isLoading ? null : _resetPassword,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: _isLoading
                                ? [Colors.grey, Colors.grey]
                                : const [
                                    Color(0xFF1A73E9),
                                    Color(0xFF0D3A8A)
                                  ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'Save New Password',
                                style: GoogleFonts.poppins(
                                  color: white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fieldBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(color: darkNavy),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: darkNavy),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}