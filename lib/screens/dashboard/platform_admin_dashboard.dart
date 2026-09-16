import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/company.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/user_avatar.dart';
import '../company/create_company_screen.dart';
import '../platform_admin/company_detail_screen.dart';
import '../platform_admin/edit_company_screen.dart';
import '../platform_admin/platform_analytics_screen.dart';
import '../platform_admin/platform_audit_logs_screen.dart';
import '../platform_admin/platform_users_screen.dart';
import '../profile/my_profile_screen.dart';

class PlatformAdminDashboard extends StatefulWidget {
  final UserProfile userProfile;

  const PlatformAdminDashboard({
    super.key,
    required this.userProfile,
  });

  @override
  State<PlatformAdminDashboard> createState() =>
      _PlatformAdminDashboardState();
}

class _PlatformAdminDashboardState extends State<PlatformAdminDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL'; // ALL, ACTIVE, SUSPENDED

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text(
          'Are you sure you want to log out of the Platform Admin portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
    }
  }

  void _openCreateCompany() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCompanyScreen(
          platformAdmin: widget.userProfile,
        ),
      ),
    );
  }

  void _openGlobalUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlatformUsersScreen(
          platformAdmin: widget.userProfile,
        ),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlatformAnalyticsScreen(
          platformAdmin: widget.userProfile,
        ),
      ),
    );
  }

  void _openAuditLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlatformAuditLogsScreen(
          platformAdmin: widget.userProfile,
        ),
      ),
    );
  }

  void _openCompanyDetail(Company company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailScreen(
          company: company,
          platformAdmin: widget.userProfile,
        ),
      ),
    );
  }

  Future<void> _toggleCompanyStatus(Company company) async {
    final isCurrentlyActive = company.status == 'ACTIVE';
    final targetStatus = isCurrentlyActive ? 'SUSPENDED' : 'ACTIVE';
    final actionText = isCurrentlyActive ? 'Suspend' : 'Activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText Company'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to suspend "${company.name}"? Users under this tenant may not be able to perform regular tasks.'
              : 'Activate "${company.name}" and restore normal operations?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isCurrentlyActive ? Colors.red.shade600 : Colors.green.shade700,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.toggleCompanyStatus(
          companyId: company.id,
          newStatus: targetStatus,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Company "${company.name}" is now marked as $targetStatus.',
            ),
            backgroundColor:
                isCurrentlyActive ? Colors.orange.shade800 : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update company status: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteCompany(Company company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization'),
        content: Text(
          'Are you sure you want to delete "${company.name}"? This action removes the company record from the platform registry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteCompany(company.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company "${company.name}" deleted successfully.'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayKey = Attendance.formatDateKey(DateTime.now());

    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.streamUserProfile(widget.userProfile.uid),
      initialData: widget.userProfile,
      builder: (context, profileSnapshot) {
        final user = profileSnapshot.data ?? widget.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Admin Portal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Super Admin Multi-Tenant Hub',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Platform Analytics',
                onPressed: _openAnalytics,
                icon: const Icon(Icons.insights_rounded),
              ),
              IconButton(
                tooltip: 'Global Users',
                onPressed: _openGlobalUsers,
                icon: const Icon(Icons.people_alt_rounded),
              ),
              IconButton(
                tooltip: 'My Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyProfileScreen(userProfile: user),
                    ),
                  );
                },
                icon: const Icon(Icons.account_circle_outlined),
              ),
              IconButton(
                tooltip: 'Sign Out',
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateCompany,
            backgroundColor: Colors.indigo.shade800,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Onboard Organization'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: StreamBuilder<List<Company>>(
              stream: _firestoreService.streamAllCompanies(),
              builder: (context, companiesSnapshot) {
                final companies = companiesSnapshot.data ?? [];
                final totalCompanies = companies.length;
                final activeCompanies =
                    companies.where((c) => c.status == 'ACTIVE').length;
                final suspendedCompanies =
                    companies.where((c) => c.status == 'SUSPENDED').length;

                return StreamBuilder<List<UserProfile>>(
                  stream: _firestoreService.streamAllPlatformUsers(),
                  builder: (context, usersSnapshot) {
                    final allUsers = usersSnapshot.data ?? [];
                    final totalUsers = allUsers.length;

                    return StreamBuilder<List<Attendance>>(
                      stream: _firestoreService
                          .streamAllAttendanceForDate(todayKey),
                      builder: (context, attSnapshot) {
                        final todayAttendance = attSnapshot.data ?? [];
                        final activeWorkingCount = todayAttendance
                            .where((a) => a.clockIn != null && a.clockOut == null)
                            .length;

                        // Filtered companies
                        final filteredCompanies = companies.where((comp) {
                          final query = _searchQuery.toLowerCase();
                          final matchesSearch = query.isEmpty ||
                              comp.name.toLowerCase().contains(query) ||
                              comp.id.toLowerCase().contains(query) ||
                              comp.adminEmail.toLowerCase().contains(query) ||
                              comp.adminName.toLowerCase().contains(query) ||
                              comp.industry.toLowerCase().contains(query);

                          final matchesStatus =
                              _selectedStatusFilter == 'ALL' ||
                                  comp.status == _selectedStatusFilter;

                          return matchesSearch && matchesStatus;
                        }).toList();

                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Platform Admin Profile Banner
                              Card(
                                elevation: 0,
                                color: Colors.indigo.shade900,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MyProfileScreen(userProfile: user),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        UserAvatar(
                                          avatarUrl: user.avatarUrl,
                                          name: user.name.isNotEmpty
                                              ? user.name
                                              : 'P',
                                          radius: 28,
                                          backgroundColor:
                                              Colors.indigo.shade400,
                                          textColor: Colors.white,
                                          fontSize: 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name.isNotEmpty
                                                    ? user.name
                                                    : 'Platform Administrator',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.email,
                                                style: TextStyle(
                                                  color: Colors.indigo.shade100,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.amber.shade700,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: const Text(
                                                      'SUPER ADMIN',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'View Profile →',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.amber.shade300,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 2. Real-time KPI Metric Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      icon: Icons.apartment_rounded,
                                      label: 'Total Tenants',
                                      value: '$totalCompanies',
                                      subtitle: '$activeCompanies Active',
                                      color: Colors.indigo,
                                      onTap: () => setState(() =>
                                          _selectedStatusFilter = 'ALL'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricCard(
                                      icon: Icons.people_alt_rounded,
                                      label: 'Platform Users',
                                      value: '$totalUsers',
                                      subtitle: 'Across Organizations',
                                      color: Colors.blue,
                                      onTap: _openGlobalUsers,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      icon: Icons.access_time_rounded,
                                      label: "Today's Check-ins",
                                      value: '${todayAttendance.length}',
                                      subtitle: '$activeWorkingCount On Duty',
                                      color: Colors.teal,
                                      onTap: _openAnalytics,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricCard(
                                      icon: Icons.shield_outlined,
                                      label: 'Suspended',
                                      value: '$suspendedCompanies',
                                      subtitle: 'Restricted Orgs',
                                      color: Colors.red,
                                      onTap: () => setState(() =>
                                          _selectedStatusFilter = 'SUSPENDED'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 3. Platform Quick Actions Grid
                              Text(
                                'Platform Management Suite',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.1,
                                children: [
                                  _PlatformActionTile(
                                    title: 'Onboard Company',
                                    subtitle: 'Create tenant & admin',
                                    icon: Icons.add_business_rounded,
                                    color: Colors.indigo,
                                    onTap: _openCreateCompany,
                                  ),
                                  _PlatformActionTile(
                                    title: 'Global Directory',
                                    subtitle: '$totalUsers total users',
                                    icon: Icons.badge_outlined,
                                    color: Colors.blue,
                                    onTap: _openGlobalUsers,
                                  ),
                                  _PlatformActionTile(
                                    title: 'System Analytics',
                                    subtitle: 'Multi-tenant metrics',
                                    icon: Icons.query_stats_rounded,
                                    color: Colors.teal,
                                    onTap: _openAnalytics,
                                  ),
                                  _PlatformActionTile(
                                    title: 'Audit & Security',
                                    subtitle: 'System activity logs',
                                    icon: Icons.verified_user_outlined,
                                    color: Colors.purple,
                                    onTap: _openAuditLogs,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // 4. Tenant Directory Header & Search Bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Registered Organizations',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${filteredCompanies.length} Organizations',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search by organization, admin, industry, or ID...',
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
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val.trim());
                                },
                              ),
                              const SizedBox(height: 10),

                              // Status Filter Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('ALL', 'All ($totalCompanies)'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip(
                                        'ACTIVE', 'Active ($activeCompanies)'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('SUSPENDED',
                                        'Suspended ($suspendedCompanies)'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 5. Tenant List
                              if (filteredCompanies.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 36.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.apartment_rounded,
                                          size: 56,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? 'No organizations match "$_searchQuery"'
                                              : 'No companies registered yet.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        FilledButton.icon(
                                          onPressed: _openCreateCompany,
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                Colors.indigo.shade800,
                                          ),
                                          icon: const Icon(
                                              Icons.add_business_rounded),
                                          label: const Text(
                                              'Onboard First Company'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredCompanies.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final comp = filteredCompanies[index];
                                    final companyUsers = allUsers
                                        .where((u) => u.companyId == comp.id)
                                        .toList();
                                    final empCount = companyUsers.length;

                                    return _CompanyCard(
                                      company: comp,
                                      employeeCount: empCount,
                                      onTap: () => _openCompanyDetail(comp),
                                      onToggleStatus: () =>
                                          _toggleCompanyStatus(comp),
                                      onEdit: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                EditCompanyScreen(company: comp),
                                          ),
                                        );
                                      },
                                      onDelete: () => _deleteCompany(comp),
                                    );
                                  },
                                ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatusFilter = value);
      },
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final MaterialColor color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.shade100,
              child: Icon(icon, color: color.shade800, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color.shade900,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _PlatformActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.shade50,
                child: Icon(icon, color: color.shade800, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final int employeeCount;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyCard({
    required this.company,
    required this.employeeCount,
    required this.onTap,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = company.status == 'ACTIVE';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        isActive ? Colors.indigo.shade50 : Colors.red.shade50,
                    child: Icon(
                      Icons.apartment_rounded,
                      color: isActive
                          ? Colors.indigo.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          company.industry,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (company.adminName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Admin: ${company.adminName} (${company.adminEmail})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'details') onTap();
                      if (val == 'edit') onEdit();
                      if (val == 'toggle') onToggleStatus();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('View Staff & Logs'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.play_circle_outline_rounded,
                              size: 18,
                              color: isActive ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Suspend' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          company.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$employeeCount Staff',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('Manage Tenant',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
