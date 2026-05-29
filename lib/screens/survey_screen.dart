import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../widgets/sewac_background.dart';
import '../widgets/sewac_header.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() =>
      _SurveyScreenState();
}

class _SurveyScreenState
    extends State<SurveyScreen> {

  final _formKey =
  GlobalKey<FormState>();

  final _areaController =
  TextEditingController();

  final _buildingController =
  TextEditingController();

  final _floorController =
  TextEditingController();

  final _nameController =
  TextEditingController();

  final _phoneController =
  TextEditingController();

  final _peopleController =
  TextEditingController();

  String? _selectedHH;
  String? _selectedCity;
  String? _selectedWard;

  XFile? _capturedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker =
  ImagePicker();

  final List<String>
  hhTypes = [
    "Owner",
    "Tenant",
  ];

  final Map<String, bool>
  wasteOptions = {
    "Individual HHs": false,
    "MDUs": false,
    "PG": false,
    "Hotel": false,
    "Bakery": false,
    "Super Market": false,
    "Provision Store": false,
    "Apartment": false,
    "Clinic & Hospital": false,
    "Medical Shop": false,
    "Others": false,
  };

  // Autocomplete search controllers for RFID fields (Reused from Dashboard)
  final TextEditingController _wetRfidSearchController = TextEditingController();
  final TextEditingController _dryRfidSearchController = TextEditingController();

  List<String> _rfidDropdownItems = ["Select"];
  String? _selectedWetRFID;
  String? _selectedDryRFID;
  bool _showRfidValidationError = false;

  // Wet available filtering exclusions logic matching DashboardScreen
  List<String> get _wetAvailableRfids {
    return _rfidDropdownItems.where((item) {
      if (item == "Select") return true;
      final currentDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();
      return item != currentDry;
    }).toList();
  }

  // Dry available filtering exclusions logic matching DashboardScreen
  List<String> get _dryAvailableRfids {
    return _rfidDropdownItems.where((item) {
      if (item == "Select") return true;
      final currentWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
      return item != currentWet;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchUnmappedRFIDs();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _peopleController.dispose();
    _wetRfidSearchController.dispose();
    _dryRfidSearchController.dispose();
    super.dispose();
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
          setState(() {
            _rfidDropdownItems = [
              "Select",
              ...rfids.map((item) => item["slno"].toString()),
            ];
          });
        }
      }
    } catch (e) {
      debugPrint("RFID API error: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      setState(() {
        _capturedImage = image;
      });
    }
  }

  void _clearForm() {
    _areaController.clear();
    _buildingController.clear();
    _floorController.clear();
    _nameController.clear();
    _phoneController.clear();
    _peopleController.clear();
    _wetRfidSearchController.clear();
    _dryRfidSearchController.clear();

    _selectedCity = null;
    _selectedWard = null;
    _selectedHH = null;
    _capturedImage = null;

    _selectedWetRFID = null;
    _selectedDryRFID = null;
    _showRfidValidationError = false;

    for (final key in wasteOptions.keys) {
      wasteOptions[key] = false;
    }

    setState(() {});
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Required";
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            menuMaxHeight: 220,
            borderRadius: BorderRadius.circular(14),
            validator: (val) {
              if (val == null) {
                return "Required";
              }
              return null;
            },
            icon: const Icon(Icons.keyboard_arrow_down),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Exact UI build searchable dropdown implementation matching Dashboard style rules
  Widget _buildSearchDropdown({
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> items,
    required IconData icon,
    required Function(String?, TextEditingController) onSelected,
  }) {
    final bool hasCustomError = _showRfidValidationError &&
        (controller.text.trim().isEmpty || controller.text.trim() == "Select");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue value) {
            List<String> filtered;
            if (value.text.isEmpty) {
              filtered = List.from(items);
            } else {
              filtered = items
                  .where((item) => item.toLowerCase().contains(value.text.toLowerCase()))
                  .toList();
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
          optionsViewBuilder: (context, onAutoCompleteSelect, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  width: MediaQuery.of(context).size.width - 80,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(option, style: const TextStyle(color: Colors.black87)),
                        onTap: () => onAutoCompleteSelect(option),
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
              onChanged: (val) {
                controller.text = val;
                setState(() {});
              },
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: Icon(icon, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: hasCustomError ? Colors.red.shade400 : Colors.grey.shade400,
                    width: hasCustomError ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: hasCustomError ? Colors.red.shade400 : Colors.green,
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
          onSelected: (val) {
            onSelected(val, controller);
          },
        ),
        if (hasCustomError)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 4),
            child: Text("Required", style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _submitSurvey() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String savedWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
    final String savedDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();

    final bool wetEmpty = savedWet.isEmpty || savedWet == "Select";
    final bool dryEmpty = savedDry.isEmpty || savedDry == "Select";

    if (wetEmpty && dryEmpty) {
      setState(() {
        _showRfidValidationError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please map at least one Wet or Dry RFID tag"),
        ),
      );
      return;
    } else {
      setState(() {
        _showRfidValidationError = false;
      });
    }

    final hasWasteSelected = wasteOptions.values.any((value) => value);
    if (!hasWasteSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select waste generator type")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final selectedWasteTypes = wasteOptions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join(", ");

    final phoneNumberEnteredInSurvey = _phoneController.text.trim();

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/survey/create"),
      );

      request.fields["city"] = _selectedCity ?? "";
      request.fields["ward"] = _selectedWard ?? "";
      request.fields["area"] = _areaController.text.trim();
      request.fields["wasteGeneratorTypes"] = selectedWasteTypes;
      request.fields["houseNumber"] = _buildingController.text.trim();
      request.fields["floorNumber"] = _floorController.text.trim();
      request.fields["householdType"] = _selectedHH ?? "";
      request.fields["personName"] = _nameController.text.trim();
      request.fields["contactNumber"] = phoneNumberEnteredInSurvey;
      request.fields["numberOfPeople"] = _peopleController.text.trim();

      if (_capturedImage != null) {
        final bytes = await _capturedImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "buildingPhoto",
            bytes,
            filename: _capturedImage!.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("auth_token") ?? "";
        final headers = {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        };

        if (!wetEmpty) {
          final wetMapResponse = await http.patch(
            Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/rfid/map"),
            headers: headers,
            body: jsonEncode({
              "slno": savedWet,
              "phoneNumber": phoneNumberEnteredInSurvey,
              "wasteType": "WET"
            }),
          );

          if (wetMapResponse.statusCode < 200 || wetMapResponse.statusCode >= 300) {
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
            setState(() {
              _isSubmitting = false;
            });
            return;
          }
        }

        if (!dryEmpty) {
          final dryMapResponse = await http.patch(
            Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/rfid/map"),
            headers: headers,
            body: jsonEncode({
              "slno": savedDry,
              "phoneNumber": phoneNumberEnteredInSurvey,
              "wasteType": "DRY"
            }),
          );

          if (dryMapResponse.statusCode < 200 || dryMapResponse.statusCode >= 300) {
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
            setState(() {
              _isSubmitting = false;
            });
            return;
          }
        }

        _clearForm();
        await _fetchUnmappedRFIDs();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF4CAF50),
            content: Text("Survey submitted and RFIDs mapped successfully"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit survey")),
        );
      }
    } on http.ClientException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed due to internet connection")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit survey")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
      print("LOGOUT ERROR => $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("isLoggedIn");

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Survey",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: "Select City *",
                        value: _selectedCity,
                        items: const [
                          "Bangalore",
                          "Mysore",
                          "Mangalore",
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                      _buildDropdown(
                        label: "Select Ward *",
                        value: _selectedWard,
                        items: const [
                          "Ward 174",
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedWard = value;
                          });
                        },
                      ),
                      _buildInput(
                        label: "Area / Main / Cross Road *",
                        controller: _areaController,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Type of Waste Generators *",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...wasteOptions.keys.map((key) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: const Color(0xFF4CAF50),
                          value: wasteOptions[key],
                          title: Text(key),
                          onChanged: (value) {
                            setState(() {
                              wasteOptions[key] = value!;
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      _buildInput(
                        label: "House / Building Number *",
                        controller: _buildingController,
                      ),
                      _buildInput(
                        label: "Floor of Building *",
                        controller: _floorController,
                      ),
                      _buildDropdown(
                        label: "Type of HHs *",
                        value: _selectedHH,
                        items: hhTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedHH = value;
                          });
                        },
                      ),
                      _buildInput(
                        label: "Name of Person *",
                        controller: _nameController,
                      ),
                      _buildInput(
                        label: "Contact Number *",
                        controller: _phoneController,
                      ),

                      // Search drop-down text controller inputs with clean Select reset mappings
                      _buildSearchDropdown(
                        label: "Wet Waste RFID *",
                        hint: "Search Wet RFID",
                        controller: _wetRfidSearchController,
                        items: _wetAvailableRfids,
                        icon: Icons.qr_code_scanner,
                        onSelected: (val, currentController) {
                          setState(() {
                            if (val == "Select") {
                              _selectedWetRFID = null;
                              currentController.clear();
                              _wetRfidSearchController.clear();
                              FocusScope.of(context).unfocus();
                            } else {
                              _selectedWetRFID = val;
                              currentController.text = val ?? "";
                              _wetRfidSearchController.text = val ?? "";
                            }
                          });
                        },
                      ),
                      _buildSearchDropdown(
                        label: "Dry Waste RFID *",
                        hint: "Search Dry RFID",
                        controller: _dryRfidSearchController,
                        items: _dryAvailableRfids,
                        icon: Icons.qr_code_scanner,
                        onSelected: (val, currentController) {
                          setState(() {
                            if (val == "Select") {
                              _selectedDryRFID = null;
                              currentController.clear();
                              _dryRfidSearchController.clear();
                              FocusScope.of(context).unfocus();
                            } else {
                              _selectedDryRFID = val;
                              currentController.text = val ?? "";
                              _dryRfidSearchController.text = val ?? "";
                            }
                          });
                        },
                      ),
                      _buildInput(
                        label: "No of People *",
                        controller: _peopleController,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Photo of Building",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 110,
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: _capturedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(_capturedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Icon(
                            Icons.add_a_photo_rounded,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
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
                            onPressed: _isSubmitting ? null : _submitSurvey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              "SUBMIT",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}