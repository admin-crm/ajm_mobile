import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'payslips_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = await auth.apiService.getProfileData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(theme, isDark),
                    const SizedBox(height: 20),
                    _buildSectionTitle(theme, 'Employment Details'),
                    _buildEmploymentCard(theme, isDark),
                    const SizedBox(height: 20),
                    _buildSectionTitle(theme, 'Personal Information'),
                    _buildPersonalCard(theme, isDark),
                    const SizedBox(height: 20),
                    _buildSectionTitle(theme, 'Emergency Contacts'),
                    _buildEmergencyCard(theme, isDark),
                    const SizedBox(height: 20),
                    _buildSectionTitle(theme, 'Banking & Payment'),
                    _buildBankingCard(theme, isDark),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PayslipsScreen()),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('View My Payslips'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, bool isDark) {
    final user = _data['user'] ?? {};
    final employee = _data['employee'] ?? {};
    final name = user['name'] ?? 'Employee';
    final email = user['email'] ?? '---';
    final code = employee['employee_code'] ?? 'EMP---';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            code,
            style: TextStyle(
              fontSize: 14,
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentCard(ThemeData theme, bool isDark) {
    final employee = _data['employee'] ?? {};
    
    final branchName = employee['branch']?['name'] ?? '---';
    final deptName = employee['department']?['name'] ?? '---';
    final desigName = employee['designation']?['name'] ?? '---';
    final empType = employee['employment_type'] ?? '---';
    final joinDate = employee['date_of_joining'] != null 
        ? employee['date_of_joining'].toString().split('T')[0]
        : '---';

    return _buildCard(
      theme,
      isDark,
      [
        _buildInfoRow('Branch', branchName, Icons.business, theme),
        _buildInfoRow('Department', deptName, Icons.schema_outlined, theme),
        _buildInfoRow('Designation', desigName, Icons.badge_outlined, theme),
        _buildInfoRow('Employment Type', empType, Icons.work_history_outlined, theme),
        _buildInfoRow('Date of Joining', joinDate, Icons.calendar_month, theme),
      ],
    );
  }

  Widget _buildPersonalCard(ThemeData theme, bool isDark) {
    final employee = _data['employee'] ?? {};
    
    final phone = employee['phone'] ?? '---';
    final dob = employee['date_of_birth'] != null 
        ? employee['date_of_birth'].toString().split('T')[0]
        : '---';
    final gender = employee['gender'] != null 
        ? employee['gender'].toString().substring(0, 1).toUpperCase() + employee['gender'].toString().substring(1)
        : '---';
    final address = "${employee['address_line_1'] ?? ''} ${employee['address_line_2'] ?? ''}".trim();
    final addressStr = address.isNotEmpty ? address : '---';

    return _buildCard(
      theme,
      isDark,
      [
        _buildInfoRow('Mobile Number', phone, Icons.phone_android, theme),
        _buildInfoRow('Date of Birth', dob, Icons.cake_outlined, theme),
        _buildInfoRow('Gender', gender, Icons.face_outlined, theme),
        _buildInfoRow('Address', addressStr, Icons.home_outlined, theme),
      ],
    );
  }

  Widget _buildEmergencyCard(ThemeData theme, bool isDark) {
    final employee = _data['employee'] ?? {};
    
    final name = employee['emergency_contact_name'] ?? '---';
    final relation = employee['emergency_contact_relationship'] ?? '---';
    final number = employee['emergency_contact_number'] ?? '---';

    return _buildCard(
      theme,
      isDark,
      [
        _buildInfoRow('Contact Name', name, Icons.person_outline, theme),
        _buildInfoRow('Relationship', relation, Icons.family_restroom, theme),
        _buildInfoRow('Contact Number', number, Icons.phone, theme),
      ],
    );
  }

  Widget _buildBankingCard(ThemeData theme, bool isDark) {
    final employee = _data['employee'] ?? {};
    
    final bankName = employee['bank_name'] ?? '---';
    final holderName = employee['account_holder_name'] ?? '---';
    final accountNum = employee['account_number'] ?? '---';
    final swiftCode = employee['bank_identifier_code'] ?? '---';

    return _buildCard(
      theme,
      isDark,
      [
        _buildInfoRow('Bank Name', bankName, Icons.account_balance, theme),
        _buildInfoRow('Account Holder', holderName, Icons.person_pin, theme),
        _buildInfoRow('Account Number', accountNum, Icons.payment, theme),
        _buildInfoRow('SWIFT/BIC Code', swiftCode, Icons.language, theme),
      ],
    );
  }

  Widget _buildCard(ThemeData theme, bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.primaryColor.withOpacity(0.7)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
