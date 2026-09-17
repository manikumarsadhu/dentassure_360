import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/auth_error_handler.dart';
import '../../widgets/office_timings_fields.dart';

class CreateCompanyScreen extends StatefulWidget {
  final UserProfile platformAdmin;

  const CreateCompanyScreen({
    super.key,
    required this.platformAdmin,
  });

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _customCompanyIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _designationController =
      TextEditingController(text: 'Organization Administrator');
  final _passwordController = TextEditingController();

  final List<String> _industries = [
    'General & Dental Healthcare',
    'Specialty Dental & Orthodontics',
    'Hospital & Clinical Network',
    'Medical Devices & Pharma',
    'Software & Tech Services',
    'Corporate & Financial Services',
    'Other Enterprise',
  ];

  late String _selectedIndustry;
  OfficeTimingsValue _timings = const OfficeTimingsValue();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedIndustry = _industries.first;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _customCompanyIdController.dispose();
    _addressController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createCompanyAndAdmin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _adminEmailController.text.trim();
      final password = _passwordController.text;
      final companyName = _companyNameController.text.trim();
      final adminName = _adminNameController.text.trim();
      final customId = _customCompanyIdController.text.trim();

      debugPrint(
        '[CreateCompany] Step 1: Provisioning Auth account for Company Admin $email',
      );

      // 1. Create Auth account for the Company Admin via secondary Firebase app
      final credential = await _authService
          .createCompanyAdminAuthAccount(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Authentication timed out while provisioning Company Admin auth account.',
            ),
          );

      final adminUser = credential.user;
      if (adminUser == null) {
        throw Exception(
          'Failed to generate Company Admin authentication identity.',
        );
      }

      debugPrint(
        '[CreateCompany] Step 2: Saving Company & Admin Profile in Firestore (UID: ${adminUser.uid})',
      );

      // 2. Create Company document and Admin User Profile atomically in Firestore
      final companyId = await _firestoreService
          .createCompany(
            companyName: companyName,
            adminUid: adminUser.uid,
            adminName: adminName,
            adminEmail: email,
            adminPhone: _adminPhoneController.text.trim(),
            address: _addressController.text.trim(),
            industry: _selectedIndustry,
            explicitCompanyId: customId.isNotEmpty ? customId : null,
            createdByUid: widget.platformAdmin.uid,
            designation: _designationController.text.trim(),
            timezone: _timings.timezone,
            workDays: _timings.workDays,
            fullDayHours: _timings.fullDayHours,
            halfDayHours: _timings.halfDayHours,
            dayShift: _timings.dayShift,
            nightShift: _timings.nightShift,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Database request timed out while creating company in Firestore.',
            ),
          );

      debugPrint('[CreateCompany] Company created successfully! ID: $companyId');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Company "$companyName" and Administrator $adminName created successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('[CreateCompany] Error: $e\n$stackTrace');
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
        title: const Text('Create Company & Admin'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tenant Onboarding',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set up a new organization and assign a dedicated Company Administrator.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
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
                  const SizedBox(height: 20),
                ],

                // SECTION 1: Company Details
                _SectionHeader(
                  icon: Icons.apartment_rounded,
                  title: '1. Organization Details',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),

                // Company Name
                TextFormField(
                  controller: _companyNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    hintText: 'e.g. Apex Software / Dentassure Tech',
                    prefixIcon: Icon(Icons.corporate_fare_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the company name';
                    }
                    if (value.trim().length < 2) {
                      return 'Company name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Industry Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedIndustry,
                  decoration: const InputDecoration(
                    labelText: 'Industry / Domain',
                    prefixIcon: Icon(Icons.category_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: _industries.map((ind) {
                    return DropdownMenuItem(
                      value: ind,
                      child: Text(ind),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIndustry = val);
                  },
                ),
                const SizedBox(height: 14),

                // Business Address
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Business Address (Optional)',
                    hintText: 'e.g. 101 Medical Center Blvd, Suite 400',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Custom Company ID (Optional)
                TextFormField(
                  controller: _customCompanyIdController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Custom Company ID (Optional)',
                    hintText: 'e.g. APEX_CORP (leave blank to auto-generate)',
                    prefixIcon: Icon(Icons.tag_rounded),
                    border: OutlineInputBorder(),
                    helperText: 'Unique tenant key in the database',
                  ),
                ),
                const SizedBox(height: 28),

                _SectionHeader(
                  icon: Icons.schedule_rounded,
                  title: '2. Office timings & hours',
                  color: Colors.teal.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  'Default day shift is 09:30–18:30. Late uses start + grace. Half-day if worked hours are below the threshold. Night staff use the night template.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                OfficeTimingsFields(
                  value: _timings,
                  onChanged: (next) => setState(() => _timings = next),
                ),
                const SizedBox(height: 28),

                // SECTION 3: Company Admin Credentials
                _SectionHeader(
                  icon: Icons.admin_panel_settings_rounded,
                  title: '3. Company Administrator Account',
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),

                // Admin Name
                TextFormField(
                  controller: _adminNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Admin Full Name *',
                    hintText: 'e.g. Sarah Connor',
                    prefixIcon: Icon(Icons.person_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter admin name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Admin Email
                TextFormField(
                  controller: _adminEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Admin Work Email *',
                    hintText: 'admin@apexcorp.com',
                    prefixIcon: Icon(Icons.email_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter admin email';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Temporary Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Initial Password *',
                    helperText:
                        'Company Admin will use this password to sign in and manage their company',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
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
                      return 'Please set a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Contact Phone
                TextFormField(
                  controller: _adminPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Admin Phone Number (Optional)',
                    hintText: '+1 555-0199',
                    prefixIcon: Icon(Icons.phone_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Designation
                TextFormField(
                  controller: _designationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Designation / Title',
                    hintText: 'Organization Administrator',
                    prefixIcon: Icon(Icons.badge_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _createCompanyAndAdmin,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_business_rounded),
                    label: Text(
                      _loading
                          ? 'Provisioning Company & Admin...'
                          : 'Create Company & Admin Account',
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
