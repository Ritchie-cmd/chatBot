import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'config.dart';

class ShareScreen extends StatefulWidget {
  final int resultId;

  const ShareScreen({super.key, required this.resultId});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  List<dynamic> _counselors = [];
  final Set<int> _shared = {};
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
      final counselorsResponse = await http.get(
        Uri.parse('$backendUrl/counselors'),
        headers: AuthService.headers(),
      );
      final sharesResponse = await http.get(
        Uri.parse('$backendUrl/results/${widget.resultId}/shares'),
        headers: AuthService.headers(),
      );

      if (counselorsResponse.statusCode != 200 ||
          sharesResponse.statusCode != 200) {
        throw Exception('Unexpected response');
      }

      final counselors = jsonDecode(counselorsResponse.body);
      final ids = jsonDecode(sharesResponse.body)['counselor_ids'];

      if (!mounted) return;

      setState(() {
        _counselors = counselors;
        _shared
          ..clear()
          ..addAll(List<int>.from(ids));
        _loading = false;
      });
    } catch (error) {
      print('Share load error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load counselors. Please try again.';
      });
    }
  }

  Future<void> _toggle(int counselorId, bool share) async {
    try {
      final http.Response response;

      if (share) {
        response = await http.post(
          Uri.parse('$backendUrl/results/${widget.resultId}/share'),
          headers: AuthService.headers(),
          body: jsonEncode({'counselor_id': counselorId}),
        );
      } else {
        response = await http.delete(
          Uri.parse(
            '$backendUrl/results/${widget.resultId}/share/$counselorId',
          ),
          headers: AuthService.headers(),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      if (!mounted) return;

      setState(() {
        if (share) {
          _shared.add(counselorId);
        } else {
          _shared.remove(counselorId);
        }
      });
    } catch (error) {
      print('Share toggle error: $error');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update sharing. Try again.')),
      );
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
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'A counselor you share with will see your name, the test, your score, the level and the date. '
              'They will not see your email, your answers or your other results. '
              'You can stop sharing anytime.',
            ),
          ),
          if (_counselors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No counselors are available yet.'),
            ),
          for (final counselor in _counselors)
            SwitchListTile(
              title: Text(counselor['name']),
              value: _shared.contains(counselor['id']),
              onChanged: (value) => _toggle(counselor['id'], value),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Share with a counselor')),
      body: SafeArea(child: body),
    );
  }
}