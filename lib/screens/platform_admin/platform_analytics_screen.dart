import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/company.dart';
import '../../models/leave_request.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class PlatformAnalyticsScreen extends StatefulWidget {
  final UserProfile platformAdmin;

  const PlatformAnalyticsScreen({
    super.key,
    required this.platformAdmin,
  });

  @override
  State<PlatformAnalyticsScreen> createState() =>
      _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final todayKey = Attendance.formatDateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<Company>>(
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
              final users = usersSnapshot.data ?? [];
              final totalUsers = users.length;
              final activeUsers = users.where((u) => u.isActive).length;
              final suspendedUsers =
                  users.where((u) => u.isSuspended).length;

              final platformAdmins =
                  users.where((u) => u.isPlatformAdmin).length;
              final companyAdmins =
                  users.where((u) => u.isCompanyAdmin).length;
              final managers = users.where((u) => u.isManager).length;
              final teamLeads = users.where((u) => u.isTeamLead).length;
              final hrs = users.where((u) => u.isHR).length;
              final employees = users.where((u) => u.isEmployee).length;

              return StreamBuilder<List<Attendance>>(
                stream:
                    _firestoreService.streamAllAttendanceForDate(todayKey),
                builder: (context, attendanceSnapshot) {
                  final attendanceList = attendanceSnapshot.data ?? [];
                  final totalClockedIn = attendanceList.length;
                  final presentCount =
                      attendanceList.where((a) => a.isPresent).length;
                  final lateCount =
                      attendanceList.where((a) => a.isLate).length;
                  final currentlyWorking = attendanceList
                      .where((a) => a.clockIn != null && a.clockOut == null)
                      .length;

                  return StreamBuilder<List<LeaveRequest>>(
                    stream: _firestoreService
                        .streamAllPlatformLeaveRequests(),
                    builder: (context, leaveSnapshot) {
                      final leaves = leaveSnapshot.data ?? [];
                      final pendingLeaves =
                          leaves.where((l) => l.isPending).length;
                      final approvedLeaves =
                          leaves.where((l) => l.isApproved).length;
                      final rejectedLeaves =
                          leaves.where((l) => l.isRejected).length;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // SECTION 1: Tenant Platform Metrics
                            _AnalyticsSectionHeader(
                              title: 'Multi-Tenant Infrastructure',
                              icon: Icons.business_rounded,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    title: 'Total Tenants',
                                    value: '$totalCompanies',
                                    subtitle: 'Organizations',
                                    icon: Icons.apartment_rounded,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatTile(
                                    title: 'Active Tenants',
                                    value: '$activeCompanies',
                                    subtitle: 'Operational',
                                    icon: Icons.check_circle_outline_rounded,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    title: 'Suspended',
                                    value: '$suspendedCompanies',
                                    subtitle: 'Restricted',
                                    icon: Icons.pause_circle_outline_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatTile(
                                    title: 'Avg Team Size',
                                    value: totalCompanies > 0
                                        ? (totalUsers / totalCompanies)
                                            .toStringAsFixed(1)
                                        : '0',
                                    subtitle: 'Users / Tenant',
                                    icon: Icons.group_work_rounded,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // SECTION 2: Global Workforce Distribution
                            _AnalyticsSectionHeader(
                              title: 'Workforce & Role Distribution',
                              icon: Icons.people_alt_rounded,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Platform Users: $totalUsers',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$activeUsers Active',
                                                style: TextStyle(
                                                  color: Colors.green.shade800,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (suspendedUsers > 0) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$suspendedUsers Suspended',
                                                  style: TextStyle(
                                                    color: Colors.red.shade800,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    _DistributionBar(
                                      label: 'Employees',
                                      count: employees,
                                      total: totalUsers,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(height: 10),
                                    _DistributionBar(
                                      label: 'Company Admins',
                                      count: companyAdmins,
                                      total: totalUsers,
                                      color: Colors.indigo,
                                    ),
                                    const SizedBox(height: 10),
                                    _DistributionBar(
                                      label: 'Managers',
                                      count: managers,
                                      total: totalUsers,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(height: 10),
                                    _DistributionBar(
                                      label: 'Team Leads',
                                      count: teamLeads,
                                      total: totalUsers,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(height: 10),
                                    _DistributionBar(
                                      label: 'HR Personnel',
                                      count: hrs,
                                      total: totalUsers,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(height: 10),
                                    _DistributionBar(
                                      label: 'Platform Super Admins',
                                      count: platformAdmins,
                                      total: totalUsers,
                                      color: Colors.amber.shade800,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // SECTION 3: Live Daily Attendance
                            _AnalyticsSectionHeader(
                              title: "Today's Live Global Attendance",
                              icon: Icons.timer_outlined,
                              color: Colors.teal,
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              color: Colors.teal.shade50.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: Colors.teal.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _MetricPill(
                                          label: 'Clocked In',
                                          value: '$totalClockedIn',
                                          color: Colors.teal.shade800,
                                        ),
                                        _MetricPill(
                                          label: 'Active Now',
                                          value: '$currentlyWorking',
                                          color: Colors.blue.shade800,
                                        ),
                                        _MetricPill(
                                          label: 'On Time',
                                          value: '$presentCount',
                                          color: Colors.green.shade800,
                                        ),
                                        _MetricPill(
                                          label: 'Late',
                                          value: '$lateCount',
                                          color: Colors.orange.shade800,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // SECTION 4: Leave Requests Overview
                            _AnalyticsSectionHeader(
                              title: 'Global Leave Statistics',
                              icon: Icons.event_note_rounded,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    title: 'Pending',
                                    value: '$pendingLeaves',
                                    subtitle: 'Awaiting review',
                                    icon: Icons.hourglass_top_rounded,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatTile(
                                    title: 'Approved',
                                    value: '$approvedLeaves',
                                    subtitle: 'Granted',
                                    icon: Icons.check_circle_outline_rounded,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatTile(
                                    title: 'Rejected',
                                    value: '$rejectedLeaves',
                                    subtitle: 'Declined',
                                    icon: Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // SECTION 5: Top Organizations by Size
                            _AnalyticsSectionHeader(
                              title: 'Tenant Scale Leaderboard',
                              icon: Icons.leaderboard_rounded,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                              child: companies.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                          child: Text('No companies onboarded yet.')),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: companies.take(6).length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final comp = companies[index];
                                        final compUsers = users
                                            .where((u) => u.companyId == comp.id)
                                            .length;

                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.indigo.shade50,
                                            child: Text(
                                              '#${index + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo.shade800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            comp.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            'Admin: ${comp.adminName.isNotEmpty ? comp.adminName : "None"} • ${comp.industry}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$compUsers Staff',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo.shade900,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AnalyticsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _AnalyticsSectionHeader({
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;

  const _StatTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.shade800,
                ),
              ),
              Icon(icon, size: 18, color: color.shade700),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: color.shade700),
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              '$count (${(percent * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
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
            fontSize: 22,
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
