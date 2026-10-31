import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'config.dart';

class AdminPhrasesTab extends StatefulWidget {
  const AdminPhrasesTab({super.key});

  @override
  State<AdminPhrasesTab> createState() => _AdminPhrasesTabState();
}

class _AdminPhrasesTabState extends State<AdminPhrasesTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _detail(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      final detail = data['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return fallback;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('$backendUrl/warning-phrases'));

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
      print('Phrases load error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load the phrases. Please try again.';
      });
    }
  }

  Future<void> _add() async {
    final phraseField = TextEditingController();
    final languageField = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add warning phrase'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phraseField,
                decoration: const InputDecoration(labelText: 'Phrase'),
              ),
              TextField(
                controller: languageField,
                decoration: const InputDecoration(
                  labelText: 'Language (for example Bisaya)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final phrase = phraseField.text.trim();
    final language = languageField.text.trim();

    phraseField.dispose();
    languageField.dispose();

    if (saved != true) return;

    if (phrase.length < 3) {
      _toast('A phrase needs at least 3 characters.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/admin/warning-phrases'),
        headers: AuthService.headers(),
        body: jsonEncode({'phrase': phrase, 'language': language}),
      );

      if (response.statusCode != 201) {
        _toast(_detail(response, 'Could not add this phrase.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Phrase add error: $error');
      _toast('Could not reach the server.');
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this phrase?'),
        content: const Text(
          'Messages with this phrase will no longer open the emergency screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/admin/warning-phrases/$id'),
        headers: AuthService.headers(),
      );

      if (response.statusCode != 204) {
        _toast(_detail(response, 'Could not delete.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Phrase delete error: $error');
      _toast('Could not reach the server.');
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
    } else {
      body = ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'These phrases are added to the built-in English ones. Every typed message is checked against them, and a match opens the emergency screen. '
              'Only add phrases that native speakers wrote and your guidance counselor approved. '
              'A phrase is matched anywhere inside a message, so avoid very short or common words that could appear in normal sentences.',
            ),
          ),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No extra phrases added yet.'),
            ),
          for (final item in _items)
            ListTile(
              title: Text(item['phrase']),
              subtitle: (item['language'] ?? '').isEmpty
                  ? null
                  : Text(item['language']),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _delete(item['id']),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add phrase'),
      ),
    );
  }
}