import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'apply_permission_screen.dart';

class PermissionDashboardScreen extends StatefulWidget {
  const PermissionDashboardScreen({super.key});

  @override
  State<PermissionDashboardScreen> createState() => _PermissionDashboardScreenState();
}

class _PermissionDashboardScreenState extends State<PermissionDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _permissions = [];
  double _totalHoursThisMonth = 0.0;
  int _totalPermissionsThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = await auth.apiService.getShortPermissions();
      
      // Calculate monthly stats
      double hours = 0.0;
      int count = 0;
      final now = DateTime.now();

      for (var item in data) {
        if (item['date'] != null) {
          try {
            final date = DateTime.parse(item['date'].toString());
            if (date.month == now.month && date.year == now.year) {
              count++;
              if (item['total_hours'] != null) {
                hours += double.tryParse(item['total_hours'].toString()) ?? 0.0;
              }
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _permissions = data;
          _totalHoursThisMonth = hours;
          _totalPermissionsThisMonth = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading short permissions: $e')),
        );
      }
    }
  }

  Future<void> _cancelPermission(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Permission'),
        content: const Text('Are you sure you want to cancel this permission slip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final success = await auth.apiService.cancelShortPermission(id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission slip cancelled successfully')),
            );
          }
          _fetchData();
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to cancel permission slip')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Short Permission Module'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsBanner(theme, isDark),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Permission Slips',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApplyPermissionScreen(),
                              ),
                            );
                            if (result == true) {
                              _fetchData();
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Apply'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionsList(theme, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [theme.cardColor, theme.cardColor.withOpacity(0.8)]
              : [theme.primaryColor.withOpacity(0.05), theme.primaryColor.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Permissions Count',
            '$_totalPermissionsThisMonth',
            Icons.vpn_key_outlined,
            theme.primaryColor,
            theme,
          ),
          Container(
            height: 50,
            width: 1,
            color: theme.dividerColor.withOpacity(0.3),
          ),
          _buildStatItem(
            'Hours Taken',
            '${_totalHoursThisMonth.toStringAsFixed(1)} hrs',
            Icons.access_time,
            Colors.orange,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.disabledColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsList(ThemeData theme, bool isDark) {
    if (_permissions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_toggle_off,
                size: 64,
                color: theme.disabledColor.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No permissions applied yet.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Once you apply for short permission, it will be automatically approved and listed here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _permissions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final perm = _permissions[index];
        final id = perm['id'] as int? ?? 0;
        final dateStr = perm['date'] ?? 'N/A';
        final startTimeStr = perm['start_time'] ?? 'N/A';
        final endTimeStr = perm['end_time'] ?? 'N/A';
        final totalHours = perm['total_hours']?.toString() ?? '0.00';
        final reason = perm['reason'] ?? '';
        final status = perm['status'] ?? 'approved';

        // Format Date
        String formattedDate = dateStr;
        try {
          final parsedDate = DateTime.parse(dateStr.toString());
          final day = parsedDate.day.toString().padLeft(2, '0');
          final month = parsedDate.month.toString().padLeft(2, '0');
          final year = parsedDate.year.toString();
          formattedDate = '$day/$month/$year';
        } catch (_) {}

        // Format times nicely (H:i:s -> AM/PM)
        String formatTimeStr(String rawTime) {
          if (rawTime == 'N/A') return 'N/A';
          try {
            final parts = rawTime.split(':');
            if (parts.length >= 2) {
              int hour = int.parse(parts[0]);
              int minute = int.parse(parts[1]);
              final period = hour >= 12 ? 'PM' : 'AM';
              if (hour > 12) hour -= 12;
              if (hour == 0) hour = 12;
              final minStr = minute.toString().padLeft(2, '0');
              return '$hour:$minStr $period';
            }
          } catch (_) {}
          return rawTime;
        }

        final timeDisplay = '${formatTimeStr(startTimeStr)} - ${formatTimeStr(endTimeStr)}';

        // Colors
        Color statusColor = Colors.green;
        if (status.toString().toLowerCase() == 'pending') {
          statusColor = Colors.orange;
        } else if (status.toString().toLowerCase() == 'rejected') {
          statusColor = Colors.red;
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time_outlined,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeDisplay,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.disabledColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reason,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Duration',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalHours hrs',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Show cancel option for active slips
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _cancelPermission(id),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Cancel Slip'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
