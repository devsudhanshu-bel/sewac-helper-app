import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import '../widgets/sewac_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/sewac_header.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // CHANGE ONLY THIS IF HARDWARE RFID LENGTH CHANGES LATER
  // Example: 36 -> 40
  static const int requiredRfidLength = 24;

  final TextEditingController _rfidController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveRFID() async {
    final code = _rfidController.text.trim();

    // EMPTY FIELD
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please scan RFID first",
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      // Fetch the auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      // URL-encode the code to prevent breakages from special characters
      final encodedCode = Uri.encodeComponent(code);

      final response = await http.post(
        Uri.parse(
          "https://sewac-helper-backend.up.railway.app/api/v1/rfid/create/$encodedCode",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("STATUS => ${response.statusCode}");
      print("BODY => ${response.body}");

      final result = jsonDecode(response.body);

      // FIXED: Reading from root level of the JSON response
      final message = result["message"]?.toString().toLowerCase() ?? "";

      // FIXED: Reading directly from result["data"]["slno"]
      final serialNo = result["data"]?["slno"]?.toString() ?? "";

      // RFID ALREADY EXISTS
      if (message.contains("already exists")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE65100), // Distinct warning color
            content: Text(
              "RFID already assigned to Serial No: $serialNo",
            ),
          ),
        );
      }

      // SUCCESS
      else if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF4CAF50),
            content: Text(
              "RFID assigned successfully",
            ),
          ),
        );

        _rfidController.clear();
      }

      // FAILED
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty ? message : "Failed to save RFID",
            ),
          ),
        );
      }
    }

    // INTERNET ISSUE
    on http.ClientException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed due to internet connection",
          ),
        ),
      );
    }

    // OTHER ERROR
    catch (e) {
      print("SAVE ERROR => $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to save RFID",
          ),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(
        "auth_token",
      ) ?? "";

      final response = await http.post(
        Uri.parse(
          "https://sewac-helper-backend.up.railway.app/api/v1/auth/logout",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print(
        "LOGOUT STATUS => ${response.statusCode}",
      );

      print(
        "LOGOUT BODY => ${response.body}",
      );
    } catch (e) {
      print(
        "LOGOUT ERROR => $e",
      );
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      "auth_token",
    );

    await prefs.remove(
      "isLoggedIn",
    );

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SewacHeader(
        onLogout: _handleLogout,
      ),
      body: SewacBackground(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                110,
                24,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reader",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.nfc_rounded,
                          size: 64,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        const Text(
                          "Tap RFID Card",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        TextFormField(
                          controller: _rfidController,
                          autofocus: true,
                          showCursor: true,
                          onChanged: (_) {
                            setState(() {});
                          },
                          maxLength: requiredRfidLength,
                          decoration: InputDecoration(
                            hintText: "Tap RFID card to scan...",
                            counterText: "",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFA000),
                                  Color(0xFF4CAF50),
                                ],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isSaving ||
                                  _rfidController.text.trim().length !=
                                      requiredRfidLength
                                  ? null
                                  : _saveRFID,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.grey,
                                shadowColor: Colors.transparent,
                              ),
                              child: const Text(
                                "SAVE",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}