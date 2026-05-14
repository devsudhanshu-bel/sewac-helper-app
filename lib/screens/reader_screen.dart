import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import '../widgets/sewac_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});



  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {

  // CHANGE ONLY THIS IF HARDWARE RFID LENGTH CHANGES LATER
  // Example: 36 -> 40
  static const int maxRfidLength = 48;

  final TextEditingController
  _rfidController =
  TextEditingController();

  bool _isSaving = false;

  Future<void>
  _saveRFID() async {

    final code =
    _rfidController.text
        .trim();

    // EMPTY FIELD
    if (code.isEmpty) {

      ScaffoldMessenger.of(
          context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Please scan RFID first",
          ),
        ),
      );

      return;
    }

    // LENGTH CHECK
    if (code.length >
        maxRfidLength) {

      ScaffoldMessenger.of(
          context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "RFID max length is $maxRfidLength",
          ),
        ),
      );

      return;
    }

    try {

      setState(() {
        _isSaving = true;
      });

      final response =
      await http.post(

        Uri.parse(
          "https://sewac-helper-app.onrender.com/api/v1/rfid/create/$code",
        ),
      );

      final body =
      response.body
          .toLowerCase();

      // SUCCESS
      if (response.statusCode ==
          200 ||
          response.statusCode ==
              201) {

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          const SnackBar(
            backgroundColor:
            Color(0xFF4CAF50),

            content: Text(
              "RFID saved successfully",
            ),
          ),
        );

        _rfidController.clear();
      }

      // RFID EXISTS
      else if (
      body.contains(
          "already exists") ||
          body.contains(
              "exists") ||
          body.contains(
              "duplicate")
      ) {

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          const SnackBar(
            content: Text(
              "RFID already exists",
            ),
          ),
        );
      }

      // OTHER BACKEND ERROR
      else {

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          const SnackBar(
            content: Text(
              "Failed to save RFID",
            ),
          ),
        );
      }

    }

    // INTERNET ISSUE
    on http.ClientException {

      ScaffoldMessenger.of(
          context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Failed due to internet connection",
          ),
        ),
      );
    }

    catch (_) {

      ScaffoldMessenger.of(
          context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Failed to save RFID",
          ),
        ),
      );
    }

    finally {

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _handleLogout() async {

    try {

      final prefs =
      await SharedPreferences.getInstance();

      final token =
          prefs.getString(
            "auth_token",
          ) ?? "";

      final response =
      await http.post(

        Uri.parse(
          "https://sewac-helper-app.onrender.com/api/v1/auth/logout",
        ),

        headers: {

          "Authorization":
          "Bearer $token",

          "Content-Type":
          "application/json",
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

    final prefs =
    await SharedPreferences.getInstance();

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
        builder: (_) =>
        const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor:
      const Color(0xFFF8F9FA),

      appBar: AppBar(
        toolbarHeight: 62,
        leadingWidth: 70,

        backgroundColor: const Color(0xFFF8FBF8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,

        centerTitle: true,

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),

        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            "assets/images/logo.png",
            height: 34,
            width: 34,
            fit: BoxFit.contain,
          ),
        ),

        title: const Text(
          "Helper App",
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _handleLogout,
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
        ],
      ),

      body: SewacBackground(
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
              24,
              110,
              24,
              24),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [

              const Text(
                "Reader",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(
                  height: 32),

              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets.all(
                    24),

                decoration:
                BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                      28),
                ),

                child: Column(
                  children: [

                    const Icon(
                      Icons.nfc_rounded,
                      size: 64,
                      color:
                      Color(0xFF4CAF50),
                    ),

                    const SizedBox(
                        height: 16),

                    const Text(
                      "Tap RFID Card",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                        height: 24),

                    TextFormField(
                      controller:
                      _rfidController,

                      autofocus: true,
                      showCursor: true,

                      decoration:
                      InputDecoration(
                        hintText:
                        "Tap RFID card to scan...",

                        filled: true,
                        fillColor:
                        Colors.white,

                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),

                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                              16),
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 24),

                    SizedBox(
                      width:
                      double.infinity,

                      child: Container(
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(
                              16),

                          gradient:
                          const LinearGradient(
                            colors: [
                              Color(
                                  0xFFFFA000),
                              Color(
                                  0xFF4CAF50),
                            ],
                          ),
                        ),

                        child:
                        ElevatedButton(

                          onPressed:
                          _isSaving
                              ? null
                              : _saveRFID,

                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            Colors.transparent,

                            shadowColor:
                            Colors.transparent,
                          ),

                          child:
                          const Text(
                            "SAVE",

                            style:
                            TextStyle(
                              color:
                              Colors.white,
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
  }
}