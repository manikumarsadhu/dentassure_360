import 'package:flutter/material.dart';

import '../../models/company.dart';
import '../../services/firestore_service.dart';
import '../../widgets/office_timings_fields.dart';

class EditCompanyScreen extends StatefulWidget {
  final Company company;

  const EditCompanyScreen({super.key, required this.company});

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _adminNameController;
  late TextEditingController _adminEmailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  final List<String> _industries = [
    'General & Dental Healthcare',
    'Specialty Dental & Orthodontics',
    'Hospital & Clinical Network',
    'Medical Devices & Pharma',
    'Software & Tech Services',
    'Corporate & Financial Services',
    'Other Enterprise',
  ];

  final List<String> _statuses = ['ACTIVE', 'SUSPENDED'];

  late String _selectedIndustry;
  late String _selectedStatus;
  late OfficeTimingsValue _timings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameController = TextEditingController(text: c.name);
    _adminNameController = TextEditingController(text: c.adminName);
    _adminEmailController = TextEditingController(text: c.adminEmail);
    _phoneController = TextEditingController(text: c.phone);
    _addressController = TextEditingController(text: c.address);

    _selectedIndustry = _industries.contains(c.industry)
        ? c.industry
        : _industries.first;
    _selectedStatus = _statuses.contains(c.status) ? c.status : 'ACTIVE';
    _timings = OfficeTimingsValue(
      timezone: c.timezone,
      workDays: c.workDays,
      fullDayHours: c.fullDayHours,
      halfDayHours: c.halfDayHours,
      dayShift: c.dayShift,
      nightShift: c.nightShift,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = widget.company.copyWith(
        name: _nameController.text.trim(),
        adminName: _adminNameController.text.trim(),
        adminEmail: _adminEmailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        industry: _selectedIndustry,
        status: _selectedStatus,
        timezone: _timings.timezone,
        workDays: _timings.workDays,
        fullDayHours: _timings.fullDayHours,
        halfDayHours: _timings.halfDayHours,
        dayShift: _timings.dayShift,
        nightShift: _timings.nightShift,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateCompany(updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company details updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update company: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Organization'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _handleSave,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo.shade800,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Company ID Banner (Read-only)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tenant / Company ID (Immutable)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.company.id,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 1: Company Profile
              _SectionHeader(
                title: 'Company Information',
                icon: Icons.business_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Company / Organization Name *',
                  prefixIcon: Icon(Icons.apartment_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedIndustry,
                decoration: const InputDecoration(
                  labelText: 'Industry / Healthcare Domain',
                  prefixIcon: Icon(Icons.category_rounded),
                  border: OutlineInputBorder(),
                ),
                items: _industries.map((ind) {
                  return DropdownMenuItem(value: ind, child: Text(ind));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedIndustry = val);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Business Address / Clinic Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 2: Primary Administrator Details
              _SectionHeader(
                title: 'Assigned Primary Administrator',
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.indigo,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Admin Contact Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Admin Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              _SectionHeader(
                title: 'Office timings & hours',
                icon: Icons.schedule_rounded,
                color: Colors.teal,
              ),
              const SizedBox(height: 12),
              OfficeTimingsFields(
                value: _timings,
                onChanged: (next) => setState(() => _timings = next),
              ),
              const SizedBox(height: 24),

              // SECTION 3: Operational Status
              _SectionHeader(
                title: 'Operational Status',
                icon: Icons.shield_outlined,
                color: Colors.teal,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Tenant Status',
                  prefixIcon: Icon(Icons.toggle_on_rounded),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'ACTIVE',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('ACTIVE - Operational & Accessible'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'SUSPENDED',
                    child: Row(
                      children: [
                        Icon(
                          Icons.pause_circle_rounded,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('SUSPENDED - Temporarily Blocked'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _saving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save_rounded),
                label: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Organization Updates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
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
