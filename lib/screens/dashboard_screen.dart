  import 'package:flutter/material.dart';
  import '../widgets/sewac_button.dart';
  import 'login_screen.dart';
  import '../widgets/sewac_background.dart';

  // API imports
  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  class DashboardScreen extends StatefulWidget {
    const DashboardScreen({
      super.key,
    });

    @override
    State<DashboardScreen> createState() =>
        _DashboardScreenState();
  }

  class _DashboardScreenState
      extends State<DashboardScreen> {

    // TOKEN HEADERS (NEW)
    Future<Map<String, String>> _getHeaders() async {

      final prefs =
      await SharedPreferences.getInstance();

      final token =
          prefs.getString("token") ?? "";

      return {

        "Authorization":
        "Bearer $token",

        "Content-Type":
        "application/json",
      };
    }

    final List<Map<String, String>>
    _mockDatabase = [

      {
        'rfid': 'Select',
        'phone': 'Select',
        'name': 'Select'
      },

      {
        'rfid': 'RFID001',
        'phone': '9876543210',
        'name': 'John Doe'
      },

      {
        'rfid': 'RFID002',
        'phone': '9123456780',
        'name': 'Maria Garcia'
      },

      {
        'rfid': 'RFID003',
        'phone': '8887776665',
        'name': 'David Smith'
      },

      {
        'rfid': 'RFID004',
        'phone': '7776665554',
        'name': 'Sarah Connor'
      },

      {
        'rfid': 'RFID005',
        'phone': '9990001112',
        'name': 'Robert Brown'
      },
    ];

    // Backend serial numbers only
    List<String> _rfidDropdownItems = [
      "Select"
    ];

    // API DATA
    List<String> _phoneDropdownItems = [
      "Select"
    ];

    List<String> _nameDropdownItems = [
      "Select"
    ];

    String? _selectedRFID;
    String? _selectedPhone;
    String? _selectedName;

    String _status =
        'Found';

    bool _showValidation =
    false;

    bool _showRemarksError =
    false;

    final TextEditingController
    _remarksController =
    TextEditingController();

    final TextEditingController
    _rfidSearchController =
    TextEditingController();

    final TextEditingController
    _phoneSearchController =
    TextEditingController();

    final TextEditingController
    _nameSearchController =
    TextEditingController();

    @override
    void initState() {
      super.initState();

      _fetchUnmappedRFIDs();
      _fetchPhones();
      _fetchNames();
    }

    // RFID API
    Future<void>
    _fetchUnmappedRFIDs() async {

      try {

        final response =
        await http.get(

          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/rfid/unmapped",
          ),
        );

        if (response.statusCode ==
            200) {

          final result =
          jsonDecode(
              response.body);

          if (result[
          "success"] ==
              true) {

            final List<dynamic>
            rfids =
            result["data"];

            setState(() {

              _rfidDropdownItems = [
                "Select",
                ...rfids.map(
                      (item) =>
                      item["slno"]
                          .toString(),
                ),
              ];
            });
          }
        }

      } catch (e) {

        debugPrint(
            "RFID API error: $e");
      }
    }

    // PHONE API (UPDATED)
    Future<void> _fetchPhones() async {

      try {

        final headers =
        await _getHeaders();

        final response =
        await http.get(

          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/citizen/phones",
          ),

          headers: headers,
        );

        debugPrint(
            "PHONE STATUS: ${response.statusCode}");

        debugPrint(
            "PHONE BODY: ${response.body}");

        if (response.statusCode == 200) {

          final result =
          jsonDecode(
              response.body);

          final List<dynamic>
          phones =
              result["data"] ?? [];

          setState(() {

            _phoneDropdownItems = [

              "Select",

              ...phones.map(
                    (item) =>
                    item["phoneNumber"]
                        .toString()
                        .trim(),
              ),
            ];
          });

          debugPrint(
              "TOTAL PHONES: ${_phoneDropdownItems.length}");
        }

      } catch (e) {

        debugPrint(
            "PHONE API ERROR: $e");
      }
    }

    // NAME API (UPDATED)
    Future<void>
    _fetchNames() async {

      try {

        final headers =
        await _getHeaders();

        final response =
        await http.get(

          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/citizen/names",
          ),

          headers: headers,
        );

        debugPrint(
            "NAME RESPONSE: ${response.body}");

        if (response.statusCode ==
            200) {

          final result =
          jsonDecode(
              response.body);

          if (result[
          "success"] ==
              true) {

            final List<dynamic>
            names =
            result["data"];

            setState(() {

              _nameDropdownItems = [
                "Select",

                ...names.map(
                      (item) =>
                      item["citizenName"]
                          .toString()
                          .trim(),
                ),
              ];
            });
          }
        }

      } catch (e) {

        debugPrint(
            "NAME API error: $e");
      }
    }

    void _onRFIDSelected(
        String? value) {

      if (value == null) {
        return;
      }

      if (value == "Select") {

        FocusScope.of(context)
            .unfocus();

        setState(() {

          _selectedRFID = null;

          _rfidSearchController
              .clear();
        });

        return;
      }

      FocusScope.of(context)
          .unfocus();

      setState(() {

        _selectedRFID =
            value;

        _rfidSearchController
            .text =
            value;

        _showValidation =
        false;
      });
    }

    void _onPhoneOrNameSelected(
        String key,
        String? value) {

      if (value == null) {
        return;
      }

      if (value == "Select") {

        FocusScope.of(context)
            .unfocus();

        setState(() {

          _selectedPhone =
          null;

          _selectedName =
          null;

          _phoneSearchController
              .clear();

          _nameSearchController
              .clear();
        });

        return;
      }

      final record =
      _mockDatabase
          .firstWhere(
            (r) =>
        r[key] ==
            value,
        orElse: () => {},
      );

      if (record.isEmpty) {
        return;
      }

      FocusScope.of(context)
          .unfocus();

      setState(() {

        _selectedPhone =
        record['phone'];

        _selectedName =
        record['name'];

        _phoneSearchController
            .text =
        _selectedPhone!;

        _nameSearchController
            .text =
        _selectedName!;

        _showValidation =
        false;
      });
    }

    Future<void>
    _fetchCitizenByPhone(
        String phone) async {

      try {

        final response =
        await http.get(

          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/citizen/phone/$phone",
          ),
        );

        if (response.statusCode ==
            200) {

          final result =
          jsonDecode(
              response.body);

          if (result[
          "success"] ==
              true) {

            setState(() {

              _selectedPhone =
              result["data"]
              ["phoneNumber"];

              _selectedName =
              result["data"]
              ["citizenName"];

              _phoneSearchController
                  .text =
              _selectedPhone!;

              _nameSearchController
                  .text =
              _selectedName!;
            });
          }
        }

      } catch (e) {

        debugPrint(
            e.toString());
      }
    }

    void _clearForm() {

      FocusScope.of(context).unfocus();
      setState(() {

        _selectedRFID = null;
        _selectedPhone = null;
        _selectedName = null;

        _status = "Found";

        _showValidation = false;
        _showRemarksError = false;

        _rfidSearchController.clear();
        _phoneSearchController.clear();
        _nameSearchController.clear();
        _remarksController.clear();
      });
    }

    Future<void> _handleSave() async {

      final headers =
      await _getHeaders();

      // =============================
      // NOT FOUND → SAVE REMARKS
      // =============================
      if (_status ==
          "Not Found") {

        if (_remarksController
            .text
            .trim()
            .isEmpty) {

          setState(() {

            _showRemarksError =
            true;
          });

          return;
        }

        setState(() {

          _showRemarksError =
          false;
        });

        try {

          final response =
          await http.post(

            Uri.parse(
              "https://sewac-helper-app.onrender.com/api/v1/remarks/create",
            ),

            headers: headers,

            body: jsonEncode({

              "remark":
              _remarksController
                  .text
                  .trim(),
            }),
          );

          debugPrint(
              "REMARK RESPONSE: ${response.body}");

          if (response.statusCode == 200 ||
              response.statusCode == 201) {
            ScaffoldMessenger.of(
                context)
                .showSnackBar(

              const SnackBar(

                content:
                Text(
                    'Data saved successfully'),

                backgroundColor:
                Color(
                    0xFF4CAF50),
              ),
            );

            _clearForm();
          }
        } catch (e) {

          debugPrint(
              "REMARK ERROR: $e");
        }

        return;
      }

      // =============================
      // FOUND → SAVE RFID MAPPING
      // =============================
      if (_selectedRFID ==
          null ||
          _selectedPhone ==
              null ||
          _selectedName ==
              null) {

        setState(() {

          _showValidation =
          true;
        });

        return;
      }

      try {

        final response =
        await http.post(

          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/rfid/map",
          ),

          headers: headers,

          body: jsonEncode({

            "slno":
            _selectedRFID,

            "phoneNumber":
            _selectedPhone,
          }),
        );

        debugPrint(
            "MAP RESPONSE: ${response.body}");

        if (response.statusCode == 200 ||
            response.statusCode == 201) {

          ScaffoldMessenger.of(
              context)
              .showSnackBar(

            const SnackBar(

              content:
              Text(
                  'Data saved successfully'),

              backgroundColor:
              Color(
                  0xFF4CAF50),
            ),
          );
        }

      } catch (e) {

        debugPrint(
            "MAP ERROR: $e");
      }
    }

    @override
    Widget build(
        BuildContext context) {

      return Scaffold(

        extendBodyBehindAppBar:
        true,

        backgroundColor:
        const Color(
            0xFFF8F9FA),

        appBar: AppBar(
          leadingWidth: 70,

          backgroundColor:
          Colors.transparent,

          elevation: 0,

          surfaceTintColor:
          Colors.transparent,

          scrolledUnderElevation:
          0,

          centerTitle:
          true,

          leading:
          Padding(

            padding:
            const EdgeInsets.only(
                left: 16),

            child:
            Image.asset(
              "assets/images/logo.png",
              height: 60,
              width: 60,
              fit: BoxFit.contain,

              errorBuilder:
                  (
                  context,
                  error,
                  stackTrace,
                  ) {

                return const Icon(
                  Icons.recycling,

                  color:
                  Color(
                      0xFF4CAF50),
                );
              },
            ),
          ),

          title:
          const Text(

            "Helper App",

            style:
            TextStyle(

              color:
              Color(
                  0xFF1A237E),

              fontWeight:
              FontWeight.w900,

              fontSize: 20,
            ),
          ),

          actions: [

            IconButton(

              icon:
              const Icon(

                Icons.logout_rounded,

                color:
                Color(
                    0xFF1A237E),
              ),

              onPressed:
                  () {

                Navigator.pushReplacement(

                  context,

                  MaterialPageRoute(

                    builder:
                        (_) =>
                    const LoginScreen(),
                  ),
                );
              },
            ),

            const SizedBox(
                width: 8),
          ],
        ),

        body: SewacBackground(

          child:
          SingleChildScrollView(

            padding:
            const EdgeInsets.fromLTRB(
                24,
                110,
                24,
                24),

            child:
            Column(

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                const Text(

                  "RFID Mapping",

                  style:
                  TextStyle(

                    fontSize: 28,

                    fontWeight:
                    FontWeight.bold,

                    color:
                    Color(
                        0xFF2C3E50),
                  ),
                ),

                const Text(

                  "Sync resident details from the secure database",

                  style:
                  TextStyle(

                    color:
                    Colors.blueGrey,

                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                    height: 32),

                Container(

                  padding:
                  const EdgeInsets.all(
                      24),

                  decoration:
                  BoxDecoration(

                    color:
                    Colors.white,

                    borderRadius:
                    BorderRadius.circular(
                        28),
                  ),

                  child:
                  Column(

                    children: [

                      _buildSearchDropdown(

                        label:
                        "RFID",

                        hint:
                        "Select RFID Number",

                        controller:
                        _rfidSearchController,

                        items:
                        _rfidDropdownItems,

                        icon:
                        Icons.qr_code_scanner_rounded,

                        onSelected:
                        _onRFIDSelected,
                      ),

                      const SizedBox(
                          height: 24),

                      _buildSearchDropdown(

                        label:
                        "Phone Number",

                        hint:
                        "Select Phone Number",

                        controller:
                        _phoneSearchController,

                        items:
                        _phoneDropdownItems,

                        icon:
                        Icons.phone_iphone_rounded,

                        onSelected:
                            (
                            val,
                            ) async {

                          _onPhoneOrNameSelected(
                              'phone',
                              val);

                          if (val !=
                              null &&
                              val !=
                                  "Select") {

                            await _fetchCitizenByPhone(
                                val);
                          }
                        },
                      ),

                      const SizedBox(
                          height: 24),

                      _buildSearchDropdown(

                        label:
                        "Name",

                        hint:
                        "Citizen Name",

                        controller:
                        _nameSearchController,

                        items:
                        _nameDropdownItems,

                        icon:
                        Icons.person_pin_rounded,

                        onSelected:
                            (
                            val,
                            ) {

                          _onPhoneOrNameSelected(
                              'name',
                              val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height: 24),

                Container(

                  padding:
                  const EdgeInsets.symmetric(

                    horizontal:
                    24,

                    vertical:
                    20,
                  ),

                  decoration:
                  BoxDecoration(

                    color:
                    Colors.white,

                    borderRadius:
                    BorderRadius.circular(
                        28),
                  ),

                  child:
                  Column(

                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      const Text(

                        "Status Selection",

                        style:
                        TextStyle(

                          fontWeight:
                          FontWeight.w800,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      Row(

                        children: [

                          Expanded(

                            child:
                            RadioListTile<String>(

                              title:
                              const Text(
                                  "Found"),

                              value:
                              'Found',

                              groupValue:
                              _status,

                              contentPadding:
                              EdgeInsets.zero,

                              onChanged:
                                  (
                                  value,
                                  ) {

                                setState(
                                      () {

                                    _status =
                                    value!;
                                  },
                                );
                              },
                            ),
                          ),

                          Expanded(

                            child:
                            RadioListTile<String>(

                              title:
                              const Text(
                                  "Not Found"),

                              value:
                              'Not Found',

                              groupValue:
                              _status,

                              contentPadding:
                              EdgeInsets.zero,

                              onChanged:
                                  (
                                  value,
                                  ) {

                                setState(
                                      () {

                                    _status =
                                    value!;
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      if (_status ==
                          "Not Found")
                        TextField(

                          controller:
                          _remarksController,

                          maxLines:
                          3,

                          decoration:
                          InputDecoration(

                            labelText:
                            "Remarks",

                            errorText:
                            _showRemarksError
                                ? "Required"
                                : null,

                            border:
                            OutlineInputBorder(

                              borderRadius:
                              BorderRadius.circular(
                                  16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(
                    height: 48),

                SewacButton(

                  text:
                  "SAVE COLLECTION DATA",

                  onPressed:
                  _handleSave,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildSearchDropdown({

      required String label,
      required String hint,
      required TextEditingController controller,
      required List<String> items,
      required IconData icon,
      required Function(String?) onSelected,
    }) {

      final bool hasError =
          _showValidation &&
              _status ==
                  "Found" &&
              controller.text
                  .trim()
                  .isEmpty;

      return Column(

        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [

          Padding(

            padding:
            const EdgeInsets.only(

              left: 4,
              bottom: 8,
            ),

            child:
            Text(label),
          ),

          Autocomplete<String>(

            optionsBuilder:
                (
                value,
                ) {

              if (value.text
                  .isEmpty) {

                return items;
              }

              return items.where(
                    (item) {

                  return item
                      .toLowerCase()
                      .contains(
                    value.text
                        .toLowerCase(),
                  );
                },
              );
            },

            onSelected:
            onSelected,

            fieldViewBuilder:
                (
                context,
                textController,
                focusNode,
                onEditingComplete,
                ) {

              textController.text =
                  controller.text;

              return TextField(

                controller:
                textController,

                focusNode:
                focusNode,

                decoration:
                InputDecoration(

                  hintText:
                  hint,

                  errorText:
                  hasError
                      ? "Required"
                      : null,

                  prefixIcon:
                  Icon(icon),
                ),
              );
            },
          ),
        ],
      );
    }
  }