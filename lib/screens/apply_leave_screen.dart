import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedTypeId;
  List<dynamic> _leaveTypes = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedDuration = 'full_day';
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final types = await auth.apiService.getLeaveTypes();
    if (mounted) {
      setState(() {
        _leaveTypes = types;
        _isLoading = false;
        if (types.isNotEmpty) {
          _selectedTypeId = types[0]['id'];
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type')),
      );
      return;
    }

    if (_selectedDuration != 'full_day') {
      _endDate = _startDate;
    }

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.apiService.applyLeave({
      'leave_type_id': _selectedTypeId,
      'start_date': _startDate!.toIso8601String().split('T')[0],
      'end_date': _endDate!.toIso8601String().split('T')[0],
      'leave_duration': _selectedDuration,
      'reason': _reasonController.text,
    });

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave application submitted successfully')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit application')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final firstDate = isStart ? DateTime.now().subtract(const Duration(days: 30)) : (_startDate ?? DateTime.now().subtract(const Duration(days: 30)));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_selectedDuration != 'full_day') {
            _endDate = picked;
          } else if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    DropdownButtonFormField<int>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Leave Type'),
                    items: _leaveTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['id'] as int,
                        child: Text(type['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTypeId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    decoration: const InputDecoration(labelText: 'Leave Duration'),
                    items: const [
                      DropdownMenuItem(
                        value: 'full_day',
                        child: Text('Full Day'),
                      ),
                      DropdownMenuItem(
                        value: 'first_half',
                        child: Text('First Half'),
                      ),
                      DropdownMenuItem(
                        value: 'second_half',
                        child: Text('Second Half'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedDuration = val ?? 'full_day';
                        if (_selectedDuration != 'full_day' && _startDate != null) {
                          _endDate = _startDate;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'From Date'),
                            child: Text(
                              _startDate != null 
                                ? "${_startDate!.toLocal()}".split(' ')[0] 
                                : 'Select Date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectedDuration == 'full_day' 
                            ? () => _selectDate(context, false) 
                            : null,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'To Date',
                              enabled: _selectedDuration == 'full_day',
                            ),
                            child: Text(
                              _endDate != null 
                                ? "${_endDate!.toLocal()}".split(' ')[0] 
                                : 'Select Date',
                              style: TextStyle(
                                color: _selectedDuration == 'full_day' 
                                  ? null 
                                  : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter a reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Application'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
