import 'package:flutter/material.dart';
import '../../services/auth.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _newEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool loading = false;

  Future<void> _updateEmail() async {
    setState(() => loading = true);

    try {
      await Auth().updateEmail(
        newEmail: _newEmailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "A verification email has been sent. Please confirm to update your email.",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Email")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _newEmailCtrl,
              decoration: const InputDecoration(labelText: "New Email"),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : _updateEmail,
              child: Text(loading ? "Updating..." : "Update Email"),
            ),
          ],
        ),
      ),
    );
  }
}
