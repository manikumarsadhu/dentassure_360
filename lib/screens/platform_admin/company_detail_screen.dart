import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/attendance.dart';
import '../../models/company.dart';
import '../../models/leave_request.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../widgets/user_avatar.dart';
import '../employee/add_employee_screen.dart';
import '../employee/employee_detail_screen.dart';
import 'edit_company_screen.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Company company;
  final UserProfile platformAdmin;

  const CompanyDetailScreen({
    super.key,
    required this.company,
    required this.platformAdmin,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late TabController _tabController;

  String _userSearchQuery = '';
  String _selectedRoleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleStatus(Company comp) async {
    final isCurrentlyActive = comp.isActive;
    final targetStatus = isCurrentlyActive ? 'SUSPENDED' : 'ACTIVE';
    final actionText = isCurrentlyActive ? 'Suspend' : 'Activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText "${comp.name}"?'),
        content: Text(
          isCurrentlyActive
              ? 'Suspending this tenant will temporarily restrict its employees and administrators from accessing standard workspaces.'
              : 'Activating this tenant will restore full access for all associated employees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isCurrentlyActive ? Colors.red.shade700 : Colors.green.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.toggleCompanyStatus(
          companyId: comp.id,
          newStatus: targetStatus,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company marked as $targetStatus!'),
            backgroundColor:
                isCurrentlyActive ? Colors.orange.shade800 : Colors.green,
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
      }
    }
  }

  Future<void> _deleteCompany(Company comp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Organization'),
        content: Text(
          'Are you sure you want to delete "${comp.name}"? This will remove the company registration document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteCompany(comp.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company deleted successfully.'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete company: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openAddUser(Company comp) {
    // Create a temporary Company Admin proxy profile for the AddEmployeeScreen
    final adminProxy = UserProfile(
      uid: widget.platformAdmin.uid,
      companyId: comp.id,
      companyName: comp.name,
      name: comp.adminName.isNotEmpty ? comp.adminName : widget.platformAdmin.name,
      email: comp.adminEmail.isNotEmpty ? comp.adminEmail : widget.platformAdmin.email,
      role: 'PLATFORM_ADMIN',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEmployeeScreen(adminProfile: adminProxy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayKey = Attendance.formatDateKey(DateTime.now());

    return StreamBuilder<Company?>(
      stream: _firestoreService.streamCompanyById(widget.company.id),
      initialData: widget.company,
      builder: (context, snapshot) {
        final comp = snapshot.data ?? widget.company;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              comp.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Organization',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditCompanyScreen(company: comp),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  comp.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: comp.isActive ? Colors.orange : Colors.green,
                ),
                tooltip: comp.isActive ? 'Suspend Company' : 'Activate Company',
                onPressed: () => _toggleStatus(comp),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete') _deleteCompany(comp);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Company', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline_rounded), text: 'Overview'),
                Tab(icon: Icon(Icons.people_alt_outlined), text: 'Staff Directory'),
                Tab(icon: Icon(Icons.access_time_rounded), text: 'Attendance'),
                Tab(icon: Icon(Icons.event_note_rounded), text: 'Leaves'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddUser(comp),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add User to Tenant'),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(comp, todayKey),
              _buildUsersTab(comp),
              _buildAttendanceTab(comp, todayKey),
              _buildLeavesTab(comp),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(Company comp, String todayKey) {
    return StreamBuilder<List<UserProfile>>(
      stream: _firestoreService.streamCompanyUsers(comp.id),
      builder: (context, usersSnapshot) {
        final users = usersSnapshot.data ?? [];
        final admins = users.where((u) => u.isCompanyAdmin).length;
        final employees = users.where((u) => u.isEmployee).length;
        final managers = users.where((u) => u.isManager).length;
        final teamLeads = users.where((u) => u.isTeamLead).length;
        final hrs = users.where((u) => u.isHR).length;
        final activeUsers = users.where((u) => u.isActive).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Company Hero Banner
              Card(
                elevation: 0,
                color: comp.isActive
                    ? Colors.indigo.shade900
                    : Colors.red.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            child: const Icon(
                              Icons.apartment_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comp.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comp.industry,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.indigo.shade100,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: comp.isActive
                                        ? Colors.green.shade600
                                        : Colors.amber.shade800,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    comp.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
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
              const SizedBox(height: 16),

              // Metric Summary Grid
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      title: 'Total Users',
                      value: '${users.length}',
                      icon: Icons.groups_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      title: 'Active Users',
                      value: '$activeUsers',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      title: 'Admins',
                      value: '$admins',
                      icon: Icons.admin_panel_settings_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Organization Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.fingerprint_rounded),
                        title: const Text('Tenant ID'),
                        subtitle: Text(comp.id),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Copy ID',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: comp.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Company ID copied!'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.person_rounded),
                        title: const Text('Primary Administrator'),
                        subtitle: Text(
                          comp.adminName.isNotEmpty
                              ? comp.adminName
                              : 'Not assigned',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Admin Email'),
                        subtitle: Text(
                          comp.adminEmail.isNotEmpty
                              ? comp.adminEmail
                              : 'Not assigned',
                        ),
                      ),
                      if (comp.phone.isNotEmpty) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text('Contact Phone'),
                          subtitle: Text(comp.phone),
                        ),
                      ],
                      if (comp.address.isNotEmpty) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Business Address'),
                          subtitle: Text(comp.address),
                        ),
                      ],
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Registered Date'),
                        subtitle: Text(_formatDate(comp.createdAt)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Staff Role Breakdown Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team Composition',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RolePill(label: 'Admins', count: admins, color: Colors.indigo),
                          _RolePill(label: 'Managers', count: managers, color: Colors.teal),
                          _RolePill(label: 'Team Leads', count: teamLeads, color: Colors.orange),
                          _RolePill(label: 'HR', count: hrs, color: Colors.purple),
                          _RolePill(label: 'Staff', count: employees, color: Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: USERS & STAFF DIRECTORY
  // ==========================================
  Widget _buildUsersTab(Company comp) {
    return StreamBuilder<List<UserProfile>>(
      stream: _firestoreService.streamCompanyUsers(comp.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data ?? [];
        final filteredUsers = allUsers.where((u) {
          final matchesSearch = _userSearchQuery.isEmpty ||
              u.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
              u.email.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
              u.employeeId.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
              u.department.toLowerCase().contains(_userSearchQuery.toLowerCase());

          final matchesRole = _selectedRoleFilter == 'ALL' ||
              u.role.toUpperCase() == _selectedRoleFilter.toUpperCase();

          return matchesSearch && matchesRole;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search staff by name, email, department...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _userSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _userSearchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) => setState(() => _userSearchQuery = val),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildRoleFilterChip('ALL', 'All Users (${allUsers.length})'),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('COMPANY_ADMIN', 'Admins'),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('MANAGER', 'Managers'),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('TEAM_LEAD', 'Team Leads'),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('HR', 'HR'),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('EMPLOYEE', 'Employees'),
                ],
              ),
            ),
            const Divider(height: 12),
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            _userSearchQuery.isNotEmpty
                                ? 'No users matching "$_userSearchQuery"'
                                : 'No employees in this organization yet.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _openAddUser(comp),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add First Member'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _UserCard(
                          user: user,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EmployeeDetailScreen(employee: user),
                              ),
                            );
                          },
                          onToggleStatus: () async {
                            final newStatus =
                                user.isActive ? 'SUSPENDED' : 'ACTIVE';
                            await _firestoreService.toggleEmployeeStatus(
                              uid: user.uid,
                              newStatus: newStatus,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleFilterChip(String role, String label) {
    final isSelected = _selectedRoleFilter == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedRoleFilter = role),
      visualDensity: VisualDensity.compact,
    );
  }

  // ==========================================
  // TAB 3: ATTENDANCE LOGS
  // ==========================================
  Widget _buildAttendanceTab(Company comp, String todayKey) {
    return StreamBuilder<List<Attendance>>(
      stream: _firestoreService.streamCompanyAttendanceByDate(
        companyId: comp.id,
        date: todayKey,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data ?? [];
        final clockedIn = records.length;
        final present = records.where((a) => a.isPresent).length;
        final lateCount = records.where((a) => a.isLate).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AttendanceStat(
                        label: "Today's Logs",
                        value: '$clockedIn',
                        color: Colors.blue.shade800,
                      ),
                      _AttendanceStat(
                        label: 'Present',
                        value: '$present',
                        color: Colors.green.shade800,
                      ),
                      _AttendanceStat(
                        label: 'Late Check-ins',
                        value: '$lateCount',
                        color: Colors.orange.shade800,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No attendance logged today ($todayKey).',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: records.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final att = records[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: att.isLate
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                              child: Icon(
                                att.isLate
                                    ? Icons.access_time_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: att.isLate
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                            title: Text(
                              att.employeeName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'In: ${att.formattedClockIn} • Out: ${att.formattedClockOut} (${att.formattedWorkingDuration})',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: att.isLate
                                    ? Colors.orange.shade600
                                    : Colors.green.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                att.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 4: LEAVE REQUESTS
  // ==========================================
  Widget _buildLeavesTab(Company comp) {
    return StreamBuilder<List<LeaveRequest>>(
      stream: _firestoreService.streamCompanyLeaveRequests(comp.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final leaves = snapshot.data ?? [];

        return leaves.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available_rounded,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No leave requests found for this organization.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: leaves.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  Color statusColor = Colors.orange.shade700;
                  if (leave.isApproved) statusColor = Colors.green.shade700;
                  if (leave.isRejected) statusColor = Colors.red.shade700;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                leave.employeeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  leave.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${leave.leaveType} • ${leave.totalDays} Day(s)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Period: ${leave.startDate} to ${leave.endDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          if (leave.reason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${leave.reason}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _MiniMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade700, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color.shade800),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final int count;
  final MaterialColor color;

  const _RolePill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.shade100,
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                radius: 22,
                backgroundColor: user.isActive
                    ? theme.colorScheme.primaryContainer
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
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: user.isCompanyAdmin
                                ? Colors.indigo.shade100
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: user.isCompanyAdmin
                                  ? Colors.indigo.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.designation} • ${user.department}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
              IconButton(
                icon: Icon(
                  user.isActive
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_filled_rounded,
                  color: user.isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                tooltip: user.isActive ? 'Active (Tap to Suspend)' : 'Suspended (Tap to Activate)',
                onPressed: onToggleStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
