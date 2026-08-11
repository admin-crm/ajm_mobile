import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  int? _downloadingId;
  List<dynamic> _payslips = [];

  @override
  void initState() {
    super.initState();
    _fetchPayslips();
  }

  Future<void> _fetchPayslips() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = await auth.apiService.getPayslips();
      if (mounted) {
        setState(() {
          _payslips = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payslips: $e')),
        );
      }
    }
  }

  Future<void> _downloadPayslip(int id, String payslipNumber) async {
    setState(() {
      _isDownloading = true;
      _downloadingId = id;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.apiService.downloadPayslip(id, payslipNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payslip $payslipNumber downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download payslip: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingId = null;
        });
      }
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
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

  String _formatPeriod(dynamic startStr, dynamic endStr) {
    if (startStr == null || endStr == null) return 'N/A';
    try {
      final start = DateTime.parse(startStr.toString());
      final end = DateTime.parse(endStr.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      if (start.month == end.month && start.year == end.year) {
        return '${months[start.month - 1]} ${start.year}';
      }
      return '${months[start.month - 1]} ${start.year} - ${months[end.month - 1]} ${end.year}';
    } catch (_) {
      return '$startStr to $endStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payslips'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPayslips,
              child: _payslips.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _payslips.length,
                      itemBuilder: (context, index) {
                        final payslip = _payslips[index];
                        final payslipId = payslip['id'] as int;
                        final numStr = payslip['payslip_number']?.toString() ?? 'PS-N/A';
                        final period = _formatPeriod(payslip['pay_period_start'], payslip['pay_period_end']);
                        final payDate = _formatDate(payslip['pay_date']);
                        final netPay = double.tryParse(payslip['net_pay']?.toString() ?? '0.00') ?? 0.00;
                        final grossPay = double.tryParse(payslip['gross_pay']?.toString() ?? '0.00') ?? 0.00;
                        final deductions = double.tryParse(payslip['total_deductions']?.toString() ?? '0.00') ?? 0.00;
                        final status = payslip['status']?.toString() ?? 'generated';
                        final isThisDownloading = _isDownloading && _downloadingId == payslipId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      numStr,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.date_range_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Period: $period',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.payment_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pay Date: $payDate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSalaryDetail('Gross Pay', grossPay, isDark),
                                    _buildSalaryDetail('Deductions', deductions, isDark, isDeduction: true),
                                    _buildSalaryDetail('Net Pay', netPay, isDark, isNet: true, primaryColor: theme.primaryColor),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _isDownloading
                                      ? null
                                      : () => _downloadPayslip(payslipId, numStr),
                                  icon: isThisDownloading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.download_rounded),
                                  label: Text(isThisDownloading ? 'Downloading...' : 'Download Payslip PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildSalaryDetail(String label, double amount, bool isDark, {bool isDeduction = false, bool isNet = false, Color? primaryColor}) {
    Color amountColor = isDark ? Colors.white : Colors.black87;
    if (isDeduction && amount > 0) {
      amountColor = Colors.red;
    } else if (isNet) {
      amountColor = primaryColor ?? Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final lowerStatus = status.toLowerCase();
    Color badgeColor = Colors.grey;
    String label = status.toUpperCase();

    if (lowerStatus == 'downloaded' || lowerStatus == 'paid') {
      badgeColor = Colors.green;
    } else if (lowerStatus == 'generated' || lowerStatus == 'sent') {
      badgeColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No payslips generated yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
}
