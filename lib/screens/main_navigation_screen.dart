import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'logs_screen.dart';
import 'survey_screen.dart';
import 'reader_screen.dart';

class MainNavigationScreen
    extends StatefulWidget {

  const MainNavigationScreen({
    super.key,
  });

  @override
  State<MainNavigationScreen>
  createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<
        MainNavigationScreen> {

  int _currentIndex =
  0;

  // ONLY UPDATED:
  // Reader screen added
  final List<Widget>
  _pages = [

    const DashboardScreen(),

    const LogsScreen(),

    const SurveyScreen(),

    const ReaderScreen(),
  ];

  void _onTap(
      int index) {

    if (_currentIndex ==
        index) {
      return;
    }

    HapticFeedback
        .lightImpact();

    setState(() {

      _currentIndex =
          index;
    });
  }

  @override
  Widget build(
      BuildContext context) {

    final safeIndex =
    _currentIndex >=
        _pages.length

        ? 0

        : _currentIndex;

    return Scaffold(

      body: _pages[safeIndex],

      bottomNavigationBar:
      Container(

        decoration:
        BoxDecoration(

          color:
          Colors.white,

          boxShadow: [

            BoxShadow(

              color:
              Colors.black
                  .withOpacity(
                  0.04),

              blurRadius:
              20,

              offset:
              const Offset(
                  0, -4),
            ),
          ],
        ),

        child:
        SafeArea(

          child:
          Padding(

            padding:
            const EdgeInsets.symmetric(

              horizontal:
              24,

              vertical:
              8,
            ),

            child:
            Row(

              mainAxisAlignment:
              MainAxisAlignment
                  .spaceAround,

              children: [

                _buildNavItem(

                  0,

                  Icons
                      .dashboard_rounded,

                  Icons
                      .dashboard_outlined,

                  "Home",
                ),

                _buildNavItem(

                  1,

                  Icons
                      .assignment_rounded,

                  Icons
                      .assignment_outlined,

                  "Logs",
                ),

                _buildNavItem(

                  2,

                  Icons
                      .fact_check_rounded,

                  Icons
                      .fact_check_outlined,

                  "Survey",
                ),

                // ONLY ADDED
                _buildNavItem(

                  3,

                  Icons
                      .nfc_rounded,

                  Icons
                      .nfc_outlined,

                  "Reader",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(

      int index,

      IconData activeIcon,

      IconData inactiveIcon,

      String label,
      ) {

    final isSelected =
        _currentIndex ==
            index;

    final color =
    isSelected

        ? const Color(
        0xFF4CAF50)

        : Colors.grey
        .shade400;

    return GestureDetector(

      onTap:
          () =>
          _onTap(index),

      behavior:
      HitTestBehavior
          .opaque,

      child:
      AnimatedContainer(

        duration:
        const Duration(
            milliseconds:
            300),

        padding:
        const EdgeInsets.symmetric(

          horizontal:
          20,

          vertical:
          10,
        ),

        decoration:
        BoxDecoration(

          color:

          isSelected

              ? const Color(
              0xFF4CAF50)
              .withOpacity(
              0.1)

              : Colors
              .transparent,

          borderRadius:
          BorderRadius.circular(
              16),
        ),

        child:
        Row(

          children: [

            Icon(

              isSelected

                  ? activeIcon

                  : inactiveIcon,

              color:
              color,

              size:
              26,
            ),

            if (isSelected)
              ...[

                const SizedBox(
                  width:
                  8,
                ),

                Text(

                  label,

                  style:
                  TextStyle(

                    color:
                    color,

                    fontWeight:
                    FontWeight
                        .bold,

                    fontSize:
                    14,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}