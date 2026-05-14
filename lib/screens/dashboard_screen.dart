import 'package:flutter/material.dart';
import '../widgets/sewac_button.dart';
import 'login_screen.dart';
import '../widgets/sewac_background.dart';

// API imports
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';


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
    print("AUTH TOKEN => $token");

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

  String? _selectedWetRFID;
  String? _selectedDryRFID;
  String? _selectedPhone;
  String? _selectedName;

  List<String> get _wetAvailableRfids {
    return _rfidDropdownItems.where((item) {
      if (item == "Select") return true;

      return item != _selectedDryRFID;
    }).toList();
  }

  List<String> get _dryAvailableRfids {
    return _rfidDropdownItems.where((item) {
      if (item == "Select") return true;

      return item != _selectedWetRFID;
    }).toList();
  }

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
  _wetRfidSearchController =
  TextEditingController();

  final TextEditingController
  _dryRfidSearchController =
  TextEditingController();

  final TextEditingController
  _phoneSearchController =
  TextEditingController();

  final TextEditingController
  _nameSearchController =
  TextEditingController();

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllDropdownData();

    // REQUIREMENT 1: Real-time auto refresh every 1 second
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) {
        _loadAllDropdownData();
      },
    );
  }

  @override
  void dispose() {
    // REQUIREMENT 6: Prevent memory leaks
    _refreshTimer?.cancel();
    _remarksController.dispose();
    _wetRfidSearchController.dispose();
    _dryRfidSearchController.dispose();
    _phoneSearchController.dispose();
    _nameSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDropdownData() async {

    // REQUIREMENT 2: Refresh unmapped RFIDs, citizen phones, and citizen names
    await Future.wait([

      _fetchUnmappedRFIDs(),
      _fetchPhones(),
      _fetchNames(),

    ]);
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

        if (result["success"] == true) {

          final List<dynamic>
          rfids =
          result["data"];

          final List<String> newList = [
            "Select",
            ...rfids.map(
                  (item) =>
                  item["slno"]
                      .toString(),
            ),
          ];

          setState(() {
            _rfidDropdownItems = newList;

            // REQUIREMENT 4: If an RFID gets mapped/used elsewhere, remove from selection
            if (_selectedWetRFID != null &&
                !_rfidDropdownItems.contains(_selectedWetRFID)) {
              _selectedWetRFID = null;
              _wetRfidSearchController.clear();
            }

            if (_selectedDryRFID != null &&
                !_rfidDropdownItems.contains(_selectedDryRFID)) {
              _selectedDryRFID = null;
              _dryRfidSearchController.clear();
            }
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
          "https://sewac-helper-app.onrender.com/api/v1/phone/unmapped",
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



  void _clearForm() {

    FocusScope.of(context).unfocus();

    setState(() {

      _selectedWetRFID = null;
      _selectedDryRFID = null;

      _wetRfidSearchController.clear();
      _dryRfidSearchController.clear();
      _selectedPhone = null;
      _selectedName = null;

      _status = "Found";

      _showValidation = false;
      _showRemarksError = false;

      _phoneSearchController.clear();
      _nameSearchController.clear();
      _remarksController.clear();
    });
  }

  Future<void> _handleSave() async {
    _refreshTimer?.cancel();
    final headers = await _getHeaders();

    _selectedPhone ??= _phoneSearchController.text.trim();
    _selectedName ??= _nameSearchController.text.trim();
    _selectedDryRFID ??= _dryRfidSearchController.text.trim();
    _selectedWetRFID ??= _wetRfidSearchController.text.trim();

    try {
      // Validation
      if (_status == "Found") {
        if (

        _selectedWetRFID == null ||
            _selectedWetRFID!.trim().isEmpty ||
            _selectedWetRFID == "Select" ||

            _selectedDryRFID == null ||
            _selectedDryRFID!.trim().isEmpty ||
            _selectedDryRFID == "Select" ||

            _selectedPhone == null ||
            _selectedPhone!.trim().isEmpty ||
            _selectedPhone == "Select" ||

            _selectedName == null ||
            _selectedName!.trim().isEmpty ||
            _selectedName == "Select"

        ) {
          setState(() {
            _showValidation = true;
          });

          return;
        }
      }

      if (_status == "Not Found") {

        bool hasPhoneNameError =

            _selectedPhone == null ||
                _selectedPhone!.trim().isEmpty ||
                _selectedPhone == "Select" ||

                _selectedName == null ||
                _selectedName!.trim().isEmpty ||
                _selectedName == "Select";

        bool hasRemarksError =
            _remarksController.text.trim().isEmpty;

        if (hasPhoneNameError || hasRemarksError) {

          setState(() {

            _showValidation = hasPhoneNameError;

            _showRemarksError = hasRemarksError;

          });

          return;
        }
      }
      http.Response? response;

      // ================= NOT FOUND =================
      if (_status == "Not Found") {

        // Save to remarks table
        final remarksResponse = await http.post(
          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/remarks/create",
          ),
          headers: headers,
          body: jsonEncode({
            "remark": _remarksController.text.trim(),
          }),
        );

        print("REMARKS STATUS => ${remarksResponse.statusCode}");
        print("REMARKS BODY => ${remarksResponse.body}");

        // Save to tracking table
        response = await http.post(
          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/tracking/create",
          ),
          headers: headers,
          body: jsonEncode({
            "phoneNumber": _selectedPhone!.trim(),
            "citizenName": _selectedName!.trim(),
            "status": "NOT_FOUND",
            "remarks": _remarksController.text.trim(),
          }),
        );

        print("NOT FOUND TRACKING STATUS => ${response.statusCode}");
        print("NOT FOUND TRACKING BODY => ${response.body}");
      }

      // ================= FOUND =================
      else {

        // Wet RFID mapping
        await http.patch(
          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/rfid/map",
          ),
          headers: headers,
          body: jsonEncode({
            "slno": _selectedWetRFID,
            "phoneNumber": _selectedPhone,
            "wasteType": "WET",
          }),
        );

        // Dry RFID mapping
        await http.patch(
          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/rfid/map",
          ),
          headers: headers,
          body: jsonEncode({
            "slno": _selectedDryRFID,
            "phoneNumber": _selectedPhone,
            "wasteType": "DRY",
          }),
        );

        // Tracking save
        response = await http.post(
          Uri.parse(
            "https://sewac-helper-app.onrender.com/api/v1/tracking/create",
          ),
          headers: headers,
          body: jsonEncode({
            "phoneNumber": _selectedPhone,
            "citizenName": _selectedName,
            "drySlno": _selectedDryRFID,
            "wetSlno": _selectedWetRFID,
            "status": "FOUND",
          }),
        );
      }

      print("SAVE STATUS: ${response?.statusCode}");
      print("SAVE BODY: ${response?.body}");

      if (!mounted) return;

      if (response != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data saved successfully"),
            backgroundColor: Colors.green,
          ),
        );

        _clearForm();
        await _loadAllDropdownData();

        _refreshTimer = Timer.periodic(
          const Duration(seconds: 2),
              (_) {
            _loadAllDropdownData();
          },
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Save failed (${response?.statusCode})",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {

      print("SAVE ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Server error"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  Future<void> _handleLogout() async {

    try {

      final headers =
      await _getHeaders();

      final response =
      await http.post(

        Uri.parse(
          "https://sewac-helper-app.onrender.com/api/v1/auth/logout",
        ),

        headers: headers,
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
  Widget build(
      BuildContext context) {

    return Scaffold(

      extendBodyBehindAppBar: false,

      backgroundColor:
      const Color(
          0xFFF8F9FA),

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

        child:
        SingleChildScrollView(

          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),

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
                  height: 16),

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
                      dropdownKey: ValueKey("wet_${_selectedDryRFID ?? "none"}"),
                      label: "Wet Waste RFID",
                      hint: "Select RFID Number",
                      controller: _wetRfidSearchController,
                      items: _wetAvailableRfids,
                      icon: Icons.water_drop_rounded,
                      onSelected: (value) {
                        if (value == null) return;

                        FocusScope.of(context).unfocus();

                        setState(() {
                          if (value == "Select") {
                            _selectedWetRFID = null;
                            _wetRfidSearchController.clear();
                          } else {
                            _selectedWetRFID = value;
                            _wetRfidSearchController.text = value;
                          }

                          _showValidation = false;
                        });
                      },
                    ),


                    const SizedBox(height: 16),

                    _buildSearchDropdown(
                      dropdownKey: ValueKey("dry_${_selectedWetRFID ?? "none"}"),
                      label: "Dry Waste RFID",
                      hint: "Select RFID Number",
                      controller: _dryRfidSearchController,
                      items: _dryAvailableRfids,
                      icon: Icons.recycling_rounded,
                      onSelected: (value) {
                        if (value == null) return;

                        FocusScope.of(context).unfocus();

                        setState(() {
                          if (value == "Select") {
                            _selectedDryRFID = null;
                            _dryRfidSearchController.clear();
                          } else {
                            _selectedDryRFID = value;
                            _dryRfidSearchController.text = value;
                          }

                          _showValidation = false;
                        });
                      },
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
                  height: 10),

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
                        decoration: InputDecoration(
                          labelText: "Remarks *",

                          hintText:
                          "Ex: House No, Address,\nData not present in database",

                          hintMaxLines: 2,

                          errorText:
                          _showRemarksError ? "Required" : null,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 12),

              SewacButton(
                text:
                "SAVE",
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
    Key? dropdownKey,
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> items,
    required IconData icon,
    required Function(String?) onSelected,
  }) {

    final bool hasError =
        _showValidation &&
            controller.text.trim().isEmpty &&
            (
                (_status == "Found") ||

                    (_status == "Not Found" &&
                        (label == "Phone Number" || label == "Name"))
            );

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
          key: dropdownKey,

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

            // Fill selected value only when different
            if (textController.text != controller.text) {
              textController.value = TextEditingValue(
                text: controller.text,
                selection: TextSelection.collapsed(
                  offset: controller.text.length,
                ),
              );
            }

            return TextField(

              controller: textController,

              focusNode: focusNode,

              onChanged: (value) {

                // allow backspace / manual typing
                controller.text = value;

                // if user clears manually, reset selected value
                if (value.isEmpty) {

                  if (label == "Wet Waste RFID") {
                    _selectedWetRFID = null;
                  }

                  if (label == "Dry Waste RFID") {
                    _selectedDryRFID = null;
                  }

                  if (label == "Phone Number") {
                    _selectedPhone = null;
                    _selectedName = null;
                    _nameSearchController.clear();
                  }

                  if (label == "Name") {
                    _selectedName = null;
                    _selectedPhone = null;
                    _phoneSearchController.clear();
                  }
                }
              },

              decoration: InputDecoration(

                hintText: hint,

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