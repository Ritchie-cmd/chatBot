import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'config.dart';
import 'share_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _results = [];
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
        Uri.parse('$backendUrl/results'),
        headers: AuthService.headers(),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        _results = data;
        _loading = false;
      });
    } catch (error) {
      print('History error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Could not load your history. Your login may have expired, so try logging in again.';
      });
    }
  }

  void _openShare(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShareScreen(resultId: id)),
    );
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this result?'),
        content: const Text(
          'This removes it from your history for good, and stops sharing it with any counselor.',
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
        Uri.parse('$backendUrl/results/$id'),
        headers: AuthService.headers(),
      );

      if (response.statusCode != 204) {
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      await _load();
    } catch (error) {
      print('Delete error: $error');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete. Please try again.')),
      );
    }
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
    } else if (_results.isEmpty) {
      body = const Center(child: Text('No saved results yet.'));
    } else {
      body = ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _results[index];
          final String label = item['test_type'] == 'phq9' ? 'PHQ-9' : 'GAD-7';

          return ListTile(
            title: Text('$label: ${item['level']}'),
            subtitle: Text(
              'Score ${item['total']}  |  ${_formatDate(item['created_at'])}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share with a counselor',
                  onPressed: () => _openShare(item['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => _delete(item['id']),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My history')),
      body: SafeArea(child: body),
    );
  }
}