import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/attendance.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../attendance/admin_attendance_screen.dart';
import '../employee/add_employee_screen.dart';
import '../employee/employee_list_screen.dart';
import '../leave/admin_leave_screen.dart';
import '../profile/my_profile_screen.dart';
import '../../widgets/user_avatar.dart';

class AdminDashboard extends StatefulWidget {
  final UserProfile userProfile;

  const AdminDashboard({
    super.key,
    required this.userProfile,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to log out?'),
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

  void _openAddEmployee() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEmployeeScreen(
          adminProfile: widget.userProfile,
        ),
      ),
    );
  }

  void _openEmployeeList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeListScreen(
          adminProfile: widget.userProfile,
        ),
      ),
    );
  }

  void _openAttendanceRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAttendanceScreen(
          adminProfile: widget.userProfile,
        ),
      ),
    );
  }

  void _openLeaveManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLeaveScreen(
          adminProfile: widget.userProfile,
        ),
      ),
    );
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
                  'Company Admin Portal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (user.companyName.isNotEmpty)
                  Text(
                    user.companyName,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'Organization Management',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            actions: [
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
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Profile Welcome Banner (Tappable to view Profile)
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyProfileScreen(userProfile: user),
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
                              name: user.name.isNotEmpty ? user.name : 'A',
                              radius: 28,
                              backgroundColor: theme.colorScheme.primary,
                              textColor: theme.colorScheme.onPrimary,
                              fontSize: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isNotEmpty
                                        ? user.name
                                        : 'Company Administrator',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          user.role,
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'View Profile →',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
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

              const SizedBox(height: 16),

              // Company Details Chip Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Company ID: ${user.companyId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy Company ID',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: user.companyId),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Company ID copied to clipboard!'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overview Section Title
              Text(
                'Company Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Real-time Employee Count & Attendance Stats
              StreamBuilder<List<UserProfile>>(
                stream:
                    _firestoreService.streamCompanyEmployees(user.companyId),
                builder: (context, empSnapshot) {
                  final employees = empSnapshot.data ?? [];
                  final totalStaff = employees.length;

                  return StreamBuilder<List<Attendance>>(
                    stream: _firestoreService.streamCompanyAttendanceByDate(
                      companyId: user.companyId,
                      date: todayKey,
                    ),
                    builder: (context, attSnapshot) {
                      final todayAttendance = attSnapshot.data ?? [];
                      final presentToday = todayAttendance
                          .where((a) => a.isPresent || a.isLate)
                          .length;
                      final lateToday =
                          todayAttendance.where((a) => a.isLate).length;

                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_alt_rounded,
                              label: 'Total Staff',
                              value: empSnapshot.hasData
                                  ? '$totalStaff'
                                  : '...',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Active Today',
                              value: attSnapshot.hasData
                                  ? '$presentToday'
                                  : '...',
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.alarm_on_rounded,
                              label: 'Late Today',
                              value: attSnapshot.hasData ? '$lateToday' : '0',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 28),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openAddEmployee,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Add Employee'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Management Tiles
              _ActionTile(
                icon: Icons.group_outlined,
                title: 'Employees Directory',
                subtitle: 'View, onboard, edit, and suspend team members',
                onTap: _openEmployeeList,
              ),
              const SizedBox(height: 10),

              _ActionTile(
                icon: Icons.access_time_rounded,
                title: 'Attendance Records',
                subtitle: 'Track check-ins, check-outs, and daily reports',
                onTap: _openAttendanceRecords,
              ),
              const SizedBox(height: 10),

              _ActionTile(
                icon: Icons.event_note_rounded,
                title: 'Leave Approvals',
                subtitle: 'Review employee leave applications',
                onTap: _openLeaveManagement,
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MaterialColor color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade700, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: color.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
