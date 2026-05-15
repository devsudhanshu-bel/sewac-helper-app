import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _bgController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _logoController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: 1500,
          ),
        );

    _bgController =
    AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 6,
      ),
    )..repeat();

    _fadeAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _logoController,
            curve: Curves.easeIn,
          ),
        );

    _scaleAnimation =
        Tween<double>(
          begin: 0.7,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _logoController,
            curve: Curves.easeOutBack,
          ),
        );

    _rotationAnimation =
        Tween<double>(
          begin: 0,
          end: 0.03,
        ).animate(
          CurvedAnimation(
            parent: _bgController,
            curve: Curves.easeInOut,
          ),
        );

    _logoController.forward();

    _navigateNext();
  }

  Future<void>
  _navigateNext() async {

    final prefs =
    await SharedPreferences
        .getInstance();

    final isLoggedIn =
        prefs.getBool(
          "isLoggedIn",
        ) ?? false;

    Timer(
      const Duration(
        seconds: 3,
      ),

          () {

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,

          PageRouteBuilder(

            pageBuilder:
                (_, __, ___) =>

            isLoggedIn
                ? const MainNavigationScreen()
                : const LoginScreen(),

            transitionsBuilder:
                (
                context,
                animation,
                secondaryAnimation,
                child,
                ) {

              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },

            transitionDuration:
            const Duration(
              milliseconds: 700,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Colors.white,

      body: AnimatedBuilder(
        animation: _bgController,

        builder: (
            context,
            child,
            ) {

          return Stack(
            children: [

              Positioned(
                top: -80,
                right: -60,
                child: Transform.rotate(
                  angle:
                  _rotationAnimation
                      .value,
                  child:
                  _buildCircle(
                    220,
                    const Color(
                      0xFF4CAF50,
                    ).withOpacity(
                      0.08,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: -100,
                left: -80,
                child: Transform.rotate(
                  angle:
                  -_rotationAnimation
                      .value,
                  child:
                  _buildCircle(
                    260,
                    const Color(
                      0xFFFF9800,
                    ).withOpacity(
                      0.08,
                    ),
                  ),
                ),
              ),

              Center(
                child:
                FadeTransition(
                  opacity:
                  _fadeAnimation,

                  child:
                  ScaleTransition(
                    scale:
                    _scaleAnimation,

                    child:
                    Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                      children: [

                        Container(
                          padding:
                          const EdgeInsets.all(
                            22,
                          ),

                          decoration:
                          BoxDecoration(
                            shape:
                            BoxShape.circle,

                            boxShadow: [

                              BoxShadow(
                                color: const Color(
                                  0xFF4CAF50,
                                ).withOpacity(
                                  0.15,
                                ),

                                blurRadius:
                                35,
                                spreadRadius:
                                8,
                              ),
                            ],
                          ),

                          child:
                          Image.asset(
                            "assets/images/logo.png",

                            width:
                            150,
                            height:
                            150,

                            errorBuilder:
                                (
                                context,
                                error,
                                stackTrace,
                                ) {
                              return const Icon(
                                Icons.recycling_rounded,
                                size: 120,
                                color: Color(
                                  0xFF4CAF50,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        const Text(
                          "SEWAC",

                          style:
                          TextStyle(
                            fontSize: 34,
                            fontWeight:
                            FontWeight.w900,
                            letterSpacing: 6,
                            color:
                            Color(0xFF1A237E),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          "HELPER APP",

                          style:
                          TextStyle(
                            fontSize: 13,
                            letterSpacing: 5,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCircle(
      double size,
      Color color,
      ) {
    return Container(
      width: size,
      height: size,

      decoration:
      BoxDecoration(
        color: color,
        shape:
        BoxShape.circle,
      ),
    );
  }
}