import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import 'edit_employee_screen.dart';
import '../../widgets/profile_photo_viewer.dart';
import '../../widgets/user_avatar.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final UserProfile employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _firestoreService = FirestoreService();
  bool _togglingStatus = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleStatus(UserProfile emp) async {
    final bool isCurrentlyActive = emp.isActive;
    final String newStatus = isCurrentlyActive ? 'SUSPENDED' : 'ACTIVE';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isCurrentlyActive ? 'Suspend Employee?' : 'Activate Employee?',
        ),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to suspend ${emp.name}? They will be blocked from logging in until reactivated.'
              : 'Reactivate ${emp.name}? They will regain access to their portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isCurrentlyActive ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isCurrentlyActive ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _togglingStatus = true);

    try {
      await _firestoreService.toggleEmployeeStatus(
        uid: emp.uid,
        newStatus: newStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${emp.name} is now $newStatus.'),
          backgroundColor: newStatus == 'ACTIVE'
              ? Colors.green
              : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _togglingStatus = false);
      }
    }
  }

  Future<void> _deleteEmployee(UserProfile emp) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee Profile?'),
        content: Text(
          'Are you sure you want to permanently remove ${emp.name} from your company directory? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestoreService.deleteEmployee(emp.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee profile deleted successfully.'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.streamUserProfile(widget.employee.uid),
      initialData: widget.employee,
      builder: (context, snapshot) {
        final emp = snapshot.data ?? widget.employee;

        return Scaffold(
          appBar: AppBar(
            title: Text(emp.name.isNotEmpty ? emp.name : 'Employee Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditEmployeeScreen(employee: emp),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Profile',
                onPressed: () => _deleteEmployee(emp),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Banner Card
                Card(
                  elevation: 0,
                  color: emp.isActive
                      ? theme.colorScheme.primaryContainer
                      : Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        MouseRegion(
                          cursor: emp.avatarUrl.trim().isEmpty
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: emp.avatarUrl.trim().isEmpty
                                ? null
                                : () => ProfilePhotoViewer.open(
                                    context,
                                    avatarUrl: emp.avatarUrl,
                                    name: emp.name,
                                  ),
                            child: Tooltip(
                              message: emp.avatarUrl.trim().isEmpty
                                  ? 'No profile photo'
                                  : 'View photo',
                              child: UserAvatar(
                                avatarUrl: emp.avatarUrl,
                                name: emp.name,
                                radius: 36,
                                backgroundColor: emp.isActive
                                    ? theme.colorScheme.primary
                                    : Colors.red.shade700,
                                textColor: theme.colorScheme.onPrimary,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          emp.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emp.designation,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                emp.role,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: emp.isActive
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    emp.isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    emp.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Employment Details Section
                _SectionHeader(
                  title: 'Employment Details',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _DetailTile(
                        label: 'Employee ID',
                        value: emp.employeeId.isNotEmpty
                            ? emp.employeeId
                            : 'N/A',
                        icon: Icons.tag_rounded,
                      ),
                      const Divider(height: 1),
                      _DetailTile(
                        label: 'Department',
                        value: emp.department,
                        icon: Icons.apartment_rounded,
                      ),
                      const Divider(height: 1),
                      _DetailTile(
                        label: 'Designation',
                        value: emp.designation,
                        icon: Icons.work_outline_rounded,
                      ),
                      const Divider(height: 1),
                      _DetailTile(
                        label: 'Work mode',
                        value: emp.workMode,
                        icon: Icons.home_work_outlined,
                      ),
                      const Divider(height: 1),
                      _DetailTile(
                        label: 'Shift',
                        value: emp.shiftType,
                        icon: Icons.nights_stay_outlined,
                      ),
                      const Divider(height: 1),
                      _DetailTile(
                        label: 'Joining Date',
                        value: _formatDate(emp.joiningDate),
                        icon: Icons.calendar_month_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Contact Information
                _SectionHeader(
                  title: 'Contact Information',
                  icon: Icons.contact_phone_outlined,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text(
                          'Email Address',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        subtitle: Text(
                          emp.email,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: emp.email));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email copied to clipboard'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text(
                          'Phone Number',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        subtitle: Text(
                          emp.phone.isNotEmpty ? emp.phone : 'Not provided',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: emp.phone.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: emp.phone),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Phone copied to clipboard',
                                      ),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: emp.isActive
                                ? Colors.red.shade400
                                : Colors.green.shade600,
                          ),
                          foregroundColor: emp.isActive
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                        onPressed: _togglingStatus
                            ? null
                            : () => _toggleStatus(emp),
                        icon: Icon(
                          emp.isActive
                              ? Icons.block_flipped
                              : Icons.check_circle_outline,
                        ),
                        label: Text(
                          emp.isActive ? 'Suspend User' : 'Activate User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditEmployeeScreen(employee: emp),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(
                          'Edit Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}
