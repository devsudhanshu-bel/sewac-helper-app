import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'logs_screen.dart';
import 'survey_screen.dart';
import 'reader_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // UPDATED: Added a local Navigator key for the Survey Tab
  // This keeps any modal popups contained strictly inside the content area of the Survey tab
  final GlobalKey<NavigatorState> _surveyNavigatorKey = GlobalKey<NavigatorState>();

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();

      case 1:
        return const LogsScreen();

      case 2:
      // UPDATED: Wrapped SurveyScreen inside a tab-scoped nested Navigator
        return Navigator(
          key: _surveyNavigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const SurveyScreen(),
            );
          },
        );

      case 3:
        return const ReaderScreen();

      default:
        return const DashboardScreen();
    }
  }

  void _onTap(int index) {
    if (_currentIndex == index) {
      return;
    }

    HapticFeedback.lightImpact();

    // UPDATED: Automatically drain/dismiss any active popups or dialogs inside
    // the Survey local stack right before switching tabs so they don't block navigation
    if (_currentIndex == 2) {
      while (_surveyNavigatorKey.currentState?.canPop() ?? false) {
        _surveyNavigatorKey.currentState?.pop();
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard_rounded,
                  Icons.dashboard_outlined,
                  "Home",
                ),
                _buildNavItem(
                  1,
                  Icons.assignment_rounded,
                  Icons.assignment_outlined,
                  "Logs",
                ),
                _buildNavItem(
                  2,
                  Icons.fact_check_rounded,
                  Icons.fact_check_outlined,
                  "Survey",
                ),
                _buildNavItem(
                  3,
                  Icons.nfc_rounded,
                  Icons.nfc_outlined,
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
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}