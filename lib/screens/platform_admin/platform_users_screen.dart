import 'package:flutter/material.dart';

import '../../models/company.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/auth_error_handler.dart';
import '../../widgets/user_avatar.dart';
import '../employee/employee_detail_screen.dart';

class PlatformUsersScreen extends StatefulWidget {
  final UserProfile platformAdmin;

  const PlatformUsersScreen({
    super.key,
    required this.platformAdmin,
  });

  @override
  State<PlatformUsersScreen> createState() => _PlatformUsersScreenState();
}

class _PlatformUsersScreenState extends State<PlatformUsersScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'ALL';
  String _selectedStatus = 'ALL';
  String _selectedCompanyId = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserActionModal(UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      avatarUrl: user.avatarUrl,
                      name: user.name,
                      radius: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${user.designation} • ${user.companyName.isNotEmpty ? user.companyName : "Platform"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // View Full Details Action
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.person_pin_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('View Full Employee Record'),
                  subtitle: const Text('Access complete profile & employment info'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeDetailScreen(employee: user),
                      ),
                    );
                  },
                ),

                // Modify Role & Status Dialog
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E8FF),
                    child: Icon(Icons.admin_panel_settings_rounded, color: Colors.purple),
                  ),
                  title: const Text('Change Role & Operational Status'),
                  subtitle: Text('Current Role: ${user.role} • Status: ${user.status}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _showEditRoleDialog(user);
                  },
                ),

                // Send Reset Password Email
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(Icons.lock_reset_rounded, color: Colors.amber),
                  ),
                  title: const Text('Send Password Reset Email'),
                  subtitle: Text('Instructions sent to ${user.email}'),
                  onTap: () async {
                    Navigator.pop(modalCtx);
                    try {
                      await _authService.resetPassword(user.email);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password reset link sent to ${user.email}!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      final msg = AuthErrorHandler.getErrorMessage(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),

                // Toggle Quick Active / Suspend
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.isActive
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE8F5E9),
                    child: Icon(
                      user.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      color: user.isActive ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    user.isActive ? 'Suspend User Account' : 'Activate User Account',
                    style: TextStyle(
                      color: user.isActive ? Colors.red : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    user.isActive
                        ? 'Prevent user from logging into portal'
                        : 'Restore user access to the system',
                  ),
                  onTap: () async {
                    Navigator.pop(modalCtx);
                    final newStatus = user.isActive ? 'SUSPENDED' : 'ACTIVE';
                    await _firestoreService.toggleEmployeeStatus(
                      uid: user.uid,
                      newStatus: newStatus,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User account status updated to $newStatus.'),
                        backgroundColor:
                            user.isActive ? Colors.red.shade700 : Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditRoleDialog(UserProfile user) async {
    String selectedRole = user.role;
    String selectedStatus = user.status;
    final designationController = TextEditingController(text: user.designation);
    final departmentController = TextEditingController(text: user.department);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Manage ${user.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'System Access Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'EMPLOYEE', child: Text('EMPLOYEE')),
                        DropdownMenuItem(
                            value: 'MANAGER', child: Text('MANAGER')),
                        DropdownMenuItem(
                            value: 'TEAM_LEAD', child: Text('TEAM_LEAD')),
                        DropdownMenuItem(value: 'HR', child: Text('HR')),
                        DropdownMenuItem(
                            value: 'COMPANY_ADMIN',
                            child: Text('COMPANY_ADMIN')),
                        DropdownMenuItem(
                            value: 'PLATFORM_ADMIN',
                            child: Text('PLATFORM_ADMIN')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Account Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(
                            value: 'SUSPENDED', child: Text('SUSPENDED')),
                        DropdownMenuItem(
                            value: 'INACTIVE', child: Text('INACTIVE')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: designationController,
                      decoration: const InputDecoration(
                        labelText: 'Designation / Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          try {
                            await _firestoreService.updateUserRoleAndStatus(
                              uid: user.uid,
                              role: selectedRole,
                              status: selectedStatus,
                              designation: designationController.text.trim(),
                              department: departmentController.text.trim(),
                            );
                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User role & status updated!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (!dialogCtx.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Update failed: $e'),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Company>>(
      stream: _firestoreService.streamAllCompanies(),
      builder: (context, compSnapshot) {
        final companies = compSnapshot.data ?? [];

        return StreamBuilder<List<UserProfile>>(
          stream: _firestoreService.streamAllPlatformUsers(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final allUsers = userSnapshot.data ?? [];

            // Filtering
            final filteredUsers = allUsers.where((u) {
              final query = _searchQuery.toLowerCase();
              final matchesSearch = query.isEmpty ||
                  u.name.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query) ||
                  u.employeeId.toLowerCase().contains(query) ||
                  u.companyName.toLowerCase().contains(query) ||
                  u.department.toLowerCase().contains(query);

              final matchesRole = _selectedRole == 'ALL' ||
                  u.role.toUpperCase() == _selectedRole.toUpperCase();

              final matchesStatus = _selectedStatus == 'ALL' ||
                  u.status.toUpperCase() == _selectedStatus.toUpperCase();

              final matchesCompany = _selectedCompanyId == 'ALL' ||
                  u.companyId == _selectedCompanyId;

              return matchesSearch &&
                  matchesRole &&
                  matchesStatus &&
                  matchesCompany;
            }).toList();

            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global User Directory',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${filteredUsers.length} of ${allUsers.length} total users',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: () => setState(() {}),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Search Box
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by user name, email, org, role...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                    ),
                  ),

                  // Company selector dropdown (if multi-company)
                  if (companies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCompanyId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Filter by Organization',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'ALL',
                            child: Text('All Organizations (Global)'),
                          ),
                          ...companies.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCompanyId = val);
                          }
                        },
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Role Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Roles', _selectedRole,
                            (v) => setState(() => _selectedRole = v)),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                            'PLATFORM_ADMIN',
                            'Platform Admins',
                            _selectedRole,
                            (v) => setState(() => _selectedRole = v)),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                            'COMPANY_ADMIN',
                            'Company Admins',
                            _selectedRole,
                            (v) => setState(() => _selectedRole = v)),
                        const SizedBox(width: 6),
                        _buildFilterChip('MANAGER', 'Managers', _selectedRole,
                            (v) => setState(() => _selectedRole = v)),
                        const SizedBox(width: 6),
                        _buildFilterChip('TEAM_LEAD', 'Team Leads', _selectedRole,
                            (v) => setState(() => _selectedRole = v)),
                        const SizedBox(width: 6),
                        _buildFilterChip('HR', 'HR', _selectedRole,
                            (v) => setState(() => _selectedRole = v)),
                        const SizedBox(width: 6),
                        _buildFilterChip('EMPLOYEE', 'Employees', _selectedRole,
                            (v) => setState(() => _selectedRole = v)),
                      ],
                    ),
                  ),

                  const Divider(height: 12),

                  // User List
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_rounded,
                                    size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No users found matching your filters.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedRole = 'ALL';
                                      _selectedStatus = 'ALL';
                                      _selectedCompanyId = 'ALL';
                                    });
                                  },
                                  child: const Text('Reset All Filters'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return _GlobalUserCard(
                                user: user,
                                onTap: () => _showUserActionModal(user),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, String currentVal,
      Function(String) onSelected) {
    final isSelected = currentVal == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _GlobalUserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _GlobalUserCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color roleBg = Colors.blue.shade50;
    Color roleText = Colors.blue.shade800;
    if (user.isPlatformAdmin) {
      roleBg = Colors.amber.shade100;
      roleText = Colors.amber.shade900;
    } else if (user.isCompanyAdmin) {
      roleBg = Colors.indigo.shade100;
      roleText = Colors.indigo.shade800;
    } else if (user.isManager) {
      roleBg = Colors.teal.shade100;
      roleText = Colors.teal.shade800;
    } else if (user.isTeamLead) {
      roleBg = Colors.orange.shade100;
      roleText = Colors.orange.shade800;
    } else if (user.isHR) {
      roleBg = Colors.purple.shade100;
      roleText = Colors.purple.shade800;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: user.avatarUrl,
                name: user.name,
                radius: 24,
                backgroundColor: user.isActive
                    ? Colors.blue.shade50
                    : Colors.red.shade100,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: roleText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.companyName.isNotEmpty
                          ? '${user.companyName} • ${user.designation}'
                          : 'Platform Console • ${user.designation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: user.isActive
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      user.status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: user.isActive
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.more_horiz_rounded, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
