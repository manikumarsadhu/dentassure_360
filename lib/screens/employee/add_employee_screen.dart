import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/auth_error_handler.dart';

class AddEmployeeScreen extends StatefulWidget {
  final UserProfile adminProfile;

  const AddEmployeeScreen({
    super.key,
    required this.adminProfile,
  });

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _empIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _designationController = TextEditingController();

  final _authService = AuthService();
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
  ];

  late String _selectedDepartment;
  late String _selectedRole;
  String _reportingManagerUid = '';
  String _reportingManagerName = '';
  final _salaryController = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDepartment = _departments.first;
    _selectedRole = _roles.first;
    _suggestEmployeeId();
  }

  Future<void> _suggestEmployeeId() async {
    try {
      final suggested = await _firestoreService.generateNextEmployeeId(
        widget.adminProfile.companyId,
      );
      if (mounted && _empIdController.text.isEmpty) {
        setState(() {
          _empIdController.text = suggested;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _empIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _designationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _joiningDate) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  Future<void> _createEmployee() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[AddEmployee] Step 1: Creating Auth user for employee ${_emailController.text.trim()}');
      final uid = await _authService
          .createAuthUserUid(
            email: _emailController.text,
            password: _passwordController.text,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Authentication timed out while creating employee auth account.',
            ),
          );

      final employeeProfile = UserProfile(
        uid: uid,
        companyId: widget.adminProfile.companyId,
        companyName: widget.adminProfile.companyName,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        employeeId: _empIdController.text.trim(),
        department: _selectedDepartment,
        designation: _designationController.text.trim().isNotEmpty
            ? _designationController.text.trim()
            : 'Staff',
        role: _selectedRole,
        status: 'ACTIVE',
        reportingManagerUid: _reportingManagerUid,
        reportingManagerName: _reportingManagerName,
        monthlySalary: double.tryParse(_salaryController.text.trim()) ?? 0,
        joiningDate: _joiningDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('[AddEmployee] Step 2: Saving employee profile in Firestore (UID: $uid)');
      // 3. Save profile under /users/{uid} in Firestore
      await _firestoreService
          .addEmployee(employeeProfile)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Database timed out while saving employee profile.',
            ),
          );

      debugPrint('[AddEmployee] Employee created successfully!');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Employee ${employeeProfile.name} created successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('[AddEmployee] Error: $e\n$stackTrace');
      if (!mounted) return;
      final msg = AuthErrorHandler.getErrorMessage(e);
      setState(() {
        _errorMessage = msg;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Employee'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Employee Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a new team member under ${widget.adminProfile.companyName.isNotEmpty ? widget.adminProfile.companyName : "your organization"}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Row for Employee ID and Full Name
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
                          hintText: 'EMP-001',
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
                          hintText: 'e.g. Sarah Jenkins',
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

                // Email Address
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Work Email Address',
                    hintText: 'sarah.jenkins@company.io',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Temporary Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
                    helperText: 'Employee will use this password for initial login',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please assign a temporary password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone Number',
                    hintText: '+1 555-0199',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Department Dropdown
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
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Job Designation / Title',
                    hintText: 'e.g. Senior Software Engineer / Product Manager',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter job title'
                      : null,
                ),
                const SizedBox(height: 16),

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
                    widget.adminProfile.companyId,
                  ),
                  builder: (context, snapshot) {
                    final managers = (snapshot.data ?? [])
                        .where((u) =>
                            u.isManager ||
                            u.isTeamLead ||
                            u.isCompanyAdmin ||
                            u.isHR)
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
                        final selected = managers
                            .where((m) => m.uid == val)
                            .firstOrNull;
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
                    labelText: 'Monthly salary (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Joining Date Picker Tile
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
                      '${_joiningDate.year}-${_joiningDate.month.toString().padLeft(2, '0')}-${_joiningDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _createEmployee,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(
                      _loading ? 'Provisioning Account...' : 'Create Employee Profile',
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
