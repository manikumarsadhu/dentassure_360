import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/leave_request.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final UserProfile adminProfile;

  const AdminAttendanceScreen({
    super.key,
    required this.adminProfile,
  });

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  late DateTime _selectedDate;
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';
  String _selectedDepartmentFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      if (preset == 'TODAY') {
        _selectedDate = now;
      } else if (preset == 'YESTERDAY') {
        _selectedDate = now.subtract(const Duration(days: 1));
      }
    });
  }

  String _formatDisplayDate(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateKey = Attendance.formatDateKey(_selectedDate);
    final isToday = Attendance.formatDateKey(DateTime.now()) == dateKey;
    final isYesterday = Attendance.formatDateKey(
            DateTime.now().subtract(const Duration(days: 1))) ==
        dateKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        actions: [
          IconButton(
            tooltip: 'Select Date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _firestoreService.streamCompanyEmployees(
          widget.adminProfile.companyId,
        ),
        builder: (context, empSnapshot) {
          final allEmployees = empSnapshot.data ?? [];
          final activeEmployees =
              allEmployees.where((e) => e.isActive).toList();

          return StreamBuilder<List<Attendance>>(
            stream: _firestoreService.streamCompanyAttendanceByDate(
              companyId: widget.adminProfile.companyId,
              date: dateKey,
            ),
            builder: (context, attSnapshot) {
              return StreamBuilder<List<LeaveRequest>>(
                stream: _firestoreService.streamCompanyLeaveRequests(
                  widget.adminProfile.companyId,
                ),
                builder: (context, leaveSnapshot) {
                  if (empSnapshot.connectionState == ConnectionState.waiting &&
                      attSnapshot.connectionState == ConnectionState.waiting &&
                      leaveSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final attendanceRecords = attSnapshot.data ?? [];
                  final allLeaveRequests = leaveSnapshot.data ?? [];

                  // Map of uid -> Attendance record for fast lookup
                  final attendanceMap = <String, Attendance>{};
                  for (final rec in attendanceRecords) {
                    attendanceMap[rec.uid] = rec;
                  }

                  // Map of uid -> Approved Leave covering selected date
                  final leaveMap = <String, LeaveRequest>{};
                  for (final req in allLeaveRequests) {
                    if (req.coversDate(dateKey)) {
                      leaveMap[req.uid] = req;
                    }
                  }

                  // Build merged employee attendance status list
                  final List<_EmployeeAttendanceStatus> fullList = [];
                  for (final emp in activeEmployees) {
                    final att = attendanceMap[emp.uid];
                    final leave = leaveMap[emp.uid];

                    if (att != null) {
                      fullList.add(_EmployeeAttendanceStatus(
                        employee: emp,
                        attendance: att,
                        leaveRequest: leave,
                        status: att.status,
                      ));
                    } else if (leave != null) {
                      // Legitimate approved leave -> On Leave (not Absent!)
                      fullList.add(_EmployeeAttendanceStatus(
                        employee: emp,
                        attendance: null,
                        leaveRequest: leave,
                        status: 'LEAVE',
                      ));
                    } else {
                      // No check-in and no approved leave => ABSENT
                      fullList.add(_EmployeeAttendanceStatus(
                        employee: emp,
                        attendance: null,
                        leaveRequest: null,
                        status: 'ABSENT',
                      ));
                    }
                  }

                  // Compute Summary Metrics
                  final totalStaff = activeEmployees.length;
                  final presentCount =
                      fullList.where((i) => i.status == 'PRESENT').length;
                  final lateCount =
                      fullList.where((i) => i.status == 'LATE').length;
                  final halfDayCount =
                      fullList.where((i) => i.status == 'HALF_DAY').length;
                  final leaveCount =
                      fullList.where((i) => i.status == 'LEAVE').length;
                  final absentCount =
                      fullList.where((i) => i.status == 'ABSENT').length;

                  // Apply Search & Filters
                  final filteredList = fullList.where((item) {
                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      final matchName =
                          item.employee.name.toLowerCase().contains(query);
                      final matchId =
                          item.employee.employeeId.toLowerCase().contains(query);
                      final matchDept =
                          item.employee.department.toLowerCase().contains(query);
                      if (!matchName && !matchId && !matchDept) return false;
                    }

                    // Status filter
                    if (_selectedStatusFilter != 'ALL') {
                      if (item.status.toUpperCase() != _selectedStatusFilter) {
                        return false;
                      }
                    }

                    // Department filter
                    if (_selectedDepartmentFilter != 'ALL') {
                      if (item.employee.department.toLowerCase() !=
                          _selectedDepartmentFilter.toLowerCase()) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // Top Date Navigation & Presets
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: theme.colorScheme.surface,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 18,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDisplayDate(_selectedDate),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _DatePresetButton(
                                      label: 'Today',
                                      isSelected: isToday,
                                      onTap: () => _setDatePreset('TODAY'),
                                    ),
                                    const SizedBox(width: 6),
                                    _DatePresetButton(
                                      label: 'Yesterday',
                                      isSelected: isYesterday,
                                      onTap: () => _setDatePreset('YESTERDAY'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Metrics Summary Row
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Total',
                                    value: '$totalStaff',
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Present',
                                    value: '$presentCount',
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Late',
                                    value: '$lateCount',
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Half Day',
                                    value: '$halfDayCount',
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _MetricCard(
                                    label: 'On Leave',
                                    value: '$leaveCount',
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Absent',
                                    value: '$absentCount',
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Search Bar
                            TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() => _searchQuery = val.trim());
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by employee name or ID...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Horizontal Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip(
                                    'All Status',
                                    'ALL',
                                    _selectedStatusFilter,
                                    (v) => setState(
                                        () => _selectedStatusFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'Present ($presentCount)',
                                    'PRESENT',
                                    _selectedStatusFilter,
                                    (v) => setState(
                                        () => _selectedStatusFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'Late ($lateCount)',
                                    'LATE',
                                    _selectedStatusFilter,
                                    (v) => setState(
                                        () => _selectedStatusFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'Half Day ($halfDayCount)',
                                    'HALF_DAY',
                                    _selectedStatusFilter,
                                    (v) => setState(
                                        () => _selectedStatusFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'On Leave ($leaveCount)',
                                    'LEAVE',
                                    _selectedStatusFilter,
                                    (v) => setState(
                                        () => _selectedStatusFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'Absent ($absentCount)',
                                    'ABSENT',
                                    _selectedStatusFilter,
                                    (v) => setState(
                                        () => _selectedStatusFilter = v),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                      height: 18,
                                      width: 1,
                                      color: Colors.grey.shade300),
                                  const SizedBox(width: 12),
                                  _buildFilterChip(
                                    'All Depts',
                                    'ALL',
                                    _selectedDepartmentFilter,
                                    (v) => setState(
                                        () => _selectedDepartmentFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'Software Engineering',
                                    'Software Engineering',
                                    _selectedDepartmentFilter,
                                    (v) => setState(
                                        () => _selectedDepartmentFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'Product & UI/UX',
                                    'Product & UI/UX',
                                    _selectedDepartmentFilter,
                                    (v) => setState(
                                        () => _selectedDepartmentFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'DevOps & Cloud',
                                    'DevOps & Cloud',
                                    _selectedDepartmentFilter,
                                    (v) => setState(
                                        () => _selectedDepartmentFilter = v),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildFilterChip(
                                    'Quality Assurance (QA)',
                                    'Quality Assurance (QA)',
                                    _selectedDepartmentFilter,
                                    (v) => setState(
                                        () => _selectedDepartmentFilter = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Attendance List Items
                      Expanded(
                        child: fullList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    'No active employees found in your company.',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              )
                            : filteredList.isEmpty
                                ? Center(
                                    child: Text(
                                      'No records matching search and filters.',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filteredList.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final item = filteredList[index];
                                      return _AttendanceRecordCard(item: item);
                                    },
                                  ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelected,
  ) {
    final isSelected = currentValue.toUpperCase() == value.toUpperCase();
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

class _EmployeeAttendanceStatus {
  final UserProfile employee;
  final Attendance? attendance;
  final LeaveRequest? leaveRequest;
  final String status; // PRESENT, LATE, HALF_DAY, LEAVE, ABSENT

  _EmployeeAttendanceStatus({
    required this.employee,
    required this.attendance,
    this.leaveRequest,
    required this.status,
  });
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: color.shade800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DatePresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DatePresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final _EmployeeAttendanceStatus item;

  const _AttendanceRecordCard({required this.item});

  Color _getStatusColor() {
    switch (item.status.toUpperCase()) {
      case 'PRESENT':
        return Colors.green;
      case 'LATE':
        return Colors.orange;
      case 'HALF_DAY':
        return Colors.indigo;
      case 'LEAVE':
        return Colors.teal;
      case 'ABSENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final emp = item.employee;
    final att = item.attendance;
    final leave = item.leaveRequest;
    final bool isOnLeave = item.status == 'LEAVE';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Text(
                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name & Employee Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          emp.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (emp.employeeId.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            emp.employeeId,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${emp.designation} • ${emp.department}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Timing / Leave Details
                  if (att != null)
                    Row(
                      children: [
                        Text(
                          'In: ${att.formattedClockIn}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Out: ${att.formattedClockOut}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '(${att.formattedWorkingDuration})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else if (isOnLeave && leave != null)
                    Row(
                      children: [
                        Icon(Icons.beach_access, size: 14, color: Colors.teal.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'On ${leave.displayLeaveType} (${leave.formattedDateRange})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'No check-in record for this date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
