import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
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
      final response = await http
          .get(Uri.parse('$backendUrl/resources'))
          .timeout(const Duration(seconds: 8));

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
      print('Resources load error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Could not load the resources. Check your connection and try again. If you need help right now, tap Get help in the chat.';
      });
    }
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
            'No resources have been added yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = ListView(
        children: [
          for (final item in _items)
            ExpansionTile(
              title: Text(item['title']),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(item['body'])],
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'This information is not a diagnosis or a replacement for a counselor or doctor.',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}