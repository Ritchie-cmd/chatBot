import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'config.dart';
import 'welcome_screen.dart';

String _detail(http.Response response, String fallback) {
  try {
    final data = jsonDecode(response.body);
    final detail = data['detail'];
    if (detail is String) return detail;
  } catch (_) {}
  return fallback;
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _logout(BuildContext context) {
    AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          actions: [
            TextButton(
              onPressed: () => _logout(context),
              child: const Text('Log out'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hotlines'),
              Tab(text: 'Counselors'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _HotlinesTab(),
              _CounselorsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotlinesTab extends StatefulWidget {
  const _HotlinesTab();

  @override
  State<_HotlinesTab> createState() => _HotlinesTabState();
}

class _HotlinesTabState extends State<_HotlinesTab> {
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('$backendUrl/hotlines'));

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
      print('Hotlines load error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load the hotlines. Please try again.';
      });
    }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final nameField = TextEditingController(text: existing?['name'] ?? '');
    final numberField = TextEditingController(text: existing?['number'] ?? '');
    final noteField = TextEditingController(text: existing?['note'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add hotline' : 'Edit hotline'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameField,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: numberField,
                decoration: const InputDecoration(labelText: 'Number'),
              ),
              TextField(
                controller: noteField,
                decoration: const InputDecoration(
                  labelText: 'Note (hours, who it is for)',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final name = nameField.text.trim();
    final number = numberField.text.trim();
    final note = noteField.text.trim();

    nameField.dispose();
    numberField.dispose();
    noteField.dispose();

    if (saved != true) return;

    if (name.isEmpty || number.isEmpty) {
      _toast('Name and number are required.');
      return;
    }

    try {
      final body = jsonEncode({'name': name, 'number': number, 'note': note});
      final http.Response response;

      if (existing == null) {
        response = await http.post(
          Uri.parse('$backendUrl/admin/hotlines'),
          headers: AuthService.headers(),
          body: body,
        );
      } else {
        response = await http.put(
          Uri.parse('$backendUrl/admin/hotlines/${existing['id']}'),
          headers: AuthService.headers(),
          body: body,
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        _toast(_detail(response, 'Could not save.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Hotline save error: $error');
      _toast('Could not reach the server.');
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this hotline?'),
        content: const Text('People in crisis will no longer see it.'),
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
        Uri.parse('$backendUrl/admin/hotlines/$id'),
        headers: AuthService.headers(),
      );

      if (response.statusCode != 204) {
        _toast(_detail(response, 'Could not delete.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Hotline delete error: $error');
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
              'Only enter numbers that were verified from official sources and approved by your guidance counselor. '
              'The app shows this list to people in crisis. Until you add numbers here, the app shows placeholders.',
            ),
          ),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hotlines added yet.'),
            ),
          for (final item in _items)
            ListTile(
              title: Text(item['name']),
              subtitle: Text(
                '${item['number']}${(item['note'] ?? '').isEmpty ? '' : '\n${item['note']}'}',
              ),
              isThreeLine: (item['note'] ?? '').isNotEmpty,
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
        label: const Text('Add hotline'),
      ),
    );
  }
}

class _CounselorsTab extends StatefulWidget {
  const _CounselorsTab();

  @override
  State<_CounselorsTab> createState() => _CounselorsTabState();
}

class _CounselorsTabState extends State<_CounselorsTab> {
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/admin/counselors'),
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
      print('Counselors load error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load the counselors. Please try again.';
      });
    }
  }

  Future<void> _add() async {
    final field = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a counselor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The person must already have a Kalinaw account. Check who they are before you give them access to students\' shared results.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: field,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Their account email'),
            ),
          ],
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

    final email = field.text.trim();
    field.dispose();

    if (confirmed != true || email.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/admin/counselors'),
        headers: AuthService.headers(),
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        _toast(_detail(response, 'Could not add this counselor.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Counselor add error: $error');
      _toast('Could not reach the server.');
    }
  }

  Future<void> _remove(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this counselor?'),
        content: const Text(
          'They will lose access, and every result that students shared with them will stop being shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/admin/counselors/$id'),
        headers: AuthService.headers(),
      );

      if (response.statusCode != 204) {
        _toast(_detail(response, 'Could not remove this counselor.'));
        return;
      }

      await _load();
    } catch (error) {
      print('Counselor remove error: $error');
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
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No counselors yet.'),
            ),
          for (final item in _items)
            ListTile(
              title: Text(item['name']),
              subtitle: Text(item['email']),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove_outlined),
                tooltip: 'Remove counselor',
                onPressed: () => _remove(item['id']),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add counselor'),
      ),
    );
  }
}