import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'phq9_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _agreed = false;

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Phq9Screen()),
    );
  }

  void _openAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Kalinaw',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const Text('Your calm check-in companion'),
                const SizedBox(height: 24),
                const Text(
                  'Kalinaw is a screening tool. It is not a diagnosis, and it does not replace a counselor, psychologist or psychiatrist. '
                  'It does not contact emergency services for you.\n\n'
                  'Your answers are sensitive personal information. In guest mode, your chat and results are not saved.',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (value) {
                    setState(() {
                      _agreed = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I understand this is not a diagnosis, and I agree to use Kalinaw.',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _agreed ? _openAuth : null,
                    child: const Text('Log in or create account'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _agreed ? _continueAsGuest : null,
                    child: const Text('Continue as guest'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}