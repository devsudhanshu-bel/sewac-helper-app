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

      print("UI Received Logs: ${result.length}");

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
      final prefs =
      await SharedPreferences.getInstance();

      final token =
          prefs.getString(
            "auth_token",
          ) ?? "";

      final response =
      await http.post(
        Uri.parse(
          "https://pretty-learning-production-c9f0.up.railway.app/api/v1/auth/logout",
        ),
        headers: {
          "Authorization":
          "Bearer $token",
          "Content-Type":
          "application/json",
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

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Computed variables inside build() for metrics counting status == "FOUND"
    final myFoundLogs = _logs.where((log) {
      if (_adminName.isEmpty) return false;
      final isCurrentUser = log.workerId.trim().toUpperCase() == _adminName.toUpperCase();
      final isFoundStatus = log.status.trim().toUpperCase() == "FOUND";
      return isCurrentUser && isFoundStatus;
    }).length;

    final allFoundLogs = _logs.where((log) {
      return log.status.trim().toUpperCase() == "FOUND";
    }).length;

    // 1. Gather all filtered logs first
    final filteredLogs = _logs.where((log) {
      final searchMatch =
          _searchQuery.isEmpty ||
              (log.phoneNumber ?? "")
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (log.citizenName ?? "")
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              log.workerId
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());

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
          color: const Color(0xFF4CAF50),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Logs Overview",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Row(
                      children: [
                        // Box 1: Logged-in worker's FOUND logs
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "My Found",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$myFoundLogs",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Box 2: Total Found counts across all workers
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Total Found",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$allFoundLogs",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
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
                                color: const Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                      _currentPage = 1; // Reset to page 1 when searching
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search name, phone, worker...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCustomDropdown(
                          label: "Worker ID",
                          value: _selectedWorker,
                          items: _workerIds,
                          icon: Icons.badge_outlined,
                          onChanged: (val) {
                            setState(() {
                              _selectedWorker = val!;
                              _currentPage = 1; // Reset to page 1 when filtering
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
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
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: _isTableView
                      ? _buildTableView(paginatedLogs) // Uses the sliced 10-item list
                      : _buildCardView(paginatedLogs),  // Uses the sliced 10-item list
                ),
              ),
              // Pagination Controls UI added at the bottom
              if (!_isLoading && totalPages > 1)
                _buildPaginationControls(totalPages),
            ],
          ),
        ),
      ),
    );
  }

  // A sleek control bar matching your clean theme styling
  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: const Color(0xFF4CAF50),
            disabledColor: Colors.grey.shade400,
          ),
          Text(
            "Page $_currentPage of $totalPages",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            color: const Color(0xFF4CAF50),
            disabledColor: Colors.grey.shade400,
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCardView(List<TrackingModel> logs) {
    if (logs.isEmpty) return _buildEmptyState();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFound
                        ? (log.citizenName ?? "-")
                        : "House Locked / Absent",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isFound ? const Color(0xFF1A237E) : const Color(0xFFC62828),
                    ),
                  ),
                  _buildStatusBadge(
                    isFound,
                    isFound ? "Found" : cardStatus.replaceAll('_', ' '),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 8),
              const SizedBox(height: 10),
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _buildStructuredMetaRow(Icons.apartment_outlined, "Building No", cardBuildingNo)),
                                  Expanded(child: _buildStructuredMetaRow(Icons.unfold_more_outlined, "Floor No", cardFloorNo)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black12,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: cardPhotoUrl.trim().isNotEmpty
                                ? Image.network(
                              cardPhotoUrl.trim(),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print("IMAGE LOAD ERROR => $error");
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.redAccent,
                                    size: 26,
                                  ),
                                );
                              },
                            )
                                : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_outlined,
                                color: Colors.black38,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEBEE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.assignment_late_outlined, size: 16, color: Color(0xFFC62828)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "REMARKS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC62828), letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 2),
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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        "Logged By: ${log.workerId.toUpperCase()}",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isFound, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFound ? const Color(0xFFE8F5E9) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isFound ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isFound ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(TrackingModel log) {
    return Column(
      children: [
        Row(
          children: [
            _buildInfoItem(Icons.badge_rounded, "Worker ID", log.workerId.toUpperCase()),
            _buildInfoItem(Icons.person, "Name", log.citizenName ?? "-"),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildInfoItem(Icons.phone, "Phone", log.phoneNumber ?? "-"),
            _buildInfoItem(Icons.verified, "Status", log.status),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoItem(Icons.water_drop_rounded, "Wet RFID", log.wetWasteRfid.isEmpty ? "-" : log.wetWasteRfid),
            _buildInfoItem(Icons.recycling_rounded, "Dry RFID", log.dryWasteRfid.isEmpty ? "-" : log.dryWasteRfid),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
        title: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    );
  }

  Widget _buildTableView(List<TrackingModel> logs) {
    if (logs.isEmpty) {
      return _buildEmptyState();
    }

    final bool rendersFoundTable = _selectedStatus == "Found";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
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
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F8F7)),
                dataRowMinHeight: 58,
                dataRowMaxHeight: 70,
                horizontalMargin: 20,
                columnSpacing: 28,
                columns: rendersFoundTable
                    ? const [
                  DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Worker", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Wet RFID", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Dry RFID", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold))),
                ]
                    : const [
                  DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Worker", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Address Specification", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Building No", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Floor", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Remarks Exception", style: TextStyle(fontWeight: FontWeight.bold))),
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
                      DataCell(Text(log.id.toString())),
                      DataCell(Text(log.workerId.toUpperCase())),
                      DataCell(Text(log.citizenName ?? "-")),
                      DataCell(Text(log.wetWasteRfid ?? "-")),
                      DataCell(Text(log.dryWasteRfid ?? "-")),
                      DataCell(Text(log.phoneNumber ?? "-")),
                    ]
                        : [
                      DataCell(Text(log.id.toString())),
                      DataCell(Text(log.workerId.toUpperCase())),
                      DataCell(Text(tableAddress)),
                      DataCell(Text(tableBuildingNo)),
                      DataCell(Text(tableFloorNo)),
                      DataCell(
                        Text(
                          log.remarks ?? "House locked",
                          style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w500),
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
          Icon(
            Icons.find_in_page_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            "No matching records found",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}