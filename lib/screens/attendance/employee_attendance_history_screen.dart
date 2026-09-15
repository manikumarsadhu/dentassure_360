import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class EmployeeAttendanceHistoryScreen extends StatefulWidget {
  final UserProfile employee;

  const EmployeeAttendanceHistoryScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeAttendanceHistoryScreen> createState() =>
      _EmployeeAttendanceHistoryScreenState();
}

class _EmployeeAttendanceHistoryScreenState
    extends State<EmployeeAttendanceHistoryScreen> {
  final _firestoreService = FirestoreService();
  String _selectedStatusFilter = 'ALL';

  List<Attendance> _filterAttendance(List<Attendance> list) {
    if (_selectedStatusFilter == 'ALL') return list;
    return list
        .where((a) =>
            a.status.toUpperCase() == _selectedStatusFilter.toUpperCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance History'),
      ),
      body: StreamBuilder<List<Attendance>>(
        stream: _firestoreService
            .streamEmployeeAttendanceHistory(widget.employee.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Failed to load attendance logs: ${snapshot.error}'),
              ),
            );
          }

          final allRecords = snapshot.data ?? [];
          final records = _filterAttendance(allRecords);

          // Calculate statistics
          final presentCount =
              allRecords.where((a) => a.isPresent || a.isLate).length;
          final lateCount = allRecords.where((a) => a.isLate).length;
          final halfDayCount = allRecords.where((a) => a.isHalfDay).length;
          final totalMinutes = allRecords.fold<int>(
              0, (sum, a) => sum + (a.workingMinutes > 0 ? a.workingMinutes : 0));
          final totalHours = (totalMinutes / 60).toStringAsFixed(1);

          return Column(
            children: [
              // Statistics Overview
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Days Worked',
                            value: '$presentCount',
                            color: Colors.blue,
                            icon: Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: 'Total Hours',
                            value: '${totalHours}h',
                            color: Colors.green,
                            icon: Icons.access_time,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: 'Late Check-in',
                            value: '$lateCount',
                            color: Colors.orange,
                            icon: Icons.alarm,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: 'Half Days',
                            value: '$halfDayCount',
                            color: Colors.indigo,
                            icon: Icons.hourglass_bottom,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Logs', 'ALL'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Present', 'PRESENT'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Late', 'LATE'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Half Day', 'HALF_DAY'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Attendance Records List
              Expanded(
                child: allRecords.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No attendance records yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clock in from your dashboard to start tracking daily work hours.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : records.isEmpty
                        ? Center(
                            child: Text(
                              'No records matching filter "$_selectedStatusFilter"',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: records.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return _AttendanceCard(attendance: record);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusKey) {
    final isSelected = _selectedStatusFilter == statusKey;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = statusKey),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: color.shade800),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Attendance attendance;

  const _AttendanceCard({required this.attendance});

  Color _getStatusColor() {
    switch (attendance.status.toUpperCase()) {
      case 'PRESENT':
        return Colors.green;
      case 'LATE':
        return Colors.orange;
      case 'HALF_DAY':
        return Colors.blue;
      case 'ABSENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Header: Date & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      attendance.date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    attendance.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Time Row: Clock In, Clock Out, Total Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TimeItem(
                  icon: Icons.login_rounded,
                  label: 'Clock In',
                  time: attendance.formattedClockIn,
                  color: Colors.green,
                ),
                _TimeItem(
                  icon: Icons.logout_rounded,
                  label: 'Clock Out',
                  time: attendance.formattedClockOut,
                  color: attendance.isClockedIn ? Colors.grey : Colors.orange,
                ),
                _TimeItem(
                  icon: Icons.timer_outlined,
                  label: 'Working',
                  time: attendance.formattedWorkingDuration,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
