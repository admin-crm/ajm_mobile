import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'apply_leave_screen.dart';

class LeaveDashboardScreen extends StatefulWidget {
  const LeaveDashboardScreen({super.key});

  @override
  State<LeaveDashboardScreen> createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _applications = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Try to fetch applications
      final data = await auth.apiService.getLeaveApplications();
      if (mounted) {
        setState(() {
          _applications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leave data: $e')),
        );
      }
    }
  }

  void _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
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
                    _buildBalanceCards(theme),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Applications',
                          style: theme.textTheme.titleLarge,
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApplyLeaveScreen(),
                              ),
                            );
                            if (result == true) {
                              _fetchData();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Apply Leave'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildApplicationsList(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCards(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildCard('Available', '12', Colors.blue, theme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard('Used', '3', Colors.orange, theme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard('Remaining', '9', Colors.green, theme),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, Color color, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList(ThemeData theme) {
    if (_applications.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No leave applications found.'),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _applications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final app = _applications[index];
        final type = app['leave_type'] ?? 'Casual Leave';
        final status = app['status'] ?? 'Pending';
        final fromDate = app['start_date'] ?? 'N/A';
        final toDate = app['end_date'] ?? 'N/A';

        Color statusColor = Colors.orange;
        if (status.toString().toLowerCase() == 'approved') {
          statusColor = Colors.green;
        } else if (status.toString().toLowerCase() == 'rejected') {
          statusColor = Colors.red;
        }

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              type,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('$fromDate to $toDate'),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
