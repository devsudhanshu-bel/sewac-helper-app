import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'main_navigation_screen.dart';

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

  // Dialog drop-down text controllers for search
  final _citySearchController = TextEditingController();
  final _wardSearchController = TextEditingController();

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

  final TextEditingController _wetRfidSearchController = TextEditingController();
  final TextEditingController _dryRfidSearchController = TextEditingController();

  List<String> _rfidDropdownItems = ["Select"];
  String? _selectedWetRFID;
  String? _selectedDryRFID;
  bool _showRfidValidationError = false;

  int? _assignedStartRFID;
  int? _assignedEndRFID;

  // Constants mock lists for autocomplete
  final List<String> _citiesList = ["Bangalore", "Mysore", "Mangalore"];
  final List<String> _wardsList = ["Ward 174"];

  List<String> get _wetAvailableRfids {
    return _rfidDropdownItems.where((item) {
      if (item == "Select") return true;
      final currentDry = (_selectedDryRFID != null && _selectedDryRFID != "Select")
          ? _selectedDryRFID!
          : _dryRfidSearchController.text.trim();
      return item != currentDry;
    }).toList();
  }

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

    _loadRFIDRange().then((_) async {
      await _fetchUnmappedRFIDs();

      await _loadSurveyDetails();

      _loadLocationAndCheckPopups();
    });
  }

  Future<void> _loadRFIDRange() async {
    final prefs = await SharedPreferences.getInstance();

    final workerId =
        prefs.getString("workerId") ??
            prefs.getString("worker_id") ??
            prefs.getString("username") ??
            "";

    setState(() {
      _assignedStartRFID =
          prefs.getInt("assignedStartRFID_$workerId");
      _assignedEndRFID =
          prefs.getInt("assignedEndRFID_$workerId");
    });
  }

  Future<void> _saveSurveyDetails() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "survey_area",
      _areaController.text.trim(),
    );

    if (_capturedImage != null) {
      await prefs.setString(
        "survey_building_photo_path",
        _capturedImage!.path,
      );
    }
  }

  Future<void> _loadSurveyDetails() async {
    final prefs = await SharedPreferences.getInstance();

    final area = prefs.getString("survey_area");
    final photoPath = prefs.getString("survey_building_photo_path");

    if (area != null) {
      _areaController.text = area;
    }

    if (photoPath != null && File(photoPath).existsSync()) {
      _capturedImage = XFile(photoPath);
    }
  }

  Future<void> _loadLocationAndCheckPopups() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString("survey_city");
    final savedWard = prefs.getString("survey_ward");

    if (savedCity != null && savedWard != null) {
      setState(() {
        _selectedCity = savedCity;
        _selectedWard = savedWard;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_selectedCity == null || _selectedWard == null) {
        _showLocationPopup(isMandatory: true);
      } else if (_areaController.text.trim().isEmpty || _capturedImage == null) {
        _showSurveyDetailsPopup(isMandatory: true);
      }
    });
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
    _citySearchController.dispose();
    _wardSearchController.dispose();
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
            final filteredRFIDs = rfids.where((item) {
              final value = int.tryParse(item["slno"].toString());

              if (value == null) return false;
              if (_assignedStartRFID == null) return false;
              if (_assignedEndRFID == null) return false;

              return value >= _assignedStartRFID! &&
                  value <= _assignedEndRFID!;
            }).toList();

            _rfidDropdownItems = [
              "Select",
              ...filteredRFIDs.map((item) => item["slno"].toString()),
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
    _buildingController.clear();
    _floorController.clear();
    _nameController.clear();
    _phoneController.clear();
    _peopleController.clear();
    _wetRfidSearchController.clear();
    _dryRfidSearchController.clear();

    _selectedHH = null;
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupSearchDropdown({
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> items,
    required IconData icon,
    required Function(String) onSelected,
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
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) {
              return items;
            }
            return items.where((item) => item.toLowerCase().contains(value.text.toLowerCase()));
          },
          optionsViewBuilder: (context, onAutoCompleteSelect, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  width: MediaQuery.of(context).size.width * 0.68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                          title: Text(option, style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14)),
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
              textController.text = controller.text;
            }
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Required";
                }
                return null;
              },
              style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
              onChanged: (val) {
                controller.text = val;
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: Icon(icon, color: Colors.black54, size: 20),
                suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
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
            );
          },
          onSelected: (val) {
            controller.text = val;
            onSelected(val);
          },
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  void _showLocationPopup({required bool isMandatory}) {
    final popupFormKey = GlobalKey<FormState>();

    _citySearchController.text = _selectedCity ?? "";
    _wardSearchController.text = _selectedWard ?? "";

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
            backgroundColor: Colors.white,
            title: const Text(
              "Survey Location",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            content: Form(
              key: popupFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPopupSearchDropdown(
                      label: "City *",
                      hint: "Search or select city",
                      controller: _citySearchController,
                      items: _citiesList,
                      icon: Icons.location_city_outlined,
                      onSelected: (_) {},
                    ),
                    _buildPopupSearchDropdown(
                      label: "Ward *",
                      hint: "Search or select ward",
                      controller: _wardSearchController,
                      items: _wardsList,
                      icon: Icons.map_outlined,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 52,
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
                    onPressed: () async {
                      if (popupFormKey.currentState!.validate()) {
                        final cityVal = _citySearchController.text.trim();
                        final wardVal = _wardSearchController.text.trim();

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString("survey_city", cityVal);
                        await prefs.setString("survey_ward", wardVal);

                        setState(() {
                          _selectedCity = cityVal;
                          _selectedWard = wardVal;
                        });
                        Navigator.of(context).pop();

                        // Immediately show the Survey Details popup
                        _showSurveyDetailsPopup(isMandatory: isMandatory);
                      }
                    },
                    child: const Text(
                      "OKAY",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSurveyDetailsPopup({required bool isMandatory}) {
    final detailsFormKey = GlobalKey<FormState>();
    bool showPhotoError = false;

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setPopupState) {
            return PopScope(
              canPop: !isMandatory,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
                backgroundColor: Colors.white,
                title: const Text(
                  "Survey Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                content: Form(
                  key: detailsFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Area / Main / Cross Road *",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _areaController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Required";
                            }
                            return null;
                          },
                          style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.add_location_alt_outlined, color: Colors.black54, size: 20),
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
                        const Text(
                          "Building Photo *",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                            if (image != null) {
                              _capturedImage = image;
                              setPopupState(() {});
                            }
                          },
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: showPhotoError ? Colors.red.shade400 : Colors.black12,
                                width: showPhotoError ? 1.5 : 1.0,
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
                        if (showPhotoError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              "Photo is required",
                              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  Theme(
                    data: ThemeData(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
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
                          onPressed: () async {
                            final isFormValid = detailsFormKey.currentState!.validate();
                            final isPhotoValid = _capturedImage != null;

                            if (!isPhotoValid) {
                              setPopupState(() {
                                showPhotoError = true;
                              });
                            } else {
                              setPopupState(() {
                                showPhotoError = false;
                              });
                            }

                            if (isFormValid && isPhotoValid) {
                              await _saveSurveyDetails();

                              setState(() {});
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text(
                            "CONTINUE",
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVerificationDialog() {
    final String savedWet = _selectedWetRFID ?? _wetRfidSearchController.text.trim();
    final String savedDry = _selectedDryRFID ?? _dryRfidSearchController.text.trim();
    final String savedPhone = _phoneController.text.trim();
    final String savedName = _nameController.text.trim();

    final String formattedWet = (savedWet.isEmpty || savedWet == "Select") ? "Not Selected" : savedWet;
    final String formattedDry = (savedDry.isEmpty || savedDry == "Select") ? "Not Selected" : savedDry;

    final bool hasWet = formattedWet != "Not Selected";
    final bool hasDry = formattedDry != "Not Selected";

    final verifyFormKey = GlobalKey<FormState>();
    final reenterWetController = TextEditingController();
    final reenterDryController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
                backgroundColor: Colors.white,
                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                content: Form(
                  key: verifyFormKey,
                  child: SingleChildScrollView(
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
                        _buildVerificationRow("City", _selectedCity ?? "N/A"),
                        _buildVerificationRow("Ward", _selectedWard ?? "N/A"),
                        _buildVerificationRow("Area / Main / Cross Road", _areaController.text.trim()),
                        _buildVerificationRow("Citizen Name", savedName),
                        _buildVerificationRow("Phone Number", savedPhone),
                        const SizedBox(height: 8),

                        const Text(
                          "Building Photo",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),

                        const SizedBox(height: 6),

                        if (_capturedImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_capturedImage!.path),
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),

                        const SizedBox(height: 8),
                        _buildVerificationRow("Wet RFID", formattedWet),
                        _buildVerificationRow("Dry RFID", formattedDry),
                        const SizedBox(height: 12),
                        if (hasWet) ...[
                          const Text(
                            "Re-enter Wet RFID *",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: reenterWetController,
                            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A236), width: 1.5)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Required";
                              if (val.trim() != savedWet) return "RFID mismatch. Please verify.";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (hasDry) ...[
                          const Text(
                            "Re-enter Dry RFID *",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: reenterDryController,
                            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A236), width: 1.5)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Required";
                              if (val.trim() != savedDry) return "RFID mismatch. Please verify.";
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
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
                            onPressed: () async {
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
                                if (verifyFormKey.currentState!.validate()) {
                                  Navigator.of(context).pop();
                                  _handleSurveySubmissionExecution();
                                }
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
            }
        );
      },
    );
  }

  void _showContinueSurveyPopup() {
    bool keepArea = true;
    bool keepBuildingPhoto = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setPopupState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.0),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                "Continue Survey?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVerificationRow("City", _selectedCity ?? "N/A"),
                    _buildVerificationRow("Ward", _selectedWard ?? "N/A"),
                    _buildVerificationRow("Area / Main / Cross Road", _areaController.text.trim()),
                    const SizedBox(height: 6),
                    const Text(
                      "Building Photo Preview",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_capturedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_capturedImage!.path),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Text(
                        "No image selected",
                        style: TextStyle(fontSize: 14, color: Colors.black45, fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text(
                        "Keep Area",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                      ),
                      value: keepArea,
                      activeColor: const Color(0xFF4CAF50),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? val) {
                        setPopupState(() {
                          keepArea = val ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        "Keep Building Photo",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                      ),
                      value: keepBuildingPhoto,
                      activeColor: const Color(0xFF4CAF50),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? val) {
                        setPopupState(() {
                          keepBuildingPhoto = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();

                            final prefs = await SharedPreferences.getInstance();

                            await prefs.remove("survey_area");
                            await prefs.remove("survey_building_photo_path");

                            _areaController.clear();
                            _capturedImage = null;

                            setState(() {});

                            // Go to Dashboard (Home)
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const MainNavigationScreen(),
                              ),
                                  (route) => false,
                            );
                          },
                          child: const Text(
                            "EXIT",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
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
                            onPressed: () async {
                              // ALWAYS keep: City, Ward
                              // ALWAYS clear: Name, Phone, HH Type, Waste Generator selection, RFID values, Number of People, Building Number, Floor Number.
                              // This is already done inside `_clearForm()` or right before this dialog was invoked,
                              // but to ensure strict adherence, variables are updated precisely as requested:

                              Navigator.of(context).pop();

                              if (keepArea && keepBuildingPhoto) {
                                // CASE 1: Keep Area and Building Photo. Return to form immediately.
                                setState(() {});
                              } else if (keepArea && !keepBuildingPhoto) {
                                // CASE 2: Keep Area, Clear Building Photo. Request only photo selection via details popup
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove("survey_building_photo_path");
                                _capturedImage = null;
                                setState(() {});

                                // Show Survey Details popup using StatefulBuilder to prompt photo selection
                                final detailsFormKey = GlobalKey<FormState>();
                                bool showPhotoError = false;

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                      builder: (BuildContext context, StateSetter setPhotoPopupState) {
                                        return PopScope(
                                          canPop: false,
                                          child: AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(28.0),
                                            ),
                                            backgroundColor: Colors.white,
                                            title: const Text(
                                              "Survey Details",
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2C3E50),
                                              ),
                                            ),
                                            content: Form(
                                              key: detailsFormKey,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Building Photo *",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      await _pickImage();
                                                      setPhotoPopupState(() {});
                                                    },
                                                    child: Container(
                                                      height: 120,
                                                      width: 120,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF8F9FA),
                                                        borderRadius: BorderRadius.circular(24),
                                                        border: Border.all(
                                                          color: showPhotoError ? Colors.red.shade400 : Colors.black12,
                                                          width: showPhotoError ? 1.5 : 1.0,
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
                                                  if (showPhotoError)
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 12, top: 4),
                                                      child: Text(
                                                        "Photo is required",
                                                        style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            actions: [
                                              SizedBox(
                                                width: double.infinity,
                                                height: 52,
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
                                                    onPressed: () async {
                                                      final isPhotoValid = _capturedImage != null;

                                                      if (!isPhotoValid) {
                                                        setPhotoPopupState(() {
                                                          showPhotoError = true;
                                                        });
                                                      } else {
                                                        setPhotoPopupState(() {
                                                          showPhotoError = false;
                                                        });
                                                        await _saveSurveyDetails();
                                                        setState(() {});
                                                        Navigator.of(context).pop();
                                                      }
                                                    },
                                                    child: const Text(
                                                      "CONTINUE",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              } else {
                                // CASE 3: Keep Area = FALSE
                                _areaController.clear();
                                _capturedImage = null;
                                setState(() {});
                                _showSurveyDetailsPopup(isMandatory: true);
                              }
                            },
                            child: const Text(
                              "CONTINUE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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

        final trackingResponse = await http.post(
          Uri.parse("https://sewac-helper-backend.up.railway.app/api/v1/tracking/create"),
          headers: headers,
          body: jsonEncode(trackingPayload),
        );

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

        // Success prompt triggered here cleanly
        _showContinueSurveyPopup();
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
    await prefs.remove("survey_city");
    await prefs.remove("survey_ward");
    await prefs.remove("survey_area");
    await prefs.remove("survey_building_photo_path");
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

    final bool isLocationSelected = _selectedCity != null && _selectedWard != null;

    final String locationSubtitle = isLocationSelected
        ? "$_selectedCity • $_selectedWard"
        : "Please select City and Ward";

    final String areaValue = _areaController.text.trim();
    final bool hasSurveyDetails = areaValue.isNotEmpty && _capturedImage != null;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Survey Form",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          locationSubtitle,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (isLocationSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: TextButton.icon(
                        onPressed: () => _showLocationPopup(isMandatory: false),
                        icon: const Icon(Icons.edit_location_alt_outlined, size: 16, color: Color(0xFF00A236)),
                        label: const Text(
                          "Change",
                          style: TextStyle(
                            color: Color(0xFF00A236),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: const Color(0xFF00A236).withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasSurveyDetails) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.03)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Survey Details Summary",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Area: $areaValue",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Text(
                                  "Building Photo: ",
                                  style: TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                Text(
                                  "Captured ✓",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00A236),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showSurveyDetailsPopup(isMandatory: false),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFFFA000)),
                        label: const Text(
                          "EDIT",
                          style: TextStyle(
                            color: Color(0xFFFFA000),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: const Color(0xFFFFA000).withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Contact Number *",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
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
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,

                              prefixIcon: Container(
                                width: 65,
                                alignment: Alignment.center,
                                child: const Text(
                                  "+91",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),

                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.04),
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00A236),
                                  width: 1.5,
                                ),
                              ),

                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.red.shade400,
                                  width: 1.0,
                                ),
                              ),

                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.red.shade400,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
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