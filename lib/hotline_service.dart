import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'hotlines.dart';

class HotlineService {
  static const String _prefsKey = 'kalinaw_hotlines';
  static List<Hotline>? _cached;

  // What to show right now: the last saved or downloaded list, or the
  // built-in placeholder list if there is none.
  static List<Hotline> get current => _cached ?? hotlines;

  static List<Hotline>? _parse(List<dynamic> data) {
    if (data.isEmpty) return null;

    return [
      for (final item in data)
        Hotline(
          name: item['name'],
          number: item['number'],
          note: item['note'] ?? '',
        ),
    ];
  }

  // Loads the list saved on the phone. Never throws.
  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == null) return;

      final list = _parse(jsonDecode(saved) as List<dynamic>);
      if (list != null) _cached = list;
    } catch (error) {
      print('Hotline restore error: $error');
    }
  }

  // Tries to refresh the list. Never throws, so the emergency screen can
  // always show something even with no internet.
  static Future<List<Hotline>> load() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/hotlines'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final list = _parse(jsonDecode(response.body) as List<dynamic>);

        if (list != null) {
          _cached = list;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, response.body);
        }
      }
    } catch (error) {
      print('Hotline load error: $error');
    }

    return current;
  }
}