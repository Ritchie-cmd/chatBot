import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'config.dart';

class AdminResourcesTab extends StatefulWidget {
  const AdminResourcesTab({super.key});

  @override
  State<AdminResourcesTab> createState() => _AdminResourcesTabState();
}

class _AdminResourcesTabState extends State<AdminResourcesTab> {
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
      final response = await http.get(Uri.parse('$backendUrl/resources'));

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
      print('Admin resources load error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load the resources. Please try again.';
      });
    }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final titleField = TextEditingController(text: existing?['title'] ?? '');
    final bodyField = TextEditingController(text: existing?['body'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add resource' : 'Edit resource'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleField,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: bodyField,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Text'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final title = titleField.text.trim();
    final body = bodyField.text.trim();

    titleField.dispose();
    bodyField.dispose();

    if (saved != true) return;

    if (title.isEmpty || body.isEmpty) {
      _toast('Title and text are required.');
      return;
    }

    try {
      final payload = jsonEncode({'title': title, 'body': body});
      final http.Response response;

      if (existing == null) {
        response = await http.post(
          Uri.parse('$backendUrl/admin/resources'),
          headers: AuthService.headers(),
          body: payload,
        );
      } else {
        response = await http.put(
          Uri.parse('$backendUrl/admin/resources/${existing['id']}'),
          headers: AuthService.headers(),
          body: payload,
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        _toast(_detail(response, 'Could not save.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Resource save error: $error');
      _toast('Could not reach the server.');
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this resource?'),
        content: const Text('Users will no longer see it.'),
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
        Uri.parse('$backendUrl/admin/resources/$id'),
        headers: AuthService.headers(),
      );

      if (response.statusCode != 204) {
        _toast(_detail(response, 'Could not delete.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Resource delete error: $error');
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
              'Only publish text that your guidance counselor has reviewed and approved. Users read it as health information.',
            ),
          ),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No resources added yet.'),
            ),
          for (final item in _items)
            ListTile(
              title: Text(item['title']),
              subtitle: Text(
                item['body'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: () => _edit(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _delete(item['id']),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Add resource'),
      ),
    );
  }
}