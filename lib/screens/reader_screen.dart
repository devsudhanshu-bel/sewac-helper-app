import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final String currentInput = _rfidController.text.trim();
    final bool isInputLengthValid = currentInput.length == requiredRfidLength;
    final bool showCustomLengthWarning = currentInput.isNotEmpty && !isInputLengthValid;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SewacHeader(
        onLogout: _handleLogout,
      ),
      body: SewacBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              color: const Color(0xFF00A236),
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "RFID Hardware Registry",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const Text(
                            "Scan and provision new active tag identifiers",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ],
                          border: Border.all(
                            color: Colors.black.withOpacity(0.03),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.nfc_rounded,
                                      size: 54,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    "Tap RFID Card",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                "Scan RFID Tag Code *",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _rfidController,
                              autofocus: true,
                              showCursor: true,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(requiredRfidLength),
                              ],
                              onChanged: (_) {
                                setState(() {});
                              },
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              decoration: InputDecoration(
                                hintText: "Tap RFID card to scan...",
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 14,
                                ),
                                counterText: "",
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                prefixIcon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                suffixIcon: _rfidController.text.isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: Colors.black38,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _rfidController.clear();
                                    setState(() {});
                                  },
                                )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: showCustomLengthWarning
                                        ? Colors.amber.shade600
                                        : Colors.black12,
                                    width: showCustomLengthWarning ? 1.5 : 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: showCustomLengthWarning
                                        ? Colors.amber.shade600
                                        : const Color(0xFF00A236),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            if (showCustomLengthWarning)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 6),
                                child: Text(
                                  "Expected code configuration requires exactly $requiredRfidLength characters (Current: ${currentInput.length})",
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isInputLengthValid && !_isSaving
                                      ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFA000),
                                      Color(0xFF4CAF50),
                                    ],
                                  )
                                      : null,
                                  color: (!isInputLengthValid || _isSaving)
                                      ? Colors.grey.shade300
                                      : null,
                                  boxShadow: isInputLengthValid && !_isSaving
                                      ? [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSaving || !isInputLengthValid ? null : _saveRFID,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text(
                                    "SAVE RFID REGISTER",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
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
            );
          },
        ),
      ),
    );
  }
}