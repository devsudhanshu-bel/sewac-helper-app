import 'package:flutter/material.dart';
import '../widgets/sewac_button.dart';
import 'login_screen.dart';
import '../widgets/sewac_background.dart';
import '../widgets/sewac_header.dart';
import 'dart:io';

// API imports
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'dart:async';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _adminName = "A";
  int? _assignedStartRFID;
  int? _assignedEndRFID;
  List<String> _assignedMappedTagsList = [];
  bool _isRangeExhausted = false;

  int get _availableTags {
    if (_assignedStartRFID == null || _assignedEndRFID == null) return 0;

    return ((_assignedEndRFID! - _assignedStartRFID!) + 1) -
        _assignedMappedTagsList.length;
  }
  bool _hasPhoto = false;

  XFile? _imageFile;

  // Focus nodes to detect focus loss for resetting fields
  final FocusNode _wetFocusNode = FocusNode();
  final FocusNode _dryFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  Future<void> _capturePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _hasPhoto = true;
        });
        print("Camera photo captured: ${pickedFile.path}");
      }
    } catch (e) {
      print("Error picking image from camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open camera or capture photo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString("admin_name") ?? "A";
    });
  }

  Future<void> _loadRFIDRange() async {
    final prefs = await SharedPreferences.getInstance();

    final workerId =
        prefs.getString("workerId") ??
            prefs.getString("worker_id") ??
            prefs.getString("username") ??
            "";

    final start =
    prefs.getInt("assignedStartRFID_$workerId");

    final end =
    prefs.getInt("assignedEndRFID_$workerId");

    final mapped =
        prefs.getStringList(
          "assignedMappedTagsList_$workerId",
        ) ?? [];

    setState(() {
      _assignedStartRFID = start;
      _assignedEndRFID = end;
      _assignedMappedTagsList = mapped;
    });

    if (start == null || end == null) {
      _showRFIDRangeDialog();
      return;
    }

    if (_availableTags <= 0) {
      _showRFIDExhaustedDialog();
    }
  }

  void _showRFIDRangeDialog() {
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        bool startError = false;
        bool endError = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A236).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFF00A236),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Assign RFID Range",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Enter the RFID range assigned to you",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 20),

                    // Start RFID Textfield
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        "Start RFID *",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ),
                    TextField(
                      controller: startController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter Start Number",
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        prefixIcon: const Icon(Icons.tag, color: Colors.black54, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        errorText: startError ? "Required" : null,
                        errorStyle: const TextStyle(color: Colors.red),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: startError ? Colors.red.shade400 : Colors.black12,
                            width: startError ? 1.5 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: startError ? Colors.red.shade400 : const Color(0xFF00A236),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End RFID Textfield
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        "End RFID *",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ),
                    TextField(
                      controller: endController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter End Number",
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        prefixIcon: const Icon(Icons.tag, color: Colors.black54, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        errorText: endError ? "Required" : null,
                        errorStyle: const TextStyle(color: Colors.red),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: endError ? Colors.red.shade400 : Colors.black12,
                            width: endError ? 1.5 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: endError ? Colors.red.shade400 : const Color(0xFF00A236),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        setDialogState(() {
                          startError = startController.text.trim().isEmpty;
                          endError = endController.text.trim().isEmpty;
                          errorMessage = null;
                        });

                        if (startError || endError) return;

                        final start = int.tryParse(startController.text.trim());
                        final end = int.tryParse(endController.text.trim());

                        if (start == null || end == null) {
                          setDialogState(() {
                            errorMessage = "Please enter valid RFID numbers";
                          });
                          return;
                        }

                        if (start >= end) {
                          setDialogState(() {
                            errorMessage = "End RFID must be greater than Start RFID";
                          });
                          return;
                        }

                        final prefs = await SharedPreferences.getInstance();
                        final workerId = prefs.getString("workerId") ??
                            prefs.getString("worker_id") ??
                            prefs.getString("username") ?? "";

                        await prefs.setInt("assignedStartRFID_$workerId", start);
                        await prefs.setInt("assignedEndRFID_$workerId", end);

                        if (_isRangeExhausted) {
                          await prefs.setStringList("assignedMappedTagsList_$workerId", []);
                          setState(() {
                            _assignedMappedTagsList = [];
                          });
                          _isRangeExhausted = false;
                        }

                        setState(() {
                          _assignedStartRFID = start;
                          _assignedEndRFID = end;
                        });

                        Navigator.pop(context);
                        await _loadAllDropdownData();
                      },
                      child: const Center(
                        child: Text(
                          "SAVE RANGE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRFIDExhaustedDialog() {
    _isRangeExhausted = true;
    _showRFIDRangeDialog();
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token") ?? "";
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  List<String> _rfidDropdownItems = ["Select"];
  List<String> _phoneDropdownItems = ["Select"];
  List<String> _nameDropdownItems = ["Select"];

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

  String _status = 'Found';
  bool _showValidation = false;
  bool _showRemarksError = false;

  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();

  final TextEditingController _wetRfidSearchController = TextEditingController();
  final TextEditingController _dryRfidSearchController = TextEditingController();
  final TextEditingController _phoneSearchController = TextEditingController();
  final TextEditingController _nameSearchController = TextEditingController();

  void _handleOutsideTapReset() {
    if (_wetFocusNode.hasFocus) {
      setState(() {
        _selectedWetRFID = null;
        _wetRfidSearchController.clear();
      });
    } else if (_dryFocusNode.hasFocus) {
      setState(() {
        _selectedDryRFID = null;
        _dryRfidSearchController.clear();
      });
    } else if (_phoneFocusNode.hasFocus) {
      setState(() {
        _selectedPhone = null;
        _selectedName = null;
        _phoneSearchController.clear();
        _nameSearchController.clear();
      });
    } else if (_nameFocusNode.hasFocus) {
      setState(() {
        _selectedName = null;
        _selectedPhone = null;
        _nameSearchController.clear();
        _phoneSearchController.clear();
      });
    }
    FocusScope.of(context).unfocus();
  }

  @override
  void initState() {
    super.initState();

    // Add focus listeners to handle automatic reset on focus loss
    _wetFocusNode.addListener(() {
      if (!_wetFocusNode.hasFocus) {
        if (_wetRfidSearchController.text.trim().isEmpty ||
            _wetRfidSearchController.text.trim() == "Select" ||
            _selectedWetRFID == null) {
          setState(() {
            _selectedWetRFID = null;
            _wetRfidSearchController.clear();
          });
        }
      }
    });

    _dryFocusNode.addListener(() {
      if (!_dryFocusNode.hasFocus) {
        if (_dryRfidSearchController.text.trim().isEmpty ||
            _dryRfidSearchController.text.trim() == "Select" ||
            _selectedDryRFID == null) {
          setState(() {
            _selectedDryRFID = null;
            _dryRfidSearchController.clear();
          });
        }
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        if (_phoneSearchController.text.trim().isEmpty ||
            _phoneSearchController.text.trim() == "Select" ||
            _selectedPhone == null) {
          setState(() {
            _selectedPhone = null;
            _selectedName = null;
            _phoneSearchController.clear();
            _nameSearchController.clear();
          });
        }
      }
    });

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        if (_nameSearchController.text.trim().isEmpty ||
            _nameSearchController.text.trim() == "Select" ||
            _selectedName == null) {
          setState(() {
            _selectedName = null;
            _selectedPhone = null;
            _nameSearchController.clear();
            _phoneSearchController.clear();
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAdminName();
      await _loadRFIDRange();
      await _loadAllDropdownData();
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _wetRfidSearchController.dispose();
    _dryRfidSearchController.dispose();
    _phoneSearchController.dispose();
    _nameSearchController.dispose();
    _wetFocusNode.dispose();
    _dryFocusNode.dispose();
    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllDropdownData() async {
    await Future.wait([
      _fetchUnmappedRFIDs(),
      _fetchPhones(),
      _fetchNames(),
    ]);
  }

  Future<void> _fetchUnmappedRFIDs() async {
    try {
      final response = await http.get(
        Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/rfid/unmapped"),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["success"] == true) {
          final List<dynamic> rfids = result["data"];
          final filteredRFIDs = rfids.where((item) {
            final value = int.tryParse(item["slno"].toString());

            if (value == null) return false;
            if (_assignedStartRFID == null) return false;
            if (_assignedEndRFID == null) return false;

            return value >= _assignedStartRFID! && value <= _assignedEndRFID!;
          }).toList();

          final List<String> newList = [
            "Select",
            ...filteredRFIDs.map((item) => item["slno"].toString()),
          ];

          setState(() {
            _rfidDropdownItems = newList;
            if (_selectedWetRFID != null && !_rfidDropdownItems.contains(_selectedWetRFID)) {
              _selectedWetRFID = null;
              _wetRfidSearchController.clear();
            }
            if (_selectedDryRFID != null && !_rfidDropdownItems.contains(_selectedDryRFID)) {
              _selectedDryRFID = null;
              _dryRfidSearchController.clear();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("RFID API error: $e");
    }
  }

  Future<void> _fetchPhones() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/phone/unmapped"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<dynamic> phones = result["data"] ?? [];
        setState(() {
          _phoneDropdownItems = [
            "Select",
            ...phones.map((item) => item["phoneNumber"].toString().trim()),
          ];
        });
      }
    } catch (e) {
      debugPrint("PHONE API ERROR: $e");
    }
  }

  Future<void> _fetchNames() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/citizen/unmapped"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["success"] == true) {
          final List<dynamic> names = result["data"];
          setState(() {
            _nameDropdownItems = [
              "Select",
              ...names.map((item) => item["citizenName"].toString().trim()),
            ];
          });
        }
      }
    } catch (e) {
      debugPrint("NAME API error: $e");
    }
  }

  Future<void> _fetchCitizenByPhone(String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/citizen/phone/$phone"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["success"] == true) {
          setState(() {
            _selectedPhone = result["data"]["phoneNumber"].toString();
            _selectedName = result["data"]["citizenName"].toString();
            _phoneSearchController.text = _selectedPhone!;
            _nameSearchController.text = _selectedName!;
          });
        }
      }
    } catch (e) {
      debugPrint("PHONE MAP ERROR: $e");
    }
  }

  Future<void> _fetchCitizenByName(String name) async {
    try {
      final headers = await _getHeaders();
      final encodedName = Uri.encodeComponent(name);
      final response = await http.get(
        Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/citizen/name/$encodedName"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["success"] == true) {
          final data = result["data"];
          final citizen = data is List ? data.first : data;

          setState(() {
            _selectedName = citizen["citizenName"].toString();
            _selectedPhone = citizen["phoneNumber"].toString();
            _nameSearchController.text = _selectedName!;
            _phoneSearchController.text = _selectedPhone!;
            _showValidation = false;
          });
        }
      }
    } catch (e) {
      debugPrint("NAME MAP ERROR: $e");
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
      _hasPhoto = false;
      _imageFile = null;
      _phoneSearchController.clear();
      _nameSearchController.clear();
      _remarksController.clear();
      _addressController.clear();
      _buildingController.clear();
      _floorController.clear();
    });
  }

  Widget _buildVerificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    final String savedWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
    final String savedDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();
    final String savedPhone = _selectedPhone ?? _phoneSearchController.text.trim();
    final String savedName = _selectedName ?? _nameSearchController.text.trim();

    final bool hasWet = savedWet.isNotEmpty && savedWet != "Select";
    final bool hasDry = savedDry.isNotEmpty && savedDry != "Select";

    final String formattedWet = hasWet ? savedWet : "Not Selected";
    final String formattedDry = hasDry ? savedDry : "Not Selected";

    final confirmWetController = TextEditingController();
    final confirmDryController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool wetConfirmError = false;
        bool dryConfirmError = false;
        String? modalErrorMessage;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.0),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              content: SizedBox(
                width: MediaQuery.of(context).size.width - 48,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A236).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF00A236),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Verify Details",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Please verify all information before saving.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: 16),

                      // Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVerificationRow("Citizen Name", savedName),
                            const Divider(height: 20, color: Colors.black12),
                            _buildVerificationRow("Phone Number", savedPhone),
                            const Divider(height: 20, color: Colors.black12),
                            _buildVerificationRow("Wet Waste RFID", formattedWet),
                            const Divider(height: 20, color: Colors.black12),
                            _buildVerificationRow("Dry Waste RFID", formattedDry),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Wet RFID Confirmation Field
                      if (hasWet) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            "Confirm Wet RFID *",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ),
                        TextField(
                          controller: confirmWetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Re-enter Wet RFID number",
                            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                            prefixIcon: const Icon(Icons.qr_code, color: Colors.black54, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            errorText: wetConfirmError ? "Required" : null,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: wetConfirmError ? Colors.red.shade400 : Colors.black12,
                                width: wetConfirmError ? 1.5 : 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: wetConfirmError ? Colors.red.shade400 : const Color(0xFF00A236),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Dry RFID Confirmation Field
                      if (hasDry) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            "Confirm Dry RFID *",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ),
                        TextField(
                          controller: confirmDryController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Re-enter Dry RFID number",
                            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                            prefixIcon: const Icon(Icons.qr_code, color: Colors.black54, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            errorText: dryConfirmError ? "Required" : null,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: dryConfirmError ? Colors.red.shade400 : Colors.black12,
                                width: dryConfirmError ? 1.5 : 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: dryConfirmError ? Colors.red.shade400 : const Color(0xFF00A236),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Validation Error Message Area
                      if (modalErrorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  modalErrorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "CANCEL",
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              final String wetInput = confirmWetController.text.trim();
                              final String dryInput = confirmDryController.text.trim();

                              setModalState(() {
                                wetConfirmError = hasWet && wetInput.isEmpty;
                                dryConfirmError = hasDry && dryInput.isEmpty;
                                modalErrorMessage = null;
                              });

                              if (wetConfirmError || dryConfirmError) return;

                              if (hasWet && wetInput != savedWet) {
                                setModalState(() {
                                  modalErrorMessage = "Wet RFID confirmation does not match";
                                });
                                return;
                              }

                              if (hasDry && dryInput != savedDry) {
                                setModalState(() {
                                  modalErrorMessage = "Dry RFID confirmation does not match";
                                });
                                return;
                              }

                              Navigator.of(context).pop();
                              _handleSave();
                            },
                            child: const Center(
                              child: Text(
                                "CONFIRM",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final String savedWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
    final String savedDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();
    final String savedPhone = _selectedPhone ?? _phoneSearchController.text.trim();
    final String savedName = _selectedName ?? _nameSearchController.text.trim();

    try {
      if (_status == "Found") {
        final bool wetEmpty = savedWet.isEmpty || savedWet == "Select";
        final bool dryEmpty = savedDry.isEmpty || savedDry == "Select";

        if ((wetEmpty && dryEmpty) ||
            savedPhone.isEmpty || savedPhone == "Select" ||
            savedName.isEmpty || savedName == "Select") {
          setState(() {
            _showValidation = true;
          });
          return;
        }
      }

      double? latitude;
      double? longitude;

      if (_status == "Not Found") {
        bool hasAddressError = _addressController.text.trim().isEmpty;
        bool hasBuildingError = _buildingController.text.trim().isEmpty;
        bool hasFloorError = _floorController.text.trim().isEmpty;
        bool hasRemarksError = _remarksController.text.trim().isEmpty;
        bool hasPhotoError = !_hasPhoto;

        if (hasAddressError || hasBuildingError || hasFloorError || hasRemarksError || hasPhotoError) {
          setState(() {
            _showValidation = true;
            _showRemarksError = hasRemarksError;
          });
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
        );

        try {
          Position position = await _determinePosition();
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (locationError) {
          if (mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Location Error: $locationError"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (mounted) Navigator.pop(context);
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final activeWorkerId = prefs.getString("workerId") ??
          prefs.getString("worker_id") ??
          prefs.getString("username") ?? "";

      http.Response? response;

      if (_status == "Not Found") {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/tracking/create"),
        );

        request.headers["Authorization"] = "Bearer $token";
        request.fields["status"] = "NOT_FOUND";
        request.fields["workerId"] = activeWorkerId.trim();
        request.fields["address"] = _addressController.text.trim();
        request.fields["buildingNo"] = _buildingController.text.trim();
        request.fields["floorNo"] = _floorController.text.trim();
        request.fields["remarks"] = _remarksController.text.trim();
        request.fields["latitude"] = latitude != null ? latitude.toString() : "";
        request.fields["longitude"] = longitude != null ? longitude.toString() : "";

        if (_imageFile != null) {
          final bytes = await _imageFile!.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              "photo",
              bytes,
              filename: _imageFile!.name,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        final headers = {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        };

        final bool absoluteWetEmpty = savedWet.isEmpty || savedWet == "Select";
        final bool absoluteDryEmpty = savedDry.isEmpty || savedDry == "Select";

        if (!absoluteWetEmpty) {
          final wetMapResponse = await http.patch(
            Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/rfid/map"),
            headers: headers,
            body: jsonEncode({
              "slno": savedWet,
              "phoneNumber": savedPhone,
              "wasteType": "WET",
            }),
          );

          if (wetMapResponse.statusCode < 200 || wetMapResponse.statusCode >= 300) {
            if (mounted) Navigator.pop(context);
            try {
              final errorJson = jsonDecode(wetMapResponse.body);
              final serverMsg = errorJson["message"] ?? "Failed to map Wet RFID";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(serverMsg), backgroundColor: Colors.red),
              );
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to map Wet RFID"), backgroundColor: Colors.red),
              );
            }
            return;
          }
        }

        if (!absoluteDryEmpty) {
          final dryMapResponse = await http.patch(
            Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/rfid/map"),
            headers: headers,
            body: jsonEncode({
              "slno": savedDry,
              "phoneNumber": savedPhone,
              "wasteType": "DRY",
            }),
          );

          if (dryMapResponse.statusCode < 200 || dryMapResponse.statusCode >= 300) {
            if (mounted) Navigator.pop(context);
            try {
              final errorJson = jsonDecode(dryMapResponse.body);
              final serverMsg = errorJson["message"] ?? "Failed to map Dry RFID";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(serverMsg), backgroundColor: Colors.red),
              );
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to map Dry RFID"), backgroundColor: Colors.red),
              );
            }
            return;
          }
        }

        response = await http.post(
          Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/tracking/create"),
          headers: headers,
          body: jsonEncode({
            "slno": absoluteWetEmpty ? "N/A" : savedWet,
            "phoneNumber": savedPhone,
            "citizenName": savedName,
            "workerId": activeWorkerId.trim(),
            "drySlno": absoluteDryEmpty ? "N/A" : savedDry,
            "wetSlno": absoluteWetEmpty ? "N/A" : savedWet,
            "status": "FOUND",
          }),
        );
      }

      if (mounted) Navigator.pop(context);

      if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data saved successfully"),
            backgroundColor: Colors.green,
          ),
        );

        if (_status != "Not Found") {
          setState(() {
            _rfidDropdownItems.removeWhere((item) => item == savedWet || item == savedDry);
            _phoneDropdownItems.removeWhere((item) => item == savedPhone);
            _nameDropdownItems.removeWhere((item) => item == savedName);
          });
        }

        final prefs = await SharedPreferences.getInstance();

        if (savedWet.isNotEmpty && savedWet != "Select" && !_assignedMappedTagsList.contains(savedWet)) {
          _assignedMappedTagsList.add(savedWet);
        }

        if (savedDry.isNotEmpty && savedDry != "Select" && !_assignedMappedTagsList.contains(savedDry)) {
          _assignedMappedTagsList.add(savedDry);
        }

        await prefs.setStringList(
          "assignedMappedTagsList_$activeWorkerId",
          _assignedMappedTagsList,
        );

        if (_availableTags <= 0) {
          _showRFIDExhaustedDialog();
        }

        _clearForm();

        await Future.wait([
          _loadRFIDRange(),
          _fetchUnmappedRFIDs(),
          _fetchPhones(),
          _fetchNames(),
        ]);

        if (mounted) {
          setState(() {});
        }
      } else {
        try {
          final errorJson = jsonDecode(response?.body ?? "{}");
          final serverMsg = errorJson["message"] ?? "Save failed (${response?.statusCode})";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(serverMsg), backgroundColor: Colors.red),
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Save failed (${response?.statusCode})"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Server connection error"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      await http.post(
        Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/auth/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
    } catch (e) {
      print("DASHBOARD LOGOUT API ERROR => $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("isLoggedIn");
    await prefs.remove("username");
    await prefs.remove("user");
    await prefs.remove("admin_name");

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showPhotoError = _showValidation && !_hasPhoto;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleOutsideTapReset,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: SewacHeader(
          onLogout: _handleLogout,
        ),
        body: SewacBackground(
          child: RefreshIndicator(
            color: const Color(0xFF00A236),
            onRefresh: _loadAllDropdownData,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 44,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Clean, Minimalist Welcome Block
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF00A236).withOpacity(0.1),
                              child: Text(
                                _adminName.isNotEmpty ? _adminName[0].toUpperCase() : "A",
                                style: const TextStyle(
                                  color: Color(0xFF00A236),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome $_adminName",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const Text(
                                    "Let's map some tags today!",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24), // Increased spacing since the bar is removed

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "RFID Mapping",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const Text(
                              "Sync resident details from the secure database",
                              style: TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEFEF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.black12, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _status = 'Found'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _status == 'Found' ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: _status == 'Found'
                                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                              : [],
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Found",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: _status == 'Found' ? const Color(0xFF00A236) : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _status = 'Not Found'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _status == 'Not Found' ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: _status == 'Not Found'
                                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                              : [],
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Not Found",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: _status == 'Not Found' ? const Color(0xFF00A236) : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                final offsetAnimation = Tween<Offset>(
                                  begin: const Offset(0.08, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ));
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _status == "Found"
                                  ? Container(
                                key: const ValueKey("found"),
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
                                  border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
                                ),
                                child: Column(
                                  children: [
                                    _buildSearchDropdown(
                                      label: "Wet Waste RFID *",
                                      hint: "Search Wet RFID",
                                      controller: _wetRfidSearchController,
                                      focusNode: _wetFocusNode,
                                      items: _wetAvailableRfids,
                                      icon: Icons.qr_code_scanner_rounded,
                                      onSelected: (val) {
                                        setState(() {
                                          if (val == "Select") {
                                            _selectedWetRFID = null;
                                            _wetRfidSearchController.clear();
                                            FocusScope.of(context).unfocus();
                                          } else {
                                            _selectedWetRFID = val;
                                            _wetRfidSearchController.text = val ?? "";
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    _buildSearchDropdown(
                                      label: "Dry Waste RFID *",
                                      hint: "Search Dry RFID",
                                      controller: _dryRfidSearchController,
                                      focusNode: _dryFocusNode,
                                      items: _dryAvailableRfids,
                                      icon: Icons.qr_code_scanner_rounded,
                                      onSelected: (val) {
                                        setState(() {
                                          if (val == "Select") {
                                            _selectedDryRFID = null;
                                            _dryRfidSearchController.clear();
                                            FocusScope.of(context).unfocus();
                                          } else {
                                            _selectedDryRFID = val;
                                            _dryRfidSearchController.text = val ?? "";
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    _buildSearchDropdown(
                                      label: "Phone Number *",
                                      hint: "Search Phone Number",
                                      controller: _phoneSearchController,
                                      focusNode: _phoneFocusNode,
                                      items: _phoneDropdownItems,
                                      icon: Icons.phone_android_rounded,
                                      onSelected: (val) {
                                        if (val == "Select") {
                                          setState(() {
                                            _selectedPhone = null;
                                            _selectedName = null;
                                            _phoneSearchController.clear();
                                            _nameSearchController.clear();
                                            FocusScope.of(context).unfocus();
                                          });
                                        } else if (val != null) {
                                          _fetchCitizenByPhone(val);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    _buildSearchDropdown(
                                      label: "Name *",
                                      hint: "Search Name",
                                      controller: _nameSearchController,
                                      focusNode: _nameFocusNode,
                                      items: _nameDropdownItems,
                                      icon: Icons.person_outline_rounded,
                                      onSelected: (val) {
                                        if (val == "Select") {
                                          setState(() {
                                            _selectedName = null;
                                            _selectedPhone = null;
                                            _nameSearchController.clear();
                                            _phoneSearchController.clear();
                                            FocusScope.of(context).unfocus();
                                          });
                                        } else if (val != null) {
                                          _fetchCitizenByName(val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              )
                                  : Container(
                                key: const ValueKey("not_found"),
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
                                  border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputField(
                                      label: "Address *",
                                      hint: "Enter Address",
                                      controller: _addressController,
                                      icon: Icons.location_on_outlined,
                                      showError: _showValidation && _addressController.text.trim().isEmpty,
                                    ),
                                    const SizedBox(height: 18),
                                    _buildInputField(
                                      label: "Building No *",
                                      hint: "Enter Building Number",
                                      controller: _buildingController,
                                      icon: Icons.apartment_outlined,
                                      showError: _showValidation && _buildingController.text.trim().isEmpty,
                                    ),
                                    const SizedBox(height: 18),
                                    _buildInputField(
                                      label: "Floor No *",
                                      hint: "Enter Floor Number",
                                      controller: _floorController,
                                      icon: Icons.unfold_more_outlined,
                                      showError: _showValidation && _floorController.text.trim().isEmpty,
                                    ),
                                    const SizedBox(height: 18),
                                    _buildInputField(
                                      label: "Remarks *",
                                      hint: "Enter Remarks",
                                      controller: _remarksController,
                                      icon: Icons.notes_outlined,
                                      showError: _showRemarksError,
                                      maxLines: null,
                                      minLines: 2,
                                    ),
                                    const SizedBox(height: 18),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4, bottom: 8),
                                      child: Text(
                                        "Photo *",
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D)),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _capturePhoto,
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: showPhotoError ? const Color(0xFFFFF5F5) : const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: showPhotoError ? Colors.red.shade400 : Colors.black12,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _hasPhoto && _imageFile != null
                                            ? ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.file(
                                            File(_imageFile!.path),
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                            : Icon(
                                          Icons.add_a_photo_outlined,
                                          color: showPhotoError ? Colors.red.shade400 : Colors.black54,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    if (showPhotoError)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4, top: 6),
                                        child: Text("Required", style: TextStyle(color: Colors.red, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: SewacButton(
                            text: "SAVE",
                            onPressed: () {
                              if (_status == "Found") {
                                final String savedWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
                                final String savedDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();
                                final String savedPhone = _selectedPhone ?? _phoneSearchController.text.trim();
                                final String savedName = _selectedName ?? _nameSearchController.text.trim();

                                final bool wetEmpty = savedWet.isEmpty || savedWet == "Select";
                                final bool dryEmpty = savedDry.isEmpty || savedDry == "Select";

                                if ((wetEmpty && dryEmpty) ||
                                    savedPhone.isEmpty || savedPhone == "Select" ||
                                    savedName.isEmpty || savedName == "Select") {
                                  setState(() {
                                    _showValidation = true;
                                  });
                                  return;
                                }

                                final wetValue = int.tryParse(savedWet);
                                final dryValue = int.tryParse(savedDry);

                                if (_assignedStartRFID != null && _assignedEndRFID != null) {
                                  if (wetValue != null && (wetValue < _assignedStartRFID! || wetValue > _assignedEndRFID!)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Wet RFID is outside assigned range"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  if (dryValue != null && (dryValue < _assignedStartRFID! || dryValue > _assignedEndRFID!)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Dry RFID is outside assigned range"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                _showVerificationDialog();
                              } else {
                                _handleSave();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool showError,
    int? maxLines = 1,
    int? minLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D))),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black54, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: showError ? Colors.red.shade400 : Colors.black12, width: showError ? 1.5 : 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: showError ? Colors.red.shade400 : const Color(0xFF00A236), width: 1.5),
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4),
            child: Text("Required", style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildSearchDropdown({
    Key? dropdownKey,
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> items,
    required IconData icon,
    required Function(String?) onSelected,
  }) {
    final bool hasError = _showValidation && (controller.text.trim().isEmpty || controller.text.trim() == "Select");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D))),
        ),
        Autocomplete<String>(
          key: dropdownKey,
          optionsBuilder: (value) {
            List<String> filtered;
            if (value.text.isEmpty) {
              filtered = List.from(items);
            } else {
              filtered = items.where((item) => item.toLowerCase().contains(value.text.toLowerCase())).toList();
            }

            final hasSelect = filtered.contains("Select");
            filtered.remove("Select");
            filtered.sort((a, b) {
              final aNum = int.tryParse(a);
              final bNum = int.tryParse(b);
              if (aNum != null && bNum != null) return aNum.compareTo(bNum);
              return a.compareTo(b);
            });

            if (hasSelect) filtered.insert(0, "Select");
            return filtered;
          },
          onSelected: onSelected,
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  width: MediaQuery.of(context).size.width - 96,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(option, style: const TextStyle(color: Colors.black87)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, textController, autocompleteFocusNode, onEditingComplete) {
            if (textController.text != controller.text) {
              textController.value = TextEditingValue(
                text: controller.text,
                selection: TextSelection.collapsed(offset: controller.text.length),
              );
            }

            // Link Autocomplete's focus chain to our internal FocusNode tracker
            if (focusNode.parent == null) {
              autocompleteFocusNode.addListener(() {
                if (autocompleteFocusNode.hasFocus) {
                  focusNode.requestFocus();
                } else {
                  focusNode.unfocus();
                }
              });
            }

            return TextField(
              controller: textController,
              focusNode: autocompleteFocusNode,
              onChanged: (value) {
                if (label.contains("RFID")) {
                  final entered = int.tryParse(value);

                  if (entered != null && _assignedStartRFID != null && _assignedEndRFID != null) {
                    if (entered < _assignedStartRFID! || entered > _assignedEndRFID!) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "RFID $entered is outside your assigned range (${_assignedStartRFID!}-${_assignedEndRFID!})",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );

                      textController.clear();

                      setState(() {
                        if (label.contains("Wet")) {
                          _selectedWetRFID = null;
                          _wetRfidSearchController.clear();
                        }
                        if (label.contains("Dry")) {
                          _selectedDryRFID = null;
                          _dryRfidSearchController.clear();
                        }
                      });
                    }
                  }
                }
              },
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: Icon(icon, color: Colors.black54, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: hasError ? Colors.red.shade400 : Colors.black12,
                    width: hasError ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: hasError ? Colors.red.shade400 : const Color(0xFF00A236),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4),
            child: Text("Required", style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
}