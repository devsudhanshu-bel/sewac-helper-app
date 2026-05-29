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
  bool _hasPhoto = false;

  XFile? _imageFile;

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

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _loadAllDropdownData();
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
          final List<String> newList = [
            "Select",
            ...rfids.map((item) => item["slno"].toString()),
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
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
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

    final String formattedWet = (savedWet.isEmpty || savedWet == "Select") ? "Not Selected" : savedWet;
    final String formattedDry = (savedDry.isEmpty || savedDry == "Select") ? "Not Selected" : savedDry;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A236).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: Color(0xFF00A236),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Verify Details",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 8),
                _buildVerificationRow("Citizen Name", savedName),
                _buildVerificationRow("Phone Number", savedPhone),
                _buildVerificationRow("Wet RFID", formattedWet),
                _buildVerificationRow("Dry RFID", formattedDry),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

        _clearForm();
        await _loadAllDropdownData();
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
    await prefs.remove("workerId");
    await prefs.remove("worker_id");
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

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SewacHeader(
        onLogout: _handleLogout,
      ),
      body: SewacBackground(
        child: RefreshIndicator(
          color: Colors.green,
          onRefresh: _loadAllDropdownData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "RFID Mapping",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Text(
                  "Sync resident details from the secure database",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _status == "Found"
                      ? Container(
                    key: const ValueKey("found"),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        _buildSearchDropdown(
                          label: "Wet Waste RFID *",
                          hint: "Search Wet RFID",
                          controller: _wetRfidSearchController,
                          items: _wetAvailableRfids,
                          icon: Icons.qr_code,
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
                        const SizedBox(height: 16),
                        _buildSearchDropdown(
                          label: "Dry Waste RFID *",
                          hint: "Search Dry RFID",
                          controller: _dryRfidSearchController,
                          items: _dryAvailableRfids,
                          icon: Icons.qr_code,
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
                        const SizedBox(height: 16),
                        _buildSearchDropdown(
                          label: "Phone Number *",
                          hint: "Search Phone Number",
                          controller: _phoneSearchController,
                          items: _phoneDropdownItems,
                          icon: Icons.phone,
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
                        const SizedBox(height: 16),
                        _buildSearchDropdown(
                          label: "Name *",
                          hint: "Search Name",
                          controller: _nameSearchController,
                          items: _nameDropdownItems,
                          icon: Icons.person,
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
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: "Building No *",
                          hint: "Enter Building Number",
                          controller: _buildingController,
                          icon: Icons.apartment_outlined,
                          showError: _showValidation && _buildingController.text.trim().isEmpty,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: "Floor No *",
                          hint: "Enter Floor Number",
                          controller: _floorController,
                          icon: Icons.unfold_more_outlined,
                          showError: _showValidation && _floorController.text.trim().isEmpty,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: "Remarks *",
                          hint: "Enter Remarks",
                          controller: _remarksController,
                          icon: Icons.notes_outlined,
                          showError: _showRemarksError,
                          maxLines: null,
                          minLines: 2,
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            "Photo *",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D)),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Status Selection",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Found"),
                              value: 'Found',
                              groupValue: _status,
                              activeColor: Colors.green,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                setState(() {
                                  _status = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Not Found"),
                              value: 'Not Found',
                              groupValue: _status,
                              activeColor: Colors.green,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                setState(() {
                                  _status = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SewacButton(
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

                      _showVerificationDialog();
                    } else {
                      _handleSave();
                    }
                  },
                ),
              ],
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D))),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            prefixIcon: Icon(icon, color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: showError ? Colors.red.shade400 : Colors.black12, width: showError ? 1.5 : 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: showError ? Colors.red.shade400 : Colors.green, width: 1.5),
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 4),
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
    required List<String> items,
    required IconData icon,
    required Function(String?) onSelected,
  }) {
    final bool hasError = _showValidation && (controller.text.trim().isEmpty || controller.text.trim() == "Select");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D))),
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
          fieldViewBuilder: (context, textController, focusNode, onEditingComplete) {
            if (textController.text != controller.text) {
              textController.value = TextEditingValue(
                text: controller.text,
                selection: TextSelection.collapsed(offset: controller.text.length),
              );
            }

            return TextField(
              controller: textController,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: Icon(icon, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: hasError ? Colors.red.shade400 : Colors.black12, width: hasError ? 1.5 : 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: hasError ? Colors.red.shade400 : Colors.green, width: 1.5),
                ),
              ),
            );
          },
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 4),
            child: Text("Required", style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
}