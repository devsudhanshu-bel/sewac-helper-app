import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/sewac_background.dart';
import '../models/tracking_model.dart';
import '../services/tracking_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  bool _isTableView = false;

  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = "";

  List<TrackingModel> _logs = [];
  bool _isLoading = true;

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

      final result = await TrackingService.fetchLogs();


      print("UI Received Logs: ${result.length}");

      for (var item in result) {
        print(
            "${item.id} | ${item.workerId} | ${item.status}"
        );
      }

      setState(() {
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
          "https://sewac-helper-app.onrender.com/api/v1/auth/logout",
        ),

        headers: {

          "Authorization":
          "Bearer $token",

          "Content-Type":
          "application/json",
        },
      );

      print(
        "LOGOUT STATUS => ${response.statusCode}",
      );

      print(
        "LOGOUT BODY => ${response.body}",
      );

    } catch (e) {

      print(
        "LOGOUT ERROR => $e",
      );
    }

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(
      "auth_token",
    );

    await prefs.remove(
      "isLoggedIn",
    );

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
              log.workerId.toUpperCase() == _selectedWorker;

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
              onPressed: _handleLogout,
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
        ],
      ),
      body: SewacBackground(
        child: RefreshIndicator(
          onRefresh: _refreshLogs,
          color: const Color(0xFF4CAF50),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  16,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Logs Overview",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(
                              0.06,
                            ),
                            blurRadius: 12,
                            offset:
                            const Offset(0, 4),
                          )
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isTableView =
                            !_isTableView;
                          });
                        },
                        icon: AnimatedSwitcher(
                          duration:
                          const Duration(
                            milliseconds: 400,
                          ),
                          child: Icon(
                            _isTableView
                                ? Icons
                                .view_agenda_rounded
                                : Icons
                                .table_chart_rounded,
                            key: ValueKey(
                              _isTableView,
                            ),
                            color: const Color(
                              0xFF4CAF50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: TextField(
                  controller: _searchController,

                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },

                  decoration: InputDecoration(
                    hintText: "Search name, phone, worker...",

                    prefixIcon:
                    const Icon(Icons.search),

                    suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(
                        Icons.close,
                      ),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = "";
                        });
                      },
                    )
                        : null,

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                      borderSide:
                      BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Container(
                  padding:
                  const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                        _buildCustomDropdown(
                          label: "Worker ID",
                          value:
                          _selectedWorker,
                          items:
                          _workerIds,
                          icon: Icons
                              .badge_outlined,
                          onChanged:
                              (val) {
                            setState(() {
                              _selectedWorker =
                              val!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child:
                        _buildCustomDropdown(
                          label: "Status",
                          value:
                          _selectedStatus,
                          items:
                          _statusOptions,
                          icon: Icons
                              .analytics_outlined,
                          onChanged:
                              (val) {
                            setState(() {
                              _selectedStatus =
                              val!;
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
                    ? const Center(
                  child:
                  CircularProgressIndicator(),
                )
                    : AnimatedSwitcher(
                  duration:
                  const Duration(
                    milliseconds: 600,
                  ),
                  child: _isTableView
                      ? _buildTableView(
                    filteredLogs,
                  )
                      : _buildCardView(
                    filteredLogs,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCardView(List<TrackingModel> logs) {
    if (logs.isEmpty) return _buildEmptyState();

    return ListView.builder(
      physics:
      const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isFound = log.status == "FOUND";

        return Container(
          margin: const EdgeInsets.only(
            bottom: 16,
          ),
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              // Header
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFound
                        ? (log.citizenName ?? "-")
                        : "Not Found",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A237E),
                    ),
                  ),

                  _buildStatusBadge(
                    isFound,
                    isFound
                        ? "Found"
                        : "Not Found",
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 8),
              const SizedBox(height: 8),

              // FOUND
              if (isFound)
                _buildInfoGrid(log)

              // NOT FOUND
              else
                Container(
                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F8),
                    borderRadius:
                    BorderRadius.circular(18),
                  ),

                  child: Column(
                    children: [

                      // Row 1
                      Row(
                        children: [

                          _buildInfoItem(
                            Icons.badge_rounded,
                            "Worker ID",
                            log.workerId.toUpperCase(),
                          ),

                          _buildInfoItem(
                            Icons.person,
                            "Name",
                            log.citizenName ?? "-",
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // Row 2
                      Row(
                        children: [

                          _buildInfoItem(
                            Icons.phone,
                            "Phone",
                            log.phoneNumber ?? "-",
                          ),

                          _buildInfoItem(
                            Icons.warning_amber_rounded,
                            "Status",
                            log.status,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // Row 3
                      Row(
                        children: [

                          Expanded(
                            child: _buildInfoItem(
                              Icons.notes_rounded,
                              "Remarks",
                              log.remarks ?? "-",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(
      bool isFound,
      String status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isFound
            ? const Color(
          0xFFE8F5E9,
        )
            : const Color(
          0xFFFFEBEE,
        ),
        borderRadius:
        BorderRadius.circular(
          100,
        ),
      ),
      child: Text(
        status.toUpperCase(),
      ),
    );
  }

  Widget _buildInfoGrid(
      TrackingModel log,
      ) {
    return Column(
      children: [

        Row(
          children: [
            _buildInfoItem(
              Icons.badge_rounded,
              "Worker ID",
              log.workerId.toUpperCase(),
            ),

            _buildInfoItem(
              Icons.person,
              "Name",
              log.citizenName ?? "-",
            ),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            _buildInfoItem(
              Icons.phone,
              "Phone",
              log.phoneNumber ?? "-",
            ),

            _buildInfoItem(
              Icons.verified,
              "Status",
              log.status,
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            _buildInfoItem(
              Icons.water_drop_rounded,
              "Wet RFID",
              log.wetWasteRfid.isEmpty
                  ? "-"
                  : log.wetWasteRfid,
            ),

            _buildInfoItem(
              Icons.recycling_rounded,
              "Dry RFID",
              log.dryWasteRfid.isEmpty
                  ? "-"
                  : log.dryWasteRfid,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(
      IconData icon,
      String label,
      String value,
      ) {
    return Expanded(
      child: ListTile(
        leading: Icon(
          icon,
          size: 18,
        ),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildTableView(
      List<TrackingModel> logs,
      ) {
    if (logs.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
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
                headingRowColor:
                MaterialStateProperty.all(
                  const Color(0xFFF5F8F7),
                ),

                dataRowMinHeight: 58,
                dataRowMaxHeight: 70,

                horizontalMargin: 20,
                columnSpacing: 28,

                columns: const [

                  DataColumn(
                    label: Text(
                      "SL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Worker",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Name",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Wet RFID",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Dry RFID",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Phone",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Status",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                rows: logs.map((log) {

                  final isFound =
                      log.status == "FOUND";

                  return DataRow(
                    cells: [

                      DataCell(
                        Text(
                          log.id.toString(),
                        ),
                      ),

                      DataCell(
                        Text(
                          log.workerId.toUpperCase(),
                        ),
                      ),

                      DataCell(
                        Text(
                          log.citizenName ?? "-",
                        ),
                      ),

                      DataCell(
                        Text(
                          log.wetWasteRfid ?? "-",
                        ),
                      ),

                      DataCell(
                        Text(
                          log.dryWasteRfid ?? "-",
                        ),
                      ),

                      DataCell(
                        Text(
                          log.phoneNumber ?? "-",
                        ),
                      ),

                      DataCell(
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            color: isFound
                                ? const Color(
                              0xFFE8F5E9,
                            )
                                : const Color(
                              0xFFFFEBEE,
                            ),

                            borderRadius:
                            BorderRadius.circular(
                              100,
                            ),
                          ),

                          child: Text(
                            isFound
                                ? "FOUND"
                                : "NOT FOUND",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
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
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .find_in_page_rounded,
            size: 80,
            color:
            Colors.grey.shade300,
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            "No matching records found",
            style: TextStyle(
              fontSize: 16,
              color:
              Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}