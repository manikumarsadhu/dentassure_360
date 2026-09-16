import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/expense_claim.dart';
import '../../models/leave_request.dart';
import '../../models/timesheet_entry.dart';
import '../../models/user_profile.dart';
import '../../navigation/app_nav.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/team_scope.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/clock_in_card.dart';
import '../../widgets/user_avatar.dart';
import '../assets/assets_screen.dart';
import '../attendance/admin_attendance_screen.dart';
import '../employee/add_employee_screen.dart';
import '../employee/employee_list_screen.dart';
import '../expenses/expenses_screen.dart';
import '../leave/admin_leave_screen.dart';
import '../leave/employee_leave_screen.dart';
import '../letters/letters_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../payslips/payslips_screen.dart';
import '../performance/performance_screen.dart';
import '../profile/my_profile_screen.dart';
import '../recruitment/recruitment_screen.dart';
import '../timesheet/timesheet_screen.dart';

class RolePortal extends StatefulWidget {
  final UserProfile userProfile;

  const RolePortal({super.key, required this.userProfile});

  @override
  State<RolePortal> createState() => _RolePortalState();
}

class _RolePortalState extends State<RolePortal> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  String _selectedId = 'home';

  Future<void> _logout() async {
    final should = await showDialog<bool>(
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (should == true) {
      await _authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.streamUserProfile(widget.userProfile.uid),
      initialData: widget.userProfile,
      builder: (context, snapshot) {
        final user = snapshot.data ?? widget.userProfile;
        return AppShell(
          user: user,
          selectedId: _selectedId,
          onSelect: (id) => setState(() => _selectedId = id),
          onLogout: _logout,
          onOpenProfile: () => setState(() => _selectedId = 'profile'),
          body: _buildBody(user),
        );
      },
    );
  }

  Widget _buildBody(UserProfile user) {
    final teamScoped = user.isManager || user.isTeamLead;
    switch (_selectedId) {
      case 'people':
      case 'team':
        return EmployeeListScreen(
          adminProfile: user,
          teamScoped: teamScoped && _selectedId == 'team',
          embedded: true,
        );
      case 'onboarding':
        return OnboardingScreen(viewer: user);
      case 'letters':
        return LettersScreen(viewer: user);
      case 'attendance':
        return AdminAttendanceScreen(
          adminProfile: user,
          teamScoped: teamScoped,
          embedded: true,
        );
      case 'leave':
        return AdminLeaveScreen(
          adminProfile: user,
          teamScoped: teamScoped,
          embedded: true,
        );
      case 'timesheet':
        return TimesheetScreen(viewer: user, personalOnly: false);
      case 'myTimesheet':
        return TimesheetScreen(viewer: user, personalOnly: true);
      case 'expenses':
        return ExpensesScreen(
          viewer: user,
          personalOnly: user.isEmployee || user.isTeamLead,
        );
      case 'assets':
        return AssetsScreen(viewer: user);
      case 'payslips':
        return PayslipsScreen(viewer: user);
      case 'recruitment':
        return RecruitmentScreen(viewer: user);
      case 'performance':
        return PerformanceScreen(viewer: user);
      case 'myLeave':
        return EmployeeLeaveScreen(employee: user);
      case 'profile':
        return MyProfileScreen(userProfile: user);
      case 'home':
      default:
        return _RoleHome(
          user: user,
          onOpen: (id) => setState(() => _selectedId = id),
        );
    }
  }
}

class _RoleHome extends StatelessWidget {
  final UserProfile user;
  final ValueChanged<String> onOpen;

  const _RoleHome({required this.user, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final todayKey = Attendance.formatDateKey(DateTime.now());
    final theme = Theme.of(context);

    return StreamBuilder<List<UserProfile>>(
      stream: firestore.streamCompanyEmployees(user.companyId),
      builder: (context, usersSnap) {
        final all = usersSnap.data ?? [];
        final team = TeamScope.reportsFor(user, all);
        final visible = user.isPeopleOps ? all : team;
        return StreamBuilder<List<Attendance>>(
          stream: firestore.streamCompanyAttendanceByDate(
            companyId: user.companyId,
            date: todayKey,
          ),
          builder: (context, attSnap) {
            return StreamBuilder<List<LeaveRequest>>(
              stream: firestore.streamCompanyLeaveRequests(user.companyId),
              builder: (context, leaveSnap) {
                return StreamBuilder<List<TimesheetEntry>>(
                  stream: firestore.streamCompanyTimesheets(user.companyId),
                  builder: (context, tsSnap) {
                    return StreamBuilder<List<ExpenseClaim>>(
                      stream: firestore.streamCompanyExpenses(user.companyId),
                      builder: (context, expSnap) {
                        final allowed = visible.map((u) => u.uid).toSet();
                        final att = (attSnap.data ?? [])
                            .where((a) =>
                                user.isPeopleOps || allowed.contains(a.uid))
                            .toList();
                        final leaves = (leaveSnap.data ?? [])
                            .where((l) =>
                                user.isPeopleOps || allowed.contains(l.uid))
                            .toList();
                        final present = att
                            .where((a) => a.isPresent || a.isLate)
                            .length;
                        final lateCount = att.where((a) => a.isLate).length;
                        final pendingLeaveList =
                            leaves.where((l) => l.isPending).toList();
                        final pendingTsList = (tsSnap.data ?? [])
                            .where((t) =>
                                t.isPending &&
                                (user.isPeopleOps || allowed.contains(t.uid)))
                            .toList();
                        final pendingExpList = (expSnap.data ?? [])
                            .where((e) =>
                                e.isPending &&
                                (user.isPeopleOps || allowed.contains(e.uid)))
                            .toList();
                        final onboardingPeople = all
                            .where((u) =>
                                !u.isOnboardingComplete && !u.isPlatformAdmin)
                            .toList();
                        final hour = DateTime.now().hour;
                        final greeting = hour < 12
                            ? 'Good morning'
                            : hour < 17
                                ? 'Good afternoon'
                                : 'Good evening';
                        final firstName = user.name.split(' ').first;

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text(
                              '$greeting, $firstName',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${AppNav.portalTitle(user)} · ${user.companyName.isNotEmpty ? user.companyName : 'Dentassure 360'}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),
                            if (!user.isCompanyAdmin) ...[
                              ClockInCard(user: user),
                              const SizedBox(height: 16),
                            ],
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _HomeStat(
                                  label: user.isPeopleOps
                                      ? 'Headcount'
                                      : 'My Team',
                                  value: '${visible.length}',
                                  color: Colors.blue,
                                  onTap: () => onOpen(
                                    user.isPeopleOps ? 'people' : 'team',
                                  ),
                                ),
                                _HomeStat(
                                  label: 'Present today',
                                  value: '$present',
                                  color: Colors.green,
                                  onTap: () => onOpen('attendance'),
                                ),
                                _HomeStat(
                                  label: 'Late today',
                                  value: '$lateCount',
                                  color: Colors.orange,
                                  onTap: () => onOpen('attendance'),
                                ),
                                _HomeStat(
                                  label: 'Pending leave',
                                  value: '${pendingLeaveList.length}',
                                  color: Colors.deepOrange,
                                  onTap: () => onOpen('leave'),
                                ),
                                if (user.isPeopleOps)
                                  _HomeStat(
                                    label: 'Onboarding',
                                    value: '${onboardingPeople.length}',
                                    color: Colors.purple,
                                    onTap: () => onOpen('onboarding'),
                                  ),
                                if (user.isTeamApprover)
                                  _HomeStat(
                                    label: 'Timesheets',
                                    value: '${pendingTsList.length}',
                                    color: Colors.teal,
                                    onTap: () => onOpen('timesheet'),
                                  ),
                                if (user.isPeopleOps || user.isManager)
                                  _HomeStat(
                                    label: 'Expenses',
                                    value: '${pendingExpList.length}',
                                    color: Colors.brown,
                                    onTap: () => onOpen('expenses'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Quick actions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                if (user.isPeopleOps)
                                  _QuickAction(
                                    icon: Icons.person_add_alt_1,
                                    title: 'Add Employee',
                                    subtitle: 'Onboard a new team member',
                                    onTap: () {
                                      Navigator.of(context, rootNavigator: true)
                                          .push(
                                        MaterialPageRoute(
                                          builder: (_) => AddEmployeeScreen(
                                            adminProfile: user,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                _QuickAction(
                                  icon: Icons.groups_outlined,
                                  title: user.isPeopleOps
                                      ? 'HR & People'
                                      : 'My Team',
                                  subtitle: user.isPeopleOps
                                      ? 'Directory, roles and profiles'
                                      : 'View your reportees',
                                  onTap: () => onOpen(
                                    user.isPeopleOps ? 'people' : 'team',
                                  ),
                                ),
                                _QuickAction(
                                  icon: Icons.schedule_outlined,
                                  title: 'Attendance',
                                  subtitle: 'Today’s check-ins and absences',
                                  onTap: () => onOpen('attendance'),
                                ),
                                _QuickAction(
                                  icon: Icons.event_available_outlined,
                                  title: 'Leave',
                                  subtitle: 'Review time-off requests',
                                  onTap: () => onOpen('leave'),
                                ),
                                if (user.isPeopleOps)
                                  _QuickAction(
                                    icon: Icons.person_add_alt_outlined,
                                    title: 'Onboarding',
                                    subtitle: 'Day-one checklists',
                                    onTap: () => onOpen('onboarding'),
                                  ),
                                _QuickAction(
                                  icon: Icons.timer_outlined,
                                  title: 'Timesheets',
                                  subtitle: 'Project hours and approvals',
                                  onTap: () => onOpen('timesheet'),
                                ),
                                if (user.isPeopleOps || user.isManager)
                                  _QuickAction(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Expenses',
                                    subtitle: 'Claims waiting for review',
                                    onTap: () => onOpen('expenses'),
                                  ),
                                if (user.isPeopleOps)
                                  _QuickAction(
                                    icon: Icons.work_outline,
                                    title: 'Recruitment',
                                    subtitle: 'Candidates and pipeline',
                                    onTap: () => onOpen('recruitment'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 840;
                                final attention = _NeedsAttentionPanel(
                                  pendingLeave: pendingLeaveList,
                                  pendingTimesheets: pendingTsList,
                                  pendingExpenses: pendingExpList,
                                  onOpenLeave: () => onOpen('leave'),
                                  onOpenTimesheet: () => onOpen('timesheet'),
                                  onOpenExpenses: () => onOpen('expenses'),
                                );
                                final people = _PeopleSnapshotPanel(
                                  people: user.isPeopleOps
                                      ? onboardingPeople
                                      : visible,
                                  title: user.isPeopleOps
                                      ? 'Onboarding in progress'
                                      : 'Team members',
                                  emptyLabel: user.isPeopleOps
                                      ? 'All staff are day-one ready.'
                                      : 'No team members assigned yet.',
                                  onSeeAll: () => onOpen(
                                    user.isPeopleOps ? 'onboarding' : 'team',
                                  ),
                                );
                                if (stacked) {
                                  return Column(
                                    children: [
                                      attention,
                                      const SizedBox(height: 12),
                                      people,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: attention),
                                    const SizedBox(width: 12),
                                    Expanded(child: people),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeStat extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;
  final VoidCallback onTap;

  const _HomeStat({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color.shade900,
                ),
              ),
              Text(label, style: TextStyle(color: color.shade800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class _NeedsAttentionPanel extends StatelessWidget {
  final List<LeaveRequest> pendingLeave;
  final List<TimesheetEntry> pendingTimesheets;
  final List<ExpenseClaim> pendingExpenses;
  final VoidCallback onOpenLeave;
  final VoidCallback onOpenTimesheet;
  final VoidCallback onOpenExpenses;

  const _NeedsAttentionPanel({
    required this.pendingLeave,
    required this.pendingTimesheets,
    required this.pendingExpenses,
    required this.onOpenLeave,
    required this.onOpenTimesheet,
    required this.onOpenExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_AttentionItem>[
      ...pendingLeave.take(4).map(
            (l) => _AttentionItem(
              title: l.employeeName,
              subtitle: '${l.displayLeaveType} · ${l.formattedDateRange}',
              onTap: onOpenLeave,
            ),
          ),
      ...pendingTimesheets.take(3).map(
            (t) => _AttentionItem(
              title: t.employeeName,
              subtitle: '${t.project} · ${t.hours}h pending',
              onTap: onOpenTimesheet,
            ),
          ),
      ...pendingExpenses.take(3).map(
            (e) => _AttentionItem(
              title: e.employeeName,
              subtitle: '${e.title} · ₹${e.amount.toStringAsFixed(0)}',
              onTap: onOpenExpenses,
            ),
          ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Needs attention',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No pending leave, timesheets, or expenses.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: item.onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttentionItem {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttentionItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _PeopleSnapshotPanel extends StatelessWidget {
  final List<UserProfile> people;
  final String title;
  final String emptyLabel;
  final VoidCallback onSeeAll;

  const _PeopleSnapshotPanel({
    required this.people,
    required this.title,
    required this.emptyLabel,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final preview = people.take(6).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(onPressed: onSeeAll, child: const Text('See all')),
              ],
            ),
            if (preview.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  emptyLabel,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...preview.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(
                    avatarUrl: p.avatarUrl,
                    name: p.name,
                    radius: 18,
                    fontSize: 14,
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    '${p.designation} · ${p.department}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: onSeeAll,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
