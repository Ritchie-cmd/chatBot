import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

// Keeps the login token in memory, and also in the phone's secure storage
// so the user stays logged in after closing the app.
class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'kalinaw_token';

  static String? token;
  static String role = 'student';
  static String name = '';

  static bool get loggedIn => token != null;

  static bool get isCounselor => role == 'counselor';

  static bool get isAdmin => role == 'admin';

  // Headers for requests to the backend. Adds the token when logged in.
  static Map<String, String> headers() {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Called once when the app starts: picks up a saved login, if any.
  static Future<void> restore() async {
    try {
      final saved = await _storage.read(key: _tokenKey);
      if (saved == null) return;

      token = saved;
      await loadProfile();
    } catch (error) {
      print('Restore error: $error');
    }
  }

  // Returns null when it worked, or an error message to show the user.
  static Future<String?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) return null;
      return _errorMessage(response);
    } catch (error) {
      print('Register error: $error');
      return 'Could not reach the server. Please try again.';
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['access_token'];

        try {
          await _storage.write(key: _tokenKey, value: token);
        } catch (error) {
          print('Could not save the login: $error');
        }

        await loadProfile();
        return null;
      }
      return _errorMessage(response);
    } catch (error) {
      print('Login error: $error');
      return 'Could not reach the server. Please try again.';
    }
  }

  // Asks the backend who we are, so the app knows the role. If the token
  // has expired, the saved login is cleared.
  static Future<void> loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/auth/me'),
        headers: headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        role = data['role'] ?? 'student';
        name = data['name'] ?? '';
      } else if (response.statusCode == 401) {
        logout();
      }
    } catch (error) {
      print('Profile error: $error');
    }
  }

  static void logout() {
    token = null;
    role = 'student';
    name = '';

    _storage.delete(key: _tokenKey).catchError((Object error) {
      print('Could not clear the saved login: $error');
    });
  }

  static String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final detail = data['detail'];
      if (detail is String) return detail;
    } catch (_) {}

    if (response.statusCode == 422) {
      return 'Please check your details. Use a valid email and a password of at least 8 characters.';
    }
    return 'Something went wrong. Please try again.';
  }
}