import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/sewac_background.dart';
import '../models/tracking_model.dart';
import '../services/tracking_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/sewac_header.dart';
import 'dart:io';
import 'dart:async';
import '../config/api_constants.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  bool _isTableView = false;
  String _adminName = "";

  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = "";

  List<TrackingModel> _logs = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Pagination State
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  String _selectedWorker = "All Workers";
  String _selectedStatus = "All Status";

  final List<String> _workerIds = [
    "All Workers",
    ...List.generate(
      15,
          (index) => "SEWAC${(index + 1).toString().padLeft(2, '0')}",
    ),
  ];

  final List<String> _statusOptions = [
    "All Status",
    "Found",
    "Not Found"
  ];

  @override
  void initState() {
    super.initState();

    _fetchLogs();

    // FIXED: Replacing Future.doWhile with a standard periodic timer to avoid stacked calls
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchLogs();
      }
    });
  }

  @override
  void dispose() {
    // FIXED: Cancel the timer and dispose controllers to prevent memory leaks
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String savedUser =
          prefs.getString("workerId") ??
              prefs.getString("worker_id") ??
              prefs.getString("username") ??
              prefs.getString("user") ??
              prefs.getString("admin_name") ??
              "";

      final result = await TrackingService.fetchLogs();

      // DEBUG LOGS: Look at your terminal! Compare what your app saved vs what the server sends.
      print("---------------- SEWAC DEBUG ----------------");
      print("LOGGED IN USER (SharedPreferences): '$savedUser'");
      if (result.isNotEmpty) {
        print("FIRST LOG WORKER ID FROM SERVER: '${result.first.workerId}'");
      }
      print("---------------------------------------------");

      setState(() {
        _adminName = savedUser.trim();
        _logs = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Logs fetch error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshLogs() async {
    await _fetchLogs();
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workerId =
          prefs.getString("workerId") ??
              prefs.getString("worker_id") ??
              "";

      await prefs.remove("assignedStartRFID_$workerId");
      await prefs.remove("assignedEndRFID_$workerId");
      await prefs.remove("assignedMappedTagsList_$workerId");
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.post(
        Uri.parse("${ApiConstants.apiV1}/auth/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("LOGOUT STATUS => ${response.statusCode}");
      print("LOGOUT BODY => ${response.body}");
    } catch (e) {
      print("LOGOUT ERROR => $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("isLoggedIn");
    await prefs.remove("username");
    await prefs.remove("workerId");
    await prefs.remove("worker_id");
    await prefs.remove("user");

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // Searchable Dialog Picker for Worker List Selection handling high density entries
  void _showSearchableWorkerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String modalSearchQuery = "";
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredWorkers = _workerIds.where((worker) {
              return worker.toLowerCase().contains(modalSearchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Worker ID",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          "${filteredWorkers.length} items",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      autofocus: false,
                      onChanged: (value) {
                        setModalState(() {
                          modalSearchQuery = value.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Type code numbers (e.g. 15, 100)...",
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00A236), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredWorkers.isEmpty
                        ? Center(
                      child: Text(
                        "No matching workers found",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredWorkers.length,
                      itemBuilder: (context, index) {
                        final worker = filteredWorkers[index];
                        final isSelected = worker == _selectedWorker;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00A236).withOpacity(0.06) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            dense: true,
                            leading: Icon(
                              worker == "All Workers" ? Icons.group_outlined : Icons.badge_outlined,
                              color: isSelected ? const Color(0xFF00A236) : Colors.black54,
                              size: 18,
                            ),
                            title: Text(
                              worker,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF00A236) : const Color(0xFF2C3E50),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF00A236), size: 18)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedWorker = worker;
                                _currentPage = 1;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    for (final log in _logs.take(5)) {
      print("LOG WORKER => ${log.workerId}");
    }

    // FIXED: Soft matching logic to handle cases where worker ID might be "1" vs "SEWAC01" or have spaces
    final myFoundLogs = _logs.where((log) {
      if (_adminName.isEmpty) return false;

      String cleanWorkerId = log.workerId.trim().toUpperCase();
      String cleanAdminName = _adminName.trim().toUpperCase();

      // Matches if they are completely identical OR if one contains the other (e.g., "1" inside "SEWAC01")
      final isCurrentUser = (cleanWorkerId == cleanAdminName) ||
          cleanWorkerId.contains(cleanAdminName) ||
          cleanAdminName.contains(cleanWorkerId);

      final isFoundStatus = log.status.trim().toUpperCase() == "FOUND";
      return isCurrentUser && isFoundStatus;
    }).length;

    final allFoundLogs = _logs.where((log) {
      return log.status.trim().toUpperCase() == "FOUND";
    }).length;
    // 1. Gather all filtered logs first
    final filteredLogs = _logs.where((log) {
      final query = _searchQuery.toLowerCase();

      final searchMatch =
          _searchQuery.isEmpty ||
              (log.phoneNumber ?? "")
                  .toLowerCase()
                  .contains(query) ||
              (log.citizenName ?? "")
                  .toLowerCase()
                  .contains(query) ||
              log.workerId
                  .toLowerCase()
                  .contains(query) ||
              (log.wetWasteRfid ?? "")
                  .toLowerCase()
                  .contains(query) ||
              (log.dryWasteRfid ?? "")
                  .toLowerCase()
                  .contains(query);

      final workerMatch =
          _selectedWorker == "All Workers" ||
              log.workerId.toUpperCase() == _selectedWorker.toUpperCase();

      final statusText = log.status == "FOUND"
          ? "Found"
          : "Not Found";

      final statusMatch =
          _selectedStatus == "All Status" ||
              statusText == _selectedStatus;

      return workerMatch &&
          statusMatch &&
          searchMatch;
    }).toList();

    // 2. Calculate Total Pages based on current search/filter criteria
    final int totalPages = (filteredLogs.length / _itemsPerPage).ceil();

    // Safety check to avoid index breaking when filters shift results down
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }

    // 3. Extract the exact 10 items for the current active page
    final paginatedLogs = filteredLogs
        .skip((_currentPage - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SewacHeader(
        onLogout: _handleLogout,
      ),
      body: SewacBackground(
        child: RefreshIndicator(
          onRefresh: _refreshLogs,
          color: const Color(0xFF00A236),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Logs Overview",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              "Track and monitor synchronization history",
                              style: TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withOpacity(0.04)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _isTableView = !_isTableView;
                                if (_isTableView && _selectedStatus == "All Status") {
                                  _selectedStatus = "Found";
                                }
                                _currentPage = 1; // Reset to page 1 on view switch
                              });
                            },
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Icon(
                                _isTableView
                                    ? Icons.view_agenda_rounded
                                    : Icons.table_chart_rounded,
                                key: ValueKey(_isTableView),
                                color: const Color(0xFF00A236),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        // Box 1: Logged-in worker's FOUND logs
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withOpacity(0.03)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A236).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person_pin_rounded, color: Color(0xFF00A236), size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "My Found",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      "$myFoundLogs",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Box 2: Total Found counts across all workers
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withOpacity(0.03)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA000).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.group_rounded, color: Color(0xFFFFA000), size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Total Found",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      "$allFoundLogs",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                      _currentPage = 1; // Reset to page 1 when searching
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search name, phone, RFID, worker...",
                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = "";
                          _currentPage = 1;
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.black.withOpacity(0.04)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF00A236), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.03)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Enhanced Searchable Worker Trigger Layout Field Box
                      Expanded(
                        child: InkWell(
                          onTap: _showSearchableWorkerPicker,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Worker ID",
                              labelStyle: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13, fontWeight: FontWeight.w500),
                              prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Colors.black54),
                              suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2C3E50)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.black12),
                              ),
                            ),
                            child: Text(
                              _selectedWorker,
                              style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildCustomDropdown(
                          label: "Status",
                          value: _selectedStatus,
                          items: _isTableView
                              ? _statusOptions.where((opt) => opt != "All Status").toList()
                              : _statusOptions,
                          icon: Icons.analytics_outlined,
                          onChanged: (val) {
                            setState(() {
                              _selectedStatus = val!;
                              _currentPage = 1; // Reset to page 1 when filtering
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A236)))
                    : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isTableView
                      ? _buildTableView(paginatedLogs) // Uses the sliced 10-item list
                      : _buildCardView(paginatedLogs),  // Uses the sliced 10-item list
                ),
              ),
              // Pagination Controls UI
              if (!_isLoading && totalPages > 1)
                _buildPaginationControls(totalPages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.03)),
            ),
            child: IconButton(
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              color: const Color(0xFF00A236),
              disabledColor: Colors.grey.shade300,
            ),
          ),
          Text(
            "Page $_currentPage of $totalPages",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.03)),
            ),
            child: IconButton(
              onPressed: _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              color: const Color(0xFF00A236),
              disabledColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, size: 18, color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00A236), width: 1.5),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCardView(List<TrackingModel> logs) {
    if (logs.isEmpty) return _buildEmptyState();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isFound = log.status == "FOUND";

        Map<String, dynamic> logMap = {};
        try {
          logMap = (log as dynamic).toJson();
        } catch (_) {}

        final String cardStatus =
            logMap["status"]?.toString() ?? log.status ?? "";

        final String cardAddress =
            logMap["address"]?.toString() ?? log.address ?? "";

        final String cardBuildingNo =
            logMap["buildingNo"]?.toString() ?? log.buildingNo ?? "";

        final String cardFloorNo =
            logMap["floorNo"]?.toString() ?? log.floorNo ?? "";

        String cardPhotoUrl =
            logMap["photoUrl"]?.toString() ?? log.photoUrl ?? logMap["photo"]?.toString() ?? "";

        if (cardPhotoUrl.trim() == "null" || cardPhotoUrl.trim().isEmpty) {
          cardPhotoUrl = "";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withOpacity(0.03)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isFound
                          ? (log.citizenName ?? "-")
                          : "House Locked / Absent",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isFound ? const Color(0xFF2C3E50) : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                  _buildStatusBadge(
                    isFound,
                    isFound ? "Found" : cardStatus.replaceAll('_', ' '),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 14),
              if (isFound)
                _buildInfoGrid(log)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildStructuredMetaRow(Icons.location_on_outlined, "Address", cardAddress),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _buildStructuredMetaRow(Icons.apartment_outlined, "Building No", cardBuildingNo)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildStructuredMetaRow(Icons.unfold_more_outlined, "Floor No", cardFloorNo)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black12,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: cardPhotoUrl.trim().isNotEmpty
                                ? Image.network(
                              cardPhotoUrl.trim(),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A236)),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print("IMAGE LOAD ERROR => $error");
                                return Container(
                                  color: const Color(0xFFFFF5F5),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.redAccent,
                                    size: 26,
                                  ),
                                );
                              },
                            )
                                : Container(
                              color: const Color(0xFFF8F9FA),
                              child: const Icon(
                                Icons.image_outlined,
                                color: Colors.black38,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEBEE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.assignment_late_outlined, size: 18, color: Color(0xFFC62828)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "REMARKS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC62828), letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  log.remarks ?? "House locked",
                                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        "Logged By: ${log.workerId.toUpperCase()}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D), fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildStructuredMetaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF7F8C8D), fontWeight: FontWeight.bold, letterSpacing: 0.4)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50), fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isFound, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isFound ? const Color(0xFF00A236).withOpacity(0.1) : const Color(0xFFC62828).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isFound ? const Color(0xFF00A236) : const Color(0xFFC62828),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(TrackingModel log) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoItem(Icons.badge_rounded, "Worker ID", log.workerId.toUpperCase()),
              _buildInfoItem(Icons.person_outline_rounded, "Name", log.citizenName ?? "-"),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, color: Colors.black12),
          ),
          Row(
            children: [
              _buildInfoItem(Icons.phone_android_rounded, "Phone", log.phoneNumber ?? "-"),
              _buildInfoItem(Icons.verified_outlined, "Status", log.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, color: Colors.black12),
          ),
          Row(
            children: [
              _buildInfoItem(Icons.water_drop_outlined, "Wet RFID", log.wetWasteRfid.isEmpty ? "-" : log.wetWasteRfid),
              _buildInfoItem(Icons.recycling_rounded, "Dry RFID", log.dryWasteRfid.isEmpty ? "-" : log.dryWasteRfid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF00A236)),
        ),
        title: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
        subtitle: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
      ),
    );
  }

  Widget _buildTableView(List<TrackingModel> logs) {
    if (logs.isEmpty) {
      return _buildEmptyState();
    }

    final bool rendersFoundTable = _selectedStatus == "Found";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FA)),
                dataRowMinHeight: 60,
                dataRowMaxHeight: 72,
                horizontalMargin: 20,
                columnSpacing: 28,
                columns: rendersFoundTable
                    ? const [
                  DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Worker", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Wet RFID", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Dry RFID", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                ]
                    : const [
                  DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Worker", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Address Specification", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Building No", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Floor", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                  DataColumn(label: Text("Remarks Exception", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                ],
                rows: logs.map((log) {
                  Map<String, dynamic> logMap = {};
                  try {
                    logMap = (log as dynamic).toJson();
                  } catch (_) {}

                  final String tableAddress =
                      logMap["address"]?.toString() ?? log.address ?? "";

                  final String tableBuildingNo =
                      logMap["buildingNo"]?.toString() ?? log.buildingNo ?? "";

                  final String tableFloorNo =
                      logMap["floorNo"]?.toString() ?? log.floorNo ?? "";

                  return DataRow(
                    cells: rendersFoundTable
                        ? [
                      DataCell(Text(log.id.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(log.workerId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)))),
                      DataCell(Text(log.citizenName ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                      DataCell(Text(log.wetWasteRfid ?? "-")),
                      DataCell(Text(log.dryWasteRfid ?? "-")),
                      DataCell(Text(log.phoneNumber ?? "-")),
                    ]
                        : [
                      DataCell(Text(log.id.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(log.workerId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)))),
                      DataCell(Text(tableAddress)),
                      DataCell(Text(tableBuildingNo)),
                      DataCell(Text(tableFloorNo)),
                      DataCell(
                        Text(
                          log.remarks ?? "House locked",
                          style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
            ),
            child: Icon(
              Icons.find_in_page_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No matching records found",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}