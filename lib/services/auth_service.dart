import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String loginUrl =
      "https://sewac-helper-app.onrender.com/api/v1/auth/login";

  static const String baseUrl =
      "https://sewac-helper-app.onrender.com/api/v1/auth";

  static bool _isRequesting = false;

  static Future<String> login({
    required String username,
    required String password,
  }) async {
    if (_isRequesting) {
      print("[AUTH_SERVICE] Blocked concurrent login request loop execution.");
      return "CONCURRENT_REQUEST";
    }
    _isRequesting = true;

    try {
      final cleanUsername = username.trim();
      final cleanPassword = password.trim();

      print("[AUTH_SERVICE] Initiating First Login Attempt for user: $cleanUsername");

      http.Response firstResponse = await http.post(
        Uri.parse(loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": cleanUsername,
          "password": cleanPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      print("[AUTH_SERVICE] LOGIN STATUS => ${firstResponse.statusCode}");
      print("[AUTH_SERVICE] LOGIN BODY => ${firstResponse.body}");

      final firstBody = firstResponse.body.toLowerCase();

      // Check if backend says session is already active
      if (firstResponse.statusCode == 409 ||
          firstBody.contains("already") ||
          firstBody.contains("active") ||
          firstBody.contains("logged in") ||
          firstBody.contains("in use")) {

        print("[AUTH_SERVICE] Ghost session verified. Triggering force logout...");
        await _forceBackendLogout(cleanUsername);

        print("[AUTH_SERVICE] Waiting 2 seconds for backend database unlock sync...");
        await Future.delayed(const Duration(seconds: 2));

        print("[AUTH_SERVICE] Re-executing Secondary Login Attempt for user: $cleanUsername");

        http.Response retryResponse = await http.post(
          Uri.parse(loginUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "username": cleanUsername,
            "password": cleanPassword,
          }),
        ).timeout(const Duration(seconds: 10));

        print("[AUTH_SERVICE] RETRY LOGIN STATUS => ${retryResponse.statusCode}");
        print("[AUTH_SERVICE] RETRY LOGIN BODY => ${retryResponse.body}");

        final result = await _handleSuccess(retryResponse, cleanUsername);
        _isRequesting = false;
        return result;
      }

      final result = await _handleSuccess(firstResponse, cleanUsername);
      _isRequesting = false;
      return result;

    } catch (e) {
      print("[AUTH_SERVICE] LOGIN ERROR => $e");
      _isRequesting = false;
      return "SERVER_ERROR";
    }
  }

  static Future<String> _handleSuccess(http.Response response, String username) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data["token"] ?? data["data"]?["token"] ?? "";

      if (token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        await prefs.setString("admin_name", username);
        print("[AUTH_SERVICE] Session local security keys written cache securely.");
        return "SUCCESS";
      }
    }

    final body = response.body.toLowerCase();
    if (response.statusCode == 409 ||
        body.contains("already") ||
        body.contains("active") ||
        body.contains("logged in") ||
        body.contains("in use")) {
      return "ALREADY_IN_USE";
    }

    return "INVALID";
  }

  static Future<void> _forceBackendLogout(String username) async {
    final targetUrl = "$baseUrl/logout";
    print("[AUTH_SERVICE] Sending force logout hook payload to target: $targetUrl");
    try {
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username}),
      ).timeout(const Duration(seconds: 5));

      print("[AUTH_SERVICE] FORCED LOGOUT API STATUS => ${response.statusCode}");
      print("[AUTH_SERVICE] FORCED LOGOUT API BODY => ${response.body}");
    } catch (e) {
      print("[AUTH_SERVICE] Forced backend release link failed: $e");
    }
  }

  static Future<void> logout() async {
    print("[AUTH_SERVICE] Initializing logout sequence pipeline execution...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString("admin_name");

      if (savedUsername != null && savedUsername.isNotEmpty) {
        print("[AUTH_SERVICE] Found user context data mapping for '$savedUsername'. Notifying remote server...");
        await _forceBackendLogout(savedUsername);
      }

      await prefs.clear();
      print("[AUTH_SERVICE] Local state machine cache storage wiped successfully.");
    } catch (e) {
      print("[AUTH_SERVICE] Error occurring inside logout sequence stack trace execution: $e");
      // Fallback local memory wipe guardrail
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}
    }
  }
}