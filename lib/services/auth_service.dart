import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static const String loginUrl =
      "https://sewac-helper-app.onrender.com/api/v1/auth/login";

  static Future<String> login({
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

          "username":
          username.trim(),

          "password":
          password.trim(),
        }),
      );

      print(
        "LOGIN STATUS => ${response.statusCode}",
      );

      print(
        "LOGIN BODY => ${response.body}",
      );

      final body =
      response.body.toLowerCase();

      // ACCOUNT IN USE
      if (

      body.contains("already") ||

          body.contains("active") ||

          body.contains("logged in") ||

          body.contains("in use")

      ) {

        return "ALREADY_IN_USE";
      }

      // SUCCESS
      if (response.statusCode == 200) {

        final data =
        jsonDecode(
            response.body);

        final token =

            data["token"] ??

                data["data"]?["token"] ??

                "";

        if (token
            .isNotEmpty) {

          final prefs =

          await SharedPreferences
              .getInstance();

          await prefs.setString(
            "auth_token",
            token,
          );

          await prefs.setString(
            "admin_name",
            username.trim(),
          );

          return "SUCCESS";
        }
      }

      return "INVALID";

    } catch (e) {

      print(
        "LOGIN ERROR => $e",
      );

      return "SERVER_ERROR";
    }
  }
}