import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'hotlines.dart';

class HotlineService {
  static List<Hotline>? _cached;

  // What to show right now: the last downloaded list, or the built-in one.
  static List<Hotline> get current => _cached ?? hotlines;

  // Tries to refresh the list. Never throws, so the emergency screen can
  // always show something even with no internet.
  static Future<List<Hotline>> load() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/hotlines'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        if (data.isNotEmpty) {
          _cached = [
            for (final item in data)
              Hotline(
                name: item['name'],
                number: item['number'],
                note: item['note'] ?? '',
              ),
          ];
        }
      }
    } catch (error) {
      print('Hotline load error: $error');
    }

    return current;
  }
}