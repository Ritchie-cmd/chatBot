import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

// Holds the login token while the app is open. The token is kept in memory
// only for now. Before real use, store it with flutter_secure_storage.
class AuthService {
  static String? token;

  static bool get loggedIn => token != null;

  // Headers for requests to the backend. Adds the token when logged in.
  static Map<String, String> headers() {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
        return null;
      }
      return _errorMessage(response);
    } catch (error) {
      print('Login error: $error');
      return 'Could not reach the server. Please try again.';
    }
  }

  static void logout() {
    token = null;
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