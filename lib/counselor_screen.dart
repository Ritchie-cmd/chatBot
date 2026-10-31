import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'config.dart';
import 'welcome_screen.dart';

class CounselorScreen extends StatefulWidget {
  const CounselorScreen({super.key});

  @override
  State<CounselorScreen> createState() => _CounselorScreenState();
}

class _CounselorScreenState extends State<CounselorScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/counselor/shared'),
        headers: AuthService.headers(),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (error) {
      print('Counselor load error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load shared results. Please try again.';
      });
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatDate(String iso) {
    final date = DateTime.parse(iso).toLocal();
    return '${date.year}-${_two(date.month)}-${_two(date.day)} ${_two(date.hour)}:${_two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    } else if (_items.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No students have shared a result with you yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final String label = item['test_type'] == 'phq9' ? 'PHQ-9' : 'GAD-7';
          final bool crisis = item['crisis'] == true;

          return Card(
            child: ListTile(
              leading: Icon(
                crisis ? Icons.warning_amber_rounded : Icons.person_outline,
                color: crisis ? Theme.of(context).colorScheme.error : null,
              ),
              title: Text(item['student_name']),
              subtitle: Text(
                '$label: ${item['level']} (score ${item['total']})\n'
                'Taken ${_formatDate(item['taken_at'])}\n'
                'Shared ${_formatDate(item['shared_at'])}'
                '${crisis ? '\nThe student answered above 0 on the self-harm question.' : ''}',
              ),
              isThreeLine: true,
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared results'),
        actions: [
          TextButton(onPressed: _logout, child: const Text('Log out')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Screening results are not a diagnosis.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}