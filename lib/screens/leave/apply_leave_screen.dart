import 'package:flutter/material.dart';

import '../../models/leave_balance.dart';
import '../../models/leave_request.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final UserProfile employee;
  final LeaveBalance currentBalance;

  const ApplyLeaveScreen({
    super.key,
    required this.employee,
    required this.currentBalance,
  });

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _firestoreService = FirestoreService();

  final List<String> _leaveTypes = ['CASUAL', 'SICK', 'ANNUAL', 'UNPAID'];
  late String _selectedLeaveType;

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLeaveType = _leaveTypes.first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _calculatedDays {
    final diff = _endDate.difference(_startDate).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  int get _availableForSelectedType {
    switch (_selectedLeaveType.toUpperCase()) {
      case 'CASUAL':
        return widget.currentBalance.availableCasual;
      case 'SICK':
        return widget.currentBalance.availableSick;
      case 'ANNUAL':
        return widget.currentBalance.availableAnnual;
      case 'UNPAID':
        return 999;
      default:
        return 0;
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)), // allow recent sick leaves
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submitLeave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalDays = _calculatedDays;
    final available = _availableForSelectedType;

    if (_selectedLeaveType != 'UNPAID' && totalDays > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Requested $totalDays days exceeds your available $available days of $_selectedLeaveType leave.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final request = LeaveRequest(
        id: '',
        companyId: widget.employee.companyId,
        uid: widget.employee.uid,
        employeeId: widget.employee.employeeId,
        employeeName: widget.employee.name,
        department: widget.employee.department,
        leaveType: _selectedLeaveType,
        startDate: LeaveRequest.formatDateKey(_startDate),
        endDate: LeaveRequest.formatDateKey(_endDate),
        totalDays: totalDays,
        reason: _reasonController.text.trim(),
        status: 'PENDING',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.submitLeaveRequest(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted for approval!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit leave: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = _availableForSelectedType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Leave Type Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedLeaveType,
                  decoration: const InputDecoration(
                    labelText: 'Leave Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _leaveTypes.map((type) {
                    String label = type;
                    switch (type) {
                      case 'CASUAL':
                        label = 'Casual Leave (${widget.currentBalance.availableCasual} days available)';
                        break;
                      case 'SICK':
                        label = 'Sick Leave (${widget.currentBalance.availableSick} days available)';
                        break;
                      case 'ANNUAL':
                        label = 'Annual Leave (${widget.currentBalance.availableAnnual} days available)';
                        break;
                      case 'UNPAID':
                        label = 'Unpaid Leave (No limit)';
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Text(label, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLeaveType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Balance Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLeaveType == 'UNPAID'
                              ? 'Unpaid leave does not deduct from your paid quota.'
                              : 'You have $available days available for $_selectedLeaveType leave.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Date Range Picker Tile
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Leave Duration / Dates',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.date_range_outlined),
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${LeaveRequest.formatDateKey(_startDate)} to ${LeaveRequest.formatDateKey(_endDate)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_calculatedDays ${_calculatedDays == 1 ? "day" : "days"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Reason Input
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Leave',
                    hintText: 'Please state the reason for your time off request...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason for your leave';
                    }
                    if (value.trim().length < 5) {
                      return 'Reason should be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submitLeave,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Submit Leave Application',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
