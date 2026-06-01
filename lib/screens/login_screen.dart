import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/sewac_button.dart';
import 'main_navigation_screen.dart';
import '../services/auth_service.dart';
import '../widgets/sewac_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _hidePassword = true;
  final _formKey = GlobalKey<FormState>();
  final _adminNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _fieldsFade;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _cardFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    );

    _fieldsFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _adminNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPopup({required String message, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _showPopup(
        message: "Please fill all fields",
        color: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginResult = await AuthService.login(
        username: _adminNameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (loginResult == "SUCCESS") {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('isLoggedIn', true);

        // CLEAR PREVIOUS USER'S SURVEY DATA
        await prefs.remove("survey_city");
        await prefs.remove("survey_ward");
        await prefs.remove("survey_area");
        await prefs.remove("survey_building_photo_path");

        _showPopup(
          message: "Login Successful",
          color: const Color(0xFF4CAF50),
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ),
        );
      } else if (loginResult == "ALREADY_IN_USE") {
        _showPopup(
          message: "Account already in use",
          color: Colors.orange,
        );
      } else if (loginResult == "SERVER_ERROR") {
        _showPopup(
          message: "Server not reachable",
          color: Colors.orange,
        );
      } else {
        _showPopup(
          message: "Invalid username or password",
          color: Colors.redAccent,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showPopup(
        message: "Server not reachable",
        color: Colors.orange,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SewacBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        children: [
                          Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              "assets/images/logo.png",
                              height: 140,
                              width: 140,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.recycling_rounded,
                                  size: 100,
                                  color: Color(0xFF4CAF50),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "HELPER APP",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A237E),
                              letterSpacing: 2,
                            ),
                          ),
                          const Text(
                            "Rfid Management Portal",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FadeTransition(
                                    opacity: _fieldsFade,
                                    child: const Text(
                                      "Admin Login",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FadeTransition(
                                    opacity: _fieldsFade,
                                    child: _buildInputField(
                                      controller: _adminNameController,
                                      label: "Username",
                                      icon: Icons.person_pin_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FadeTransition(
                                    opacity: _fieldsFade,
                                    child: _buildInputField(
                                      controller: _passwordController,
                                      label: "Password",
                                      icon: Icons.lock_person_rounded,
                                      isPassword: true,
                                    ),
                                  ),
                                  const SizedBox(height: 24), // Replaced checkbox padding layout space
                                  FadeTransition(
                                    opacity: _fieldsFade,
                                    child: SewacButton(
                                      text: "AUTHENTICATE",
                                      isLoading: _isLoading,
                                      onPressed: _handleLogin,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _hidePassword : false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Required";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4CAF50),
        ),
        suffixIcon: isPassword
            ? IconButton(
          onPressed: () {
            setState(() {
              _hidePassword = !_hidePassword;
            });
          },
          icon: Icon(
            _hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey,
          ),
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}