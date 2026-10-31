import 'package:flutter/material.dart';

import 'hotline_service.dart';
import 'hotlines.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Hotline> _items = HotlineService.current;

  @override
  void initState() {
    super.initState();

    // Show what we have right away, then refresh in the background.
    HotlineService.load().then((list) {
      if (mounted) {
        setState(() {
          _items = list;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('You are not alone')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'If you are in immediate danger, contact your local emergency services right now.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reaching out is a strong thing to do. You can also tell someone you trust, like a family member, a friend or a teacher, and ask them to stay with you.',
            ),
            const SizedBox(height: 24),
            for (final hotline in _items)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotline.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        hotline.number,
                        style: TextStyle(
                          fontSize: 22,
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hotline.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(hotline.note),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}