import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';

class AuthService {
  const AuthService._();

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(loginEndpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readMessage(response.body, 'Invalid email or password.'),
      );
    }
  }
}

String _readMessage(String body, String fallback) {
  try {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded['message'] != null) {
      return decoded['message'].toString();
    }
  } catch (_) {
    // Fall through to the fallback message.
  }

  return fallback;
}
