import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

// The extra warning phrases an admin added (Bisaya, Waray, Tagalog and so
// on). They are saved on the phone, so the scan works with no connection.
class PhraseService {
  static const String _prefsKey = 'kalinaw_warning_phrases';
  static List<String> _extra = [];

  static List<String> get extra => _extra;

  // Loads the list saved on the phone. Never throws.
  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _extra = prefs.getStringList(_prefsKey) ?? [];
    } catch (error) {
      print('Phrase restore error: $error');
    }
  }

  // Downloads the newest list and saves it. Never throws.
  static Future<void> refresh() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/warning-phrases'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as List<dynamic>;

      final phrases = <String>[
        for (final item in data)
          if (item['phrase'] is String &&
              (item['phrase'] as String).trim().length >= 3)
            (item['phrase'] as String).trim().toLowerCase(),
      ];

      _extra = phrases;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, phrases);
    } catch (error) {
      print('Phrase refresh error: $error');
    }
  }
}