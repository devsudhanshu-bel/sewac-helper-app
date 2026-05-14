import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../widgets/sewac_background.dart';

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

  File? _capturedImage;

  final ImagePicker _picker =
  ImagePicker();

  final List<String>
  hhTypes = [

    "Owner",
    "Tenant",
  ];

  final Map<String, bool>
  wasteOptions = {

    "Individual HHs":
    false,

    "MDUs":
    false,

    "PG":
    false,

    "Hotel":
    false,

    "Bakery":
    false,

    "Super Market":
    false,

    "Provision Store":
    false,

    "Apartment":
    false,

    "Clinic & Hospital":
    false,

    "Medical Shop":
    false,

    "Others":
    false,
  };

  Future<void>
  _pickImage() async {

    final XFile? image =
    await _picker.pickImage(

      source:
      ImageSource.camera,
    );

    if (image != null) {

      setState(() {

        _capturedImage =
            File(
                image.path);
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

    _selectedCity = null;
    _selectedWard = null;
    _selectedHH = null;

    _capturedImage = null;

    for (final key in wasteOptions.keys) {
      wasteOptions[key] = false;
    }

    setState(() {});
  }

  Widget _buildInput({

    required String label,

    required TextEditingController
    controller,
  }) {

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment
          .start,

      children: [

        Text(

          label,

          style:
          const TextStyle(

            fontSize:
            15,

            fontWeight:
            FontWeight.w700,

            color:
            Color(
                0xFF2C3E50),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        TextFormField(

          controller:
          controller,

          validator:
              (
              value,
              ) {

            if (value == null ||
                value
                    .trim()
                    .isEmpty) {

              return "Required";
            }

            return null;
          },

          decoration:
          InputDecoration(

            filled:
            true,

            fillColor:
            Colors.white,

            contentPadding:
            const EdgeInsets.symmetric(

              horizontal:
              16,

              vertical:
              16,
            ),

            border:
            OutlineInputBorder(

              borderRadius:
              BorderRadius.circular(
                  14),
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget _buildDropdown({

    required String label,

    required String? value,

    required List<String>
    items,

    required Function(
        String?)
    onChanged,
  }) {

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment
          .start,

      children: [

        Text(

          label,

          style:
          const TextStyle(

            fontSize:
            15,

            fontWeight:
            FontWeight.w700,

            color:
            Color(
                0xFF2C3E50),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Material(

          color: Colors.transparent,

          child:
          DropdownButtonFormField<String>(

            value:
            value,

            isExpanded:
            true,

            menuMaxHeight:
            220,

            borderRadius:
            BorderRadius.circular(
                14),

            validator:
                (
                value,
                ) {

              if (value == null) {
                return "Required";
              }

              return null;
            },

            icon:
            const Icon(
              Icons.keyboard_arrow_down,
            ),

            decoration:
            InputDecoration(

              contentPadding:
              const EdgeInsets.symmetric(

                horizontal:
                16,

                vertical:
                16,
              ),

              filled:
              true,

              fillColor:
              Colors.white,

              border:
              OutlineInputBorder(

                borderRadius:
                BorderRadius.circular(
                    14),
              ),
            ),

            items:
            items.map(
                  (
                  item,
                  ) {

                return DropdownMenuItem(

                  value:
                  item,

                  child:
                  Text(
                      item),
                );
              },
            ).toList(),

            onChanged:
            onChanged,
          ),
        ),

        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Future<void> _submitSurvey() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Waste type validation
    final hasWasteSelected =
    wasteOptions.values.any((value) => value);

    if (!hasWasteSelected) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select waste generator type",
          ),
        ),
      );

      return;
    }

    // Selected waste types
    final selectedWasteTypes =
    wasteOptions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join(", ");

    try {

      // Multipart request instead of JSON
      var request =
      http.MultipartRequest(
        "POST",

        Uri.parse(
          "https://sewac-helper-app.onrender.com/api/v1/survey/create",
        ),
      );

      // Normal form fields
      request.fields["city"] =
          _selectedCity ?? "";

      request.fields["ward"] =
          _selectedWard ?? "";

      request.fields["area"] =
          _areaController.text.trim();

      request.fields[
      "wasteGeneratorTypes"] =
          selectedWasteTypes;

      request.fields[
      "houseNumber"] =
          _buildingController.text.trim();

      request.fields[
      "floorNumber"] =
          _floorController.text.trim();

      request.fields[
      "householdType"] =
          _selectedHH ?? "";

      request.fields[
      "personName"] =
          _nameController.text.trim();

      request.fields[
      "contactNumber"] =
          _phoneController.text.trim();

      request.fields[
      "numberOfPeople"] =
          _peopleController.text.trim();

      // Image upload
      if (_capturedImage != null) {

        request.files.add(

          await http.MultipartFile.fromPath(

            "buildingPhoto", // backend field name

            _capturedImage!.path,
          ),
        );
      }

      // Send request
      final streamedResponse =
      await request.send();

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        _clearForm();

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            backgroundColor:
            Color(0xFF4CAF50),

            content: Text(
              "Survey submitted successfully",
            ),
          ),
        );

      } else {

        print(response.body);

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Failed to submit survey",
            ),
          ),
        );
      }

    }

    on http.ClientException {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Failed due to internet connection",
          ),
        ),
      );
    }

    catch (e) {

      print(e);

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Failed to submit survey",
          ),
        ),
      );
    }
  }
  @override
  Widget build(
      BuildContext context) {

    // KEEP YOUR EXISTING UI BELOW EXACTLY SAME
    // (No UI changes made)

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF8F9FA),

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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
        ],
      ),

      body: SewacBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            4,
            20,
            16,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const Text(
                "Survey",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(
                  height: 24),

              Form(
                key: _formKey,

                child: Container(
                  padding:
                  const EdgeInsets.all(
                      20),

                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,

                    borderRadius:
                    BorderRadius.circular(
                        24),
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
                        label:
                        "Area / Main / Cross Road *",
                        controller:
                        _areaController,
                      ),

                      const Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Text(
                          "Type of Waste Generators *",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      ...wasteOptions.keys.map((key) {
                        return CheckboxListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          dense: true,
                          activeColor:
                          const Color(
                              0xFF4CAF50),
                          value:
                          wasteOptions[key],
                          title:
                          Text(key),
                          onChanged:
                              (value) {
                            setState(() {
                              wasteOptions[key] =
                              value!;
                            });
                          },
                        );
                      }),

                      const SizedBox(
                          height: 12),

                      _buildInput(
                        label:
                        "House / Building Number *",
                        controller:
                        _buildingController,
                      ),

                      _buildInput(
                        label:
                        "Floor of Building *",
                        controller:
                        _floorController,
                      ),

                      _buildDropdown(
                        label:
                        "Type of HHs *",
                        value:
                        _selectedHH,
                        items:
                        hhTypes,
                        onChanged:
                            (value) {
                          setState(() {
                            _selectedHH =
                                value;
                          });
                        },
                      ),

                      _buildInput(
                        label:
                        "Name of Person *",
                        controller:
                        _nameController,
                      ),

                      _buildInput(
                        label:
                        "Contact Number *",
                        controller:
                        _phoneController,
                      ),

                      _buildInput(
                        label:
                        "No of People *",
                        controller:
                        _peopleController,
                      ),

                      const Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Text(
                          "Photo of Building *",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      GestureDetector(
                        onTap:
                        _pickImage,

                        child:
                        Container(
                          height: 110,
                          width: 110,

                          decoration:
                          BoxDecoration(
                            color: Colors
                                .grey
                                .shade100,

                            borderRadius:
                            BorderRadius.circular(
                                20),

                            border:
                            Border.all(
                              color:
                              Colors.grey
                                  .shade300,
                            ),
                          ),

                          child:
                          _capturedImage !=
                              null
                              ? ClipRRect(
                            borderRadius:
                            BorderRadius.circular(
                                20),

                            child:
                            Image.file(
                              _capturedImage!,
                              fit:
                              BoxFit.cover,
                            ),
                          )
                              : const Icon(
                            Icons
                                .add_a_photo_rounded,
                            size: 40,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 28),

                      SizedBox(
                        width:
                        double.infinity,

                        child:
                        Container(
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
                            _submitSurvey,

                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.transparent,

                              shadowColor:
                              Colors.transparent,
                            ),

                            child:
                            const Text(
                              "SUBMIT",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}