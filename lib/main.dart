import 'dart:convert';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'phq9_screen.dart';
import 'welcome_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const KalinawApp(),
    ),
  );
}

class KalinawApp extends StatelessWidget {
  const KalinawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalinaw',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6B6B),
        ),
      ),
      home: const  WelcomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'Not checked yet';

  Future<void> _checkBackend() async {
    setState(() {
      _status = 'Checking...';
    });

    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/'));
      final data = jsonDecode(response.body);
      setState(() {
        _status = data['message'];
      });
    } catch (error) {
      setState(() {
        _status = 'Could not reach the backend';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kalinaw',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const Text('Your calm check-in companion'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Phq9Screen()),
                );
              },
              child: const Text('Start check-in'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _checkBackend,
              child: const Text('Check backend'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}