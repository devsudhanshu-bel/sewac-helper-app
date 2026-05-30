import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../widgets/sewac_background.dart';
import '../widgets/sewac_header.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _areaController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _peopleController = TextEditingController();

  String? _selectedHH;
  String? _selectedCity;
  String? _selectedWard;

  XFile? _capturedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> hhTypes = [
    "Owner",
    "Tenant",
  ];

  final Map<String, bool> wasteOptions = {
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

  // Autocomplete search controllers for RFID fields
  final TextEditingController _wetRfidSearchController = TextEditingController();
  final TextEditingController _dryRfidSearchController = TextEditingController();

  List<String> _rfidDropdownItems = ["Select"];
  String? _selectedWetRFID;
  String? _selectedDryRFID;
  bool _showRfidValidationError = false;

  // Wet available filtering exclusions logic
  List<String> get _wetAvailableRfids {
    return _rfidDropdownItems.where((item) {
      if (item == "Select") return true;
      final currentDry = (_selectedDryRFID != null && _selectedDryRFID != "Select")
          ? _selectedDryRFID!
          : _dryRfidSearchController.text.trim();
      return item != currentDry;
    }).toList();
  }

  // Dry available filtering exclusions logic
  List<String> get _dryAvailableRfids {
    return _rfidDropdownItems.where((item) {
      if (item == "Select") return true;
      final currentWet = (_selectedWetRFID != null && _selectedWetRFID != "Select")
          ? _selectedWetRFID!
          : _wetRfidSearchController.text.trim();
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
    final String savedPhone = _phoneController.text.trim();
    final String savedName = _nameController.text.trim();

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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: Colors.green,
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
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
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
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _handleSurveySubmissionExecution();
                        },
                        child: const Center(
                          child: Text(
                            "CONFIRM",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        );
      },
    );
  }

  void _handleSubmitClick() {
    if (_isSubmitting) {
      return;
    }

    final bool isFormValid = _formKey.currentState!.validate();

    final String savedWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
    final String savedDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();

    final bool wetEmpty = savedWet.isEmpty || savedWet == "Select";
    final bool dryEmpty = savedDry.isEmpty || savedDry == "Select";

    if (wetEmpty && dryEmpty) {
      setState(() {
        _showRfidValidationError = true;
      });
    } else {
      setState(() {
        _showRfidValidationError = false;
      });
    }

    if (!isFormValid || (wetEmpty && dryEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required parameters accurately"),
        ),
      );
      return;
    }

    final hasWasteSelected = wasteOptions.values.any((value) => value);
    if (!hasWasteSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select waste generator type")),
      );
      return;
    }

    _showVerificationDialog();
  }

  Future<void> _handleSurveySubmissionExecution() async {
    setState(() {
      _isSubmitting = true;
    });

    final String savedWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
    final String savedDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();
    final bool wetEmpty = savedWet.isEmpty || savedWet == "Select";
    final bool dryEmpty = savedDry.isEmpty || savedDry == "Select";

    final selectedWasteTypes = wasteOptions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join(", ");

    final phoneNumberEnteredInSurvey = _phoneController.text.trim();
    final citizenNameEnteredInSurvey = _nameController.text.trim();

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
      request.fields["personName"] = citizenNameEnteredInSurvey;
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

        String workerId = "";
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payloadJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            final payloadMap = jsonDecode(payloadJson);
            workerId = payloadMap["id"]?.toString() ?? "";
          }
        } catch (e) {
          debugPrint("Error parsing token: $e");
        }

        final trackingPayload = {
          "slno": wetEmpty ? "N/A" : savedWet,
          "phoneNumber": phoneNumberEnteredInSurvey,
          "citizenName": citizenNameEnteredInSurvey,
          "workerId": workerId.trim(),
          "drySlno": dryEmpty ? "N/A" : savedDry,
          "wetSlno": wetEmpty ? "N/A" : savedWet,
          "status": "FOUND",
        };

        print("TRACKING PAYLOAD =>");
        print(trackingPayload);

        final trackingResponse = await http.post(
          Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/tracking/create"),
          headers: headers,
          body: jsonEncode(trackingPayload),
        );

        print("TRACKING STATUS => ${trackingResponse.statusCode}");
        print("TRACKING BODY => ${trackingResponse.body}");

        if (trackingResponse.statusCode < 200 || trackingResponse.statusCode >= 300) {
          try {
            final errorJson = jsonDecode(trackingResponse.body);
            final serverMsg = errorJson["message"] ??
                errorJson["error"] ??
                "Tracking log creation failed";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(serverMsg), backgroundColor: Colors.red),
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tracking log creation failed"), backgroundColor: Colors.red),
            );
          }
          setState(() {
            _isSubmitting = false;
          });
          return;
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return "Required";
            }
            return null;
          },
          style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.black54, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.04)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF00A236), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
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
            borderRadius: BorderRadius.circular(18),
            validator: (val) {
              if (val == null) {
                return "Required";
              }
              return null;
            },
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(prefixIcon, color: Colors.black54, size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.04)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF00A236), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontWeight: FontWeight.normal)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

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
            fontSize: 14,
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
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  width: MediaQuery.of(context).size.width - 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 13)),
                          onTap: () => onAutoCompleteSelect(option),
                        );
                      },
                    ),
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
              style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
              onChanged: (val) {
                controller.text = val;

                // Keep selected model data updated inline with input changes
                if (controller == _wetRfidSearchController) {
                  _selectedWetRFID = (val.trim().isEmpty || val.trim() == "Select") ? null : val.trim();
                } else if (controller == _dryRfidSearchController) {
                  _selectedDryRFID = (val.trim().isEmpty || val.trim() == "Select") ? null : val.trim();
                }

                if (val.trim().isNotEmpty && val.trim() != "Select") {
                  if (_showRfidValidationError) {
                    setState(() {
                      _showRfidValidationError = false;
                    });
                  }
                } else {
                  setState(() {});
                }
              },
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: Icon(icon, color: Colors.black54, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: hasCustomError ? Colors.red.shade400 : Colors.black.withOpacity(0.04),
                    width: hasCustomError ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: hasCustomError ? Colors.red.shade400 : const Color(0xFF00A236),
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
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text("Required", style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
          ),
        const SizedBox(height: 18),
      ],
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Survey Form",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    "Capture household and generator specifications",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black.withOpacity(0.03)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: "Select City *",
                        value: _selectedCity,
                        prefixIcon: Icons.location_city_outlined,
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
                        prefixIcon: Icons.map_outlined,
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
                        prefixIcon: Icons.add_location_alt_outlined,
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Type of Waste Generators *",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12.withOpacity(0.04)),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wasteOptions.keys.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12, indent: 14, endIndent: 14),
                          itemBuilder: (context, index) {
                            final key = wasteOptions.keys.elementAt(index);
                            return CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                              dense: true,
                              activeColor: const Color(0xFF00A236),
                              checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              value: wasteOptions[key],
                              title: Text(key, style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500)),
                              onChanged: (value) {
                                setState(() {
                                  wasteOptions[key] = value!;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInput(
                        label: "House / Building Number *",
                        controller: _buildingController,
                        prefixIcon: Icons.holiday_village_outlined,
                      ),
                      _buildInput(
                        label: "Floor of Building *",
                        controller: _floorController,
                        prefixIcon: Icons.layers_outlined,
                      ),
                      _buildDropdown(
                        label: "Type of HHs *",
                        value: _selectedHH,
                        prefixIcon: Icons.supervised_user_circle_outlined,
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
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z ]'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Required";
                          }

                          if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value.trim())) {
                            return "Only alphabets allowed";
                          }

                          return null;
                        },
                      ),
                      _buildInput(
                        label: "Contact Number *",
                        controller: _phoneController,
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Required";
                          }

                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                            return "Enter exactly 10 digits";
                          }

                          return null;
                        },
                      ),
                      _buildSearchDropdown(
                        label: "Wet Waste RFID *",
                        hint: "Search Wet RFID",
                        controller: _wetRfidSearchController,
                        items: _wetAvailableRfids,
                        icon: Icons.qr_code_scanner_rounded,
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
                            _showRfidValidationError = false;
                          });
                        },
                      ),
                      _buildSearchDropdown(
                        label: "Dry Waste RFID *",
                        hint: "Search Dry RFID",
                        controller: _dryRfidSearchController,
                        items: _dryAvailableRfids,
                        icon: Icons.qr_code_scanner_rounded,
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
                            _showRfidValidationError = false;
                          });
                        },
                      ),
                      _buildInput(
                        label: "No of People *",
                        controller: _peopleController,
                        prefixIcon: Icons.groups_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Photo of Building",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.black12,
                            ),
                          ),
                          child: _capturedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.file(
                              File(_capturedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Icon(
                            Icons.add_a_photo_rounded,
                            size: 36,
                            color: Color(0xFF00A236),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFA000),
                                Color(0xFF4CAF50),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleSubmitClick,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
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
                              "SUBMIT SURVEY",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}