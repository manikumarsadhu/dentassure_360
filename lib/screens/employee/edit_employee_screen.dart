import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  final UserProfile employee;

  const EditEmployeeScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _empIdController;
  late TextEditingController _designationController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _salaryController;

  final _firestoreService = FirestoreService();

  final List<String> _departments = [
    'Software Engineering',
    'Product & UI/UX',
    'DevOps & Cloud',
    'Quality Assurance (QA)',
    'IT Support & Security',
    'Client Success & Support',
    'Human Resources (HR)',
    'Finance & Operations',
    'Executive Administration',
  ];

  final List<String> _roles = [
    'EMPLOYEE',
    'TEAM_LEAD',
    'MANAGER',
    'HR',
    'COMPANY_ADMIN',
  ];

  final List<String> _statuses = [
    'ACTIVE',
    'SUSPENDED',
    'INACTIVE',
  ];

  late String _selectedDepartment;
  late String _selectedRole;
  late String _selectedStatus;
  late String _reportingManagerUid;
  late String _reportingManagerName;
  DateTime? _joiningDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameController = TextEditingController(text: emp.name);
    _phoneController = TextEditingController(text: emp.phone);
    _empIdController = TextEditingController(text: emp.employeeId);
    _designationController = TextEditingController(text: emp.designation);
    _avatarUrlController = TextEditingController(text: emp.avatarUrl);
    _salaryController = TextEditingController(
      text: emp.monthlySalary > 0 ? emp.monthlySalary.toStringAsFixed(0) : '',
    );

    _selectedDepartment = _departments.contains(emp.department)
        ? emp.department
        : _departments.first;
    _selectedRole = _roles.contains(emp.role) ? emp.role : 'EMPLOYEE';
    _selectedStatus = _statuses.contains(emp.status) ? emp.status : 'ACTIVE';
    _reportingManagerUid = emp.reportingManagerUid;
    _reportingManagerName = emp.reportingManagerName;
    _joiningDate = emp.joiningDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _empIdController.dispose();
    _designationController.dispose();
    _avatarUrlController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectJoiningDate() async {
    final initial = _joiningDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final updatedProfile = widget.employee.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        employeeId: _empIdController.text.trim(),
        department: _selectedDepartment,
        designation: _designationController.text.trim(),
        role: _selectedRole,
        status: _selectedStatus,
        avatarUrl: _avatarUrlController.text.trim(),
        reportingManagerUid: _reportingManagerUid,
        reportingManagerName: _reportingManagerName,
        monthlySalary: double.tryParse(_salaryController.text.trim()) ?? 0,
        joiningDate: _joiningDate,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateEmployee(updatedProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, updatedProfile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Employee'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Readonly Email Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.employee.email,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Fixed ID',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Employee ID & Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _empIdController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Employee ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Avatar URL
                TextFormField(
                  controller: _avatarUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Avatar Image URL (Optional)',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Department
                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  items: _departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDepartment = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Designation
                TextFormField(
                  controller: _designationController,
                  decoration: const InputDecoration(
                    labelText: 'Designation / Job Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter designation'
                      : null,
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Account Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  items: _statuses.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: s == 'ACTIVE'
                                ? Colors.green
                                : (s == 'SUSPENDED' ? Colors.red : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Text(s),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'System Access Role',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items: _roles.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRole = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<UserProfile>>(
                  stream: _firestoreService.streamCompanyEmployees(
                    widget.employee.companyId,
                  ),
                  builder: (context, snapshot) {
                    final managers = (snapshot.data ?? [])
                        .where((u) =>
                            u.uid != widget.employee.uid &&
                            (u.isManager ||
                                u.isTeamLead ||
                                u.isCompanyAdmin ||
                                u.isHR))
                        .toList();
                    final values = ['', ...managers.map((m) => m.uid)];
                    final current = values.contains(_reportingManagerUid)
                        ? _reportingManagerUid
                        : '';
                    return DropdownButtonFormField<String>(
                      initialValue: current,
                      decoration: const InputDecoration(
                        labelText: 'Reporting manager / team lead',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.supervisor_account_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('None'),
                        ),
                        ...managers.map(
                          (m) => DropdownMenuItem(
                            value: m.uid,
                            child: Text('${m.name} (${m.role})'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        final selected =
                            managers.where((m) => m.uid == val).firstOrNull;
                        setState(() {
                          _reportingManagerUid = val ?? '';
                          _reportingManagerName = selected?.name ?? '';
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly salary',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Joining Date Picker
                InkWell(
                  onTap: _selectJoiningDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Joining Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _joiningDate != null
                          ? '${_joiningDate!.year}-${_joiningDate!.month.toString().padLeft(2, '0')}-${_joiningDate!.day.toString().padLeft(2, '0')}'
                          : 'Not set',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveChanges,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Profile Changes',
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
