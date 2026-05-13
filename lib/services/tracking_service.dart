import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tracking_model.dart';

class TrackingService {

  static const String baseUrl =
      "https://sewac-helper-app.onrender.com/api/v1/tracking/tracking";

  static Future<List<TrackingModel>> fetchLogs() async {

    try {

      final prefs =
      await SharedPreferences.getInstance();

      final token =
      prefs.getString("auth_token");

      print("Saved Token: $token");

      final response = await http.get(
        Uri.parse(baseUrl),

        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print(
        "Tracking Response: ${response.body}",
      );

      if (response.statusCode == 200) {

        final decoded =
        jsonDecode(response.body);

        final List<dynamic> data =
            decoded["data"] ?? [];

        return data
            .map<TrackingModel>(
              (item) =>
              TrackingModel.fromJson(item),
        )
            .toList();
      }

      throw Exception(
        "Failed to fetch logs",
      );

    } catch (e) {

      print(
        "TRACKING ERROR: $e",
      );

      rethrow;
    }
  }
}