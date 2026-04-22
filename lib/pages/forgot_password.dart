import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color white = Colors.white;
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color hintGrey = Color(0xFF8FA8C8);
  static const Color fieldBorder = Color(0xFFDDE6F0);

  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  bool _canResend = true;
  int _resendCooldown = 0;

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) return '*@$domain';

    return '${name[0]}***${name[name.length - 1]}@$domain';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("Sending reset email to: $email");

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("Reset email sent successfully");
      if (!mounted) return;
      setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Something went wrong';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // Icon
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
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: white,
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Forgot Password',
                    style: GoogleFonts.poppins(
                      color: white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailSent
                        ? 'A reset link has been sent to\nyour email address.'
                        : 'Enter your registered email and we\nwill send you a reset link.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: hintGrey,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Success state
                  if (_emailSent) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: primaryBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _emailCtrl.text.isNotEmpty
                                  ? 'Check ${_maskEmail(_emailCtrl.text.trim())} and follow the link to reset your password.'
                                  : 'Check your inbox and follow the link to reset your password.',
                              style: GoogleFonts.poppins(
                                color: white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Resend
                    Opacity(
                      opacity: _canResend ? 1.0 : 0.5,
                      child: GestureDetector(
                        onTap: (_canResend && !_isLoading)
                            ? () async {
                                await _sendResetEmail();

                                setState(() {
                                  _canResend = false;
                                  _resendCooldown = 30;
                                });

                                // countdown timer
                                while (_resendCooldown > 0 && mounted) {
                                  await Future.delayed(
                                    const Duration(seconds: 1),
                                  );
                                  setState(() => _resendCooldown--);
                                }

                                if (mounted) {
                                  setState(() => _canResend = true);
                                }
                              }
                            : null,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              color: hintGrey,
                              fontSize: 13,
                            ),
                            children: [
                              const TextSpan(text: "Didn't receive it? "),
                              TextSpan(
                                text: _canResend
                                    ? 'Resend'
                                    : 'Wait $_resendCooldown s',
                                style: GoogleFonts.poppins(
                                  color: _canResend ? white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Email field
                    _buildInputField(
                      controller: _emailCtrl,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 44),

                    // Send button
                    GestureDetector(
                      onTap: _isLoading ? null : _sendResetEmail,
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
                                'Send Reset Link',
                                style: GoogleFonts.poppins(
                                  color: white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fieldBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14, color: darkNavy),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: darkNavy, fontSize: 14),
          prefixIcon: Icon(icon, color: darkNavy, size: 24),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
    );
  }
}
