import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static const String loginUrl =
      "https://sewac-helper-app.onrender.com/api/v1/auth/login";

  static Future<bool> login({
    required String username,
    required String password,
  }) async {

    try {

      final response = await http.post(
        Uri.parse(loginUrl),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      print("LOGIN RESPONSE: ${response.body}");

      if (response.statusCode == 200) {

        final responseData =
        jsonDecode(response.body);

        final token =
        responseData["data"]["token"];

        final prefs =
        await SharedPreferences.getInstance();

        await prefs.setString(
          "auth_token",
          token,
        );

        print(
          "TOKEN SAVED: $token",
        );

        return true;
      }

      return false;

    } catch (e) {

      print(
        "LOGIN ERROR: $e",
      );

      return false;
    }
  }
}