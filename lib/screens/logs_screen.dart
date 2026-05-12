  import 'package:flutter/material.dart';
  import 'login_screen.dart';

  class LogsScreen extends StatefulWidget {
    const LogsScreen({super.key});

    @override
    State<LogsScreen> createState() => _LogsScreenState();
  }

  class _LogsScreenState extends State<LogsScreen> with SingleTickerProviderStateMixin {
    bool _isTableView = false;
    String _selectedWorker = "All Workers";
    String _selectedStatus = "All Status";

    final List<String> _workerIds = [
      "All Workers",
      ...List.generate(15, (index) => "SEWAC${(index + 1).toString().padLeft(2, '0')}")
    ];

    final List<String> _statusOptions = ["All Status", "Found", "Not Found"];

    // Enterprise Mock Data
    final List<Map<String, String>> _logs = [
      {
        "sl": "1",
        "worker": "SEWAC01",
        "rfid": "RFID-8829-X1",
        "name": "Johnathan Doe",
        "phone": "+91 9876543210",
        "status": "Found",
      },
      {
        "sl": "2",
        "worker": "SEWAC03",
        "rfid": "RFID-1022-A4",
        "name": "Maria Garcia",
        "phone": "+91 9123456780",
        "status": "Not Found",
      },
      {
        "sl": "3",
        "worker": "SEWAC01",
        "rfid": "RFID-9938-Z2",
        "name": "David Smith",
        "phone": "+91 9988776655",
        "status": "Found",
      },
      {
        "sl": "4",
        "worker": "SEWAC07",
        "rfid": "RFID-4451-Q9",
        "name": "Priya Sharma",
        "phone": "+91 9001122334",
        "status": "Found",
      },
      {
        "sl": "5",
        "worker": "SEWAC02",
        "rfid": "RFID-7762-L3",
        "name": "Arjun Singh",
        "phone": "+91 9445566778",
        "status": "Not Found",
      },
      {
        "sl": "6",
        "worker": "SEWAC05",
        "rfid": "RFID-3321-K8",
        "name": "Sarah Jenkins",
        "phone": "+91 9112233445",
        "status": "Found",
      },
    ];

    Future<void> _refreshLogs() async {
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {});
    }

    @override
    Widget build(BuildContext context) {
      final filteredLogs = _logs.where((log) {
        final workerMatch = _selectedWorker == "All Workers" || log["worker"] == _selectedWorker;
        final statusMatch = _selectedStatus == "All Status" || log["status"] == _selectedStatus;
        return workerMatch && statusMatch;
      }).toList();

      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                "assets/images/logo.png",
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.recycling, color: Color(0xFF4CAF50)),
              ),
            ),
          ),
          title: const Text(
            "SEWAC Helper",
            style: TextStyle(
              color: Color(0xFF1A237E), // Professional Navy
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.0,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF1A237E)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshLogs,
          color: const Color(0xFF4CAF50),
          child: Column(
            children: [
              // Title and Toggle Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => setState(() => _isTableView = !_isTableView),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) => RotationTransition(
                            turns: Tween<double>(begin: 0.5, end: 1.0).animate(anim),
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: Icon(
                            _isTableView ? Icons.view_agenda_rounded : Icons.table_chart_rounded,
                            key: ValueKey(_isTableView),
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Premium Filter Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCustomDropdown(
                          label: "Worker ID",
                          value: _selectedWorker,
                          items: _workerIds,
                          icon: Icons.badge_outlined,
                          onChanged: (val) => setState(() => _selectedWorker = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCustomDropdown(
                          label: "Status",
                          value: _selectedStatus,
                          items: _statusOptions,
                          icon: Icons.analytics_outlined,
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Animated List/Table Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  child: _isTableView
                      ? _buildTableView(filteredLogs)
                      : _buildCardView(filteredLogs),
                ),
              ),
            ],
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 22),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 16,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                ),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: const Color(0xFF4CAF50).withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text(item),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildCardView(List<Map<String, String>> logs) {
      if (logs.isEmpty) return _buildEmptyState();

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: logs.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final log = logs[index];
          final isFound = log["status"] == "Found";

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log["name"]!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      _buildStatusBadge(isFound, log["status"]!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
                  const SizedBox(height: 16),
                  _buildInfoGrid(log),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget _buildStatusBadge(bool isFound, String status) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFound ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isFound ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    Widget _buildInfoGrid(Map<String, String> log) {
      return Column(
        children: [
          Row(
            children: [
              _buildInfoItem(Icons.tag, "SL", log["sl"]!),
              _buildInfoItem(Icons.badge_rounded, "Worker", log["worker"]!),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoItem(Icons.qr_code_2_rounded, "RFID", log["rfid"]!),
              _buildInfoItem(Icons.phone_iphone_rounded, "Phone", log["phone"]!),
            ],
          ),
        ],
      );
    }

    Widget _buildInfoItem(IconData icon, String label, String value) {
      return Expanded(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: Colors.blueGrey),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildTableView(List<Map<String, String>> logs) {
      if (logs.isEmpty) return _buildEmptyState();

      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              color: const Color(0xFF4CAF50),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.unfold_more_rounded, size: 14, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    "Horizontal scroll enabled for detailed data",
                    style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: DataTable(
                    columnSpacing: 32,
                    headingRowHeight: 60,
                    dataRowMaxHeight: 70,
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                      fontSize: 13,
                    ),
                    columns: const [
                      DataColumn(label: Text("SL")),
                      DataColumn(label: Text("Worker ID")),
                      DataColumn(label: Text("RFID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Phone")),
                      DataColumn(label: Text("Status")),
                    ],
                    rows: List.generate(logs.length, (index) {
                      final log = logs[index];
                      final isFound = log["status"] == "Found";
                      final isEven = index % 2 == 0;

                      return DataRow(
                        color: WidgetStateProperty.all(isEven ? Colors.transparent : const Color(0xFFF8F9FA)),
                        cells: [
                          DataCell(Text(log["sl"]!)),
                          DataCell(Text(log["worker"]!, style: const TextStyle(fontWeight: FontWeight.w700))),
                          DataCell(Text(log["rfid"]!)),
                          DataCell(Text(log["name"]!, style: const TextStyle(fontWeight: FontWeight.w700))),
                          DataCell(Text(log["phone"]!)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFound ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log["status"]!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isFound ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.find_in_page_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              "No matching records found",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
  }
