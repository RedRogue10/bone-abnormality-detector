import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MobileOnlyPage extends StatelessWidget {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color primaryBlue = Color(0xFF1A73E9);
  static const Color gold = Color(0xFFD19527);
  static const Color grey = Color(0xFF808080);
  static const Color white = Colors.white;
  static const Color bgGrey = Color(0xFFF0F0F0);

  const MobileOnlyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'DOWNLOAD THE APP',
          style: GoogleFonts.oswald(color: white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phonelink_erase_rounded,
                size: 80,
                color: primaryBlue,
              ),
              const SizedBox(height: 20),
              const Text(
                "Scanning is only available on the Mobile App",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please download our app on Android to use scanning features.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Go Back"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkNavy,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
