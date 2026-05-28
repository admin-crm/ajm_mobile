import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ApplyPermissionScreen extends StatefulWidget {
  const ApplyPermissionScreen({super.key});

  @override
  State<ApplyPermissionScreen> createState() => _ApplyPermissionScreenState();
}

class _ApplyPermissionScreenState extends State<ApplyPermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonController = TextEditingController();
  
  bool _isSubmitting = false;
  double _calculatedDuration = 0.0;

  void _calculateDuration() {
    if (_startTime != null && _endTime != null) {
      final startMin = _startTime!.hour * 60 + _startTime!.minute;
      final endMin = _endTime!.hour * 60 + _endTime!.minute;
      
      int diffMin = endMin - startMin;
      if (diffMin < 0) {
        // Handle wrap-around for overnight, though usually short permission is same day
        diffMin += 24 * 60;
      }
      
      setState(() {
        _calculatedDuration = double.parse((diffMin / 60.0).toStringAsFixed(2));
      });
    } else {
      setState(() {
        _calculatedDuration = 0.0;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart 
          ? (_startTime ?? TimeOfDay.now()) 
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _calculateDuration();
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatTimeOfDayForDisplay(TimeOfDay tod) {
    final hourVal = tod.hour;
    final minVal = tod.minute.toString().padLeft(2, '0');
    final period = hourVal >= 12 ? 'PM' : 'AM';
    int h = hourVal > 12 ? hourVal - 12 : hourVal;
    if (h == 0) h = 12;
    return '$h:$minVal $period';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }

    // Validate end time is after start time
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be strictly after start time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final startTimeStr = _formatTimeOfDay(_startTime!);
    final endTimeStr = _formatTimeOfDay(_endTime!);

    final success = await auth.apiService.applyShortPermission({
      'date': dateStr,
      'start_time': startTimeStr,
      'end_time': endTimeStr,
      'reason': _reasonController.text,
    });

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Short permission applied and approved successfully!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit permission request')),
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Short Permission'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Permission Request Slip',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Short-duration permissions are automatically approved upon submission.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),
                  
                  // Date Field
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Permission Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _selectedDate != null 
                          ? "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}"
                          : 'Select Date',
                        style: TextStyle(
                          color: _selectedDate != null ? null : theme.disabledColor,
                          fontWeight: _selectedDate != null ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Time Fields Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, true),
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              prefixIcon: Icon(Icons.login_outlined),
                            ),
                            child: Text(
                              _startTime != null 
                                ? _formatTimeOfDayForDisplay(_startTime!) 
                                : 'Select Start',
                              style: TextStyle(
                                color: _startTime != null ? null : theme.disabledColor,
                                fontWeight: _startTime != null ? FontWeight.w500 : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, false),
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              prefixIcon: Icon(Icons.logout_outlined),
                            ),
                            child: Text(
                              _endTime != null 
                                ? _formatTimeOfDayForDisplay(_endTime!) 
                                : 'Select End',
                              style: TextStyle(
                                color: _endTime != null ? null : theme.disabledColor,
                                fontWeight: _endTime != null ? FontWeight.w500 : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Calculated Duration Display
                  if (_calculatedDuration > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.av_timer, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Total Duration:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '$_calculatedDuration Hours',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  // Reason Field
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Permission',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 50.0),
                        child: Icon(Icons.info_outline),
                      ),
                    ),
                    maxLines: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide a reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Apply & Approve Slip',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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
