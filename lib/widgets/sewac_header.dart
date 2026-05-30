import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class SewacHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;

  const SewacHeader({
    super.key,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  State<SewacHeader> createState() => _SewacHeaderState();
}

class _SewacHeaderState extends State<SewacHeader> {
  String _adminName = "A";
  int _availableTagsCount = 0;
  String _rangeDisplay = "Not Assigned";
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadAdminName();
    _fetchHeaderTrackingData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) => _fetchHeaderTrackingData(),
    );
  }

  @override
  void didUpdateWidget(covariant SewacHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchHeaderTrackingData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _adminName = prefs.getString("admin_name") ?? "A";
    });
  }

  Future<void> _fetchHeaderTrackingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final workerId =
          prefs.getString("workerId") ??
              prefs.getString("worker_id") ??
              prefs.getString("username") ??
              "";

      final int? start =
      prefs.getInt("assignedStartRFID_$workerId");

      final int? end =
      prefs.getInt("assignedEndRFID_$workerId");

      final List<String> mappedTags =
          prefs.getStringList(
            "assignedMappedTagsList_$workerId",
          ) ?? [];
      if (start != null && end != null) {
        final int totalCapacity = (end - start + 1);
        int availableCount = totalCapacity - mappedTags.length;
        if (availableCount < 0) availableCount = 0;

        if (mounted) {
          setState(() {
            _rangeDisplay = "$start - $end";
            _availableTagsCount = availableCount;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("Header local range compute error: $e");
    }

    // Fallback logic if range is completely not set yet or null values encountered
    if (mounted) {
      setState(() {
        _rangeDisplay = "Not Assigned";
        _availableTagsCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 62,
      leadingWidth: 70,
      backgroundColor: const Color(0xFFF8FBF8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
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
      title: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Range: $_rangeDisplay",
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Available Tags: $_availableTagsCount",
              style: const TextStyle(
                color: Color(0xFF00A236),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Username chip
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xFF4CAF50),
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _adminName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
        // Logout
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF1A237E),
            ),
          ),
        ),
      ],
    );
  }
}