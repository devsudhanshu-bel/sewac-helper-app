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

  Future<Map<String, String>> _getHeaders() async {

    final prefs =
    await SharedPreferences.getInstance();

    final token =
        prefs.getString("auth_token") ?? "";

    return {

      "Authorization":
      "Bearer $token",

      "Content-Type":
      "application/json",
    };
  }

  List<String> _rfidDropdownItems = [
    "Select"
  ];

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
      }

    } catch (e) {

      debugPrint(
          "PHONE API ERROR: $e");
    }
  }

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

  Future<void>
  _fetchCitizenByPhone(
      String phone) async {

    try {

      final headers =
      await _getHeaders();

      final response =
      await http.get(

        Uri.parse(
          "https://sewac-helper-app.onrender.com/api/v1/citizen/phone/$phone",
        ),

        headers: headers,
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
                ["phoneNumber"]
                    .toString();

            _selectedName =
                result["data"]
                ["citizenName"]
                    .toString();

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
          "PHONE MAP ERROR: $e");
    }
  }

  Future<void> _fetchCitizenByName(String name) async {

    try {

      final headers =
      await _getHeaders();

      final encodedName =
      Uri.encodeComponent(name);

      final response =
      await http.get(

        Uri.parse(
          "https://sewac-helper-app.onrender.com/api/v1/citizen/name/$encodedName",
        ),

        headers: headers,
      );

      if (response.statusCode == 200) {

        final result =
        jsonDecode(response.body);

        if (result["success"] == true) {

          final data =
          result["data"];

          // If API sends list
          final citizen =
          data is List
              ? data.first
              : data;

          setState(() {

            _selectedName =
                citizen["citizenName"]
                    .toString();

            _selectedPhone =
                citizen["phoneNumber"]
                    .toString();

            // THIS updates UI instantly
            _nameSearchController.text =
            _selectedName!;

            _phoneSearchController.text =
            _selectedPhone!;

            _showValidation =
            false;
          });
        }
      }

    } catch (e) {

      debugPrint(
        "NAME MAP ERROR: $e",
      );
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

        if (response.statusCode == 200 ||
            response.statusCode == 201) {

          ScaffoldMessenger.of(
              context)
              .showSnackBar(

            const SnackBar(
              content:
              Text(
                  'Data saved successfully'),
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

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          const SnackBar(
            content:
            Text(
                'Data saved successfully'),
          ),
        );

        _clearForm();
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
                  builder: (_) =>
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

                        onSelected: (val) async {

                          if (val == null) return;

                          if (val == "Select") {

                            FocusScope.of(context).unfocus();

                            setState(() {

                              _selectedPhone = null;
                              _selectedName = null;

                              _phoneSearchController.clear();
                              _nameSearchController.clear();
                            });

                            return;
                          }

                          await _fetchCitizenByPhone(val);
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

                      onSelected: (val) async {

                        if (val == null) return;

                        if (val == "Select") {

                          FocusScope.of(context).unfocus();

                          setState(() {

                            _selectedPhone = null;
                            _selectedName = null;

                            _phoneSearchController.clear();
                            _nameSearchController.clear();
                          });

                          return;
                        }

                        await _fetchCitizenByName(val);
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
                  horizontal: 24,
                  vertical: 20,
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
                    ),

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
                        maxLines: 3,
                        decoration:
                        InputDecoration(
                          labelText:
                          "Remarks",
                          errorText:
                          _showRemarksError
                              ? "Required"
                              : null,
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