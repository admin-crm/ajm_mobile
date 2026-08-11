import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Date range filters
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Attendance status filter
  String _selectedAttendanceStatus = 'all';
  
  // Loading & Data states
  bool _isLoading = false;
  List<dynamic> _leaves = [];
  List<dynamic> _permissions = [];
  List<dynamic> _attendance = [];

  // Summary counts
  int _totalLeaves = 0;
  int _approvedLeaves = 0;
  int _pendingLeaves = 0;
  
  int _totalPermissions = 0;
  double _totalPermissionHours = 0.0;
  
  int _presentDays = 0;
  int _absentDays = 0;
  int _halfDays = 0;
  int _holidayDays = 0;
  int _lateArrivals = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Default range: current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // last day of month
    
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _fetchData();
    }
  }

  String _formatDateForApi(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateForDisplay(dynamic dateStr) {
    if (dateStr == null || dateStr == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final startStr = _formatDateForApi(_startDate);
    final endStr = _formatDateForApi(_endDate);
    
    try {
      if (_tabController.index == 0) {
        // Fetch Leaves
        final data = await auth.apiService.getLeaveApplications(
          startDate: startStr.isNotEmpty ? startStr : null,
          endDate: endStr.isNotEmpty ? endStr : null,
        );
        _calculateLeaveStats(data);
        if (mounted) {
          setState(() {
            _leaves = data;
            _isLoading = false;
          });
        }
      } else if (_tabController.index == 1) {
        // Fetch Permissions
        final data = await auth.apiService.getShortPermissions(
          startDate: startStr.isNotEmpty ? startStr : null,
          endDate: endStr.isNotEmpty ? endStr : null,
        );
        _calculatePermissionStats(data);
        if (mounted) {
          setState(() {
            _permissions = data;
            _isLoading = false;
          });
        }
      } else {
        // Fetch Attendance
        final data = await auth.apiService.getAttendanceRecords(
          startDate: startStr.isNotEmpty ? startStr : null,
          endDate: endStr.isNotEmpty ? endStr : null,
          status: _selectedAttendanceStatus,
        );
        _calculateAttendanceStats(data);
        if (mounted) {
          setState(() {
            _attendance = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  void _calculateLeaveStats(List<dynamic> list) {
    _totalLeaves = list.length;
    _approvedLeaves = list.where((x) => x['status']?.toString().toLowerCase() == 'approved').length;
    _pendingLeaves = list.where((x) => x['status']?.toString().toLowerCase() == 'pending').length;
  }

  void _calculatePermissionStats(List<dynamic> list) {
    _totalPermissions = list.length;
    double hours = 0.0;
    for (var x in list) {
      try {
        hours += double.parse(x['total_hours']?.toString() ?? '0');
      } catch (_) {}
    }
    _totalPermissionHours = double.parse(hours.toStringAsFixed(2));
  }

  void _calculateAttendanceStats(List<dynamic> list) {
    _presentDays = list.where((x) => x['status']?.toString().toLowerCase() == 'present').length;
    _absentDays = list.where((x) => x['status']?.toString().toLowerCase() == 'absent').length;
    _halfDays = list.where((x) => x['status']?.toString().toLowerCase() == 'half_day').length;
    _holidayDays = list.where((x) => 
      x['status']?.toString().toLowerCase() == 'holiday' || 
      x['status']?.toString().toLowerCase() == 'on_leave'
    ).length;
    _lateArrivals = list.where((x) => x['is_late'] == true).length;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  void _applyQuickRange(String range) {
    final now = DateTime.now();
    setState(() {
      if (range == 'month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (range == '30days') {
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
      } else {
        _startDate = null;
        _endDate = null;
      }
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Leave Report'),
            Tab(text: 'Permission'),
            Tab(text: 'Attendance'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterHeader(theme, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveReportTab(theme, isDark),
                _buildPermissionReportTab(theme, isDark),
                _buildAttendanceReportTab(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(ThemeData theme, bool isDark) {
    final dateDisplay = (_startDate != null && _endDate != null)
        ? "${_formatDateForDisplay(_startDate)}  →  ${_formatDateForDisplay(_endDate)}"
        : "All-Time Records";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateDisplay,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildQuickChip('This Month', () => _applyQuickRange('month')),
              const SizedBox(width: 8),
              _buildQuickChip('Last 30 Days', () => _applyQuickRange('30days')),
              const SizedBox(width: 8),
              _buildQuickChip('Clear Filters', () => _applyQuickRange('clear')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetricsRow(List<Widget> cards) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: cards.map((card) => Expanded(child: card)).toList(),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final lowerStatus = status.toLowerCase();
    Color badgeColor = Colors.orange;
    
    if (lowerStatus == 'approved' || lowerStatus == 'present') {
      badgeColor = Colors.green;
    } else if (lowerStatus == 'rejected' || lowerStatus == 'absent') {
      badgeColor = Colors.red;
    } else if (lowerStatus == 'holiday' || lowerStatus == 'on_leave') {
      badgeColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveReportTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSummaryMetricsRow([
              _buildMetricCard(
                title: 'Total Applications',
                value: '$_totalLeaves',
                color: theme.primaryColor,
                icon: Icons.assignment_outlined,
                theme: theme,
                isDark: isDark,
              ),
              _buildMetricCard(
                title: 'Approved Leaves',
                value: '$_approvedLeaves',
                color: Colors.green,
                icon: Icons.done_all_outlined,
                theme: theme,
                isDark: isDark,
              ),
              _buildMetricCard(
                title: 'Pending Review',
                value: '$_pendingLeaves',
                color: Colors.orange,
                icon: Icons.hourglass_empty_outlined,
                theme: theme,
                isDark: isDark,
              ),
            ]),
          ),
          if (_leaves.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState('No leave application history found for this period.'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _leaves[index];
                  String type = 'Leave';
                  if (item['leave_type'] != null) {
                    if (item['leave_type'] is Map) {
                      type = item['leave_type']['name'] ?? 'Leave';
                    } else {
                      type = item['leave_type'].toString();
                    }
                  }

                  final fromDate = _formatDateForDisplay(item['start_date']);
                  final toDate = _formatDateForDisplay(item['end_date']);
                  final totalDays = item['total_days']?.toString() ?? '1';
                  final reason = item['reason'] ?? 'No reason provided';
                  final status = item['status'] ?? 'pending';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$fromDate  →  $toDate',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: $totalDays Day(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(height: 16),
                          Text(
                            'Reason: $reason',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _leaves.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionReportTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSummaryMetricsRow([
              _buildMetricCard(
                title: 'Total Permissions',
                value: '$_totalPermissions',
                color: theme.primaryColor,
                icon: Icons.timer_outlined,
                theme: theme,
                isDark: isDark,
              ),
              _buildMetricCard(
                title: 'Total Hours Used',
                value: '$_totalPermissionHours hrs',
                color: Colors.orange,
                icon: Icons.hourglass_full_outlined,
                theme: theme,
                isDark: isDark,
              ),
            ]),
          ),
          if (_permissions.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState('No short permissions applied during this period.'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _permissions[index];
                  final date = _formatDateForDisplay(item['date']);
                  final startTime = item['start_time'] ?? '00:00';
                  final endTime = item['end_time'] ?? '00:00';
                  final hours = item['total_hours']?.toString() ?? '0';
                  final reason = item['reason'] ?? 'No reason provided';
                  final status = item['status'] ?? 'approved';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Short Permission Slip',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: theme.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                '$startTime - $endTime  ($hours Hours)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text(
                            'Reason: $reason',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _permissions.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceReportTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSummaryMetricsRow([
                  _buildMetricCard(
                    title: 'Present Days',
                    value: '$_presentDays',
                    color: Colors.green,
                    icon: Icons.done,
                    theme: theme,
                    isDark: isDark,
                  ),
                  _buildMetricCard(
                    title: 'Absent Days',
                    value: '$_absentDays',
                    color: Colors.red,
                    icon: Icons.close,
                    theme: theme,
                    isDark: isDark,
                  ),
                  _buildMetricCard(
                    title: 'Half Days',
                    value: '$_halfDays',
                    color: Colors.orange,
                    icon: Icons.star_half,
                    theme: theme,
                    isDark: isDark,
                  ),
                ]),
                _buildSummaryMetricsRow([
                  _buildMetricCard(
                    title: 'Late Arrivals',
                    value: '$_lateArrivals',
                    color: Colors.purple,
                    icon: Icons.alarm_on,
                    theme: theme,
                    isDark: isDark,
                  ),
                  _buildMetricCard(
                    title: 'Leave/Holidays',
                    value: '$_holidayDays',
                    color: Colors.blue,
                    icon: Icons.event,
                    theme: theme,
                    isDark: isDark,
                  ),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Status:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF374151) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedAttendanceStatus,
                          underline: const SizedBox(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                            DropdownMenuItem(value: 'present', child: Text('Present')),
                            DropdownMenuItem(value: 'absent', child: Text('Absent')),
                            DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
                            DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                            DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedAttendanceStatus = val;
                              });
                              _fetchData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_attendance.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState('No attendance records found for this criteria.'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _attendance[index];
                  final date = _formatDateForDisplay(item['date']);
                  final clockIn = item['clock_in'] ?? '---';
                  final clockOut = item['clock_out'] ?? '---';
                  final totalHours = item['total_hours']?.toString() ?? '0';
                  final status = item['status'] ?? 'absent';
                  final isLate = item['is_late'] == true;
                  final notes = item['notes'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CLOCK IN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.login, size: 14, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Text(
                                          clockIn,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CLOCK OUT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.logout, size: 14, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(
                                          clockOut,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL WORK',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer, size: 14, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$totalHours hrs',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isLate || notes.isNotEmpty) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                if (isLate) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.warning, size: 12, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text(
                                          'LATE ARRIVAL',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (notes.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      notes,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                childCount: _attendance.length,
              ),
            ),
        ],
      ),
    );
  }
}
