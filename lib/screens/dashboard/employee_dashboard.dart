import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../attendance/employee_attendance_history_screen.dart';
import '../leave/employee_leave_screen.dart';
import '../profile/my_profile_screen.dart';
import '../timesheet/timesheet_screen.dart';
import '../expenses/expenses_screen.dart';
import '../assets/assets_screen.dart';
import '../payslips/payslips_screen.dart';
import '../letters/letters_screen.dart';
import '../../widgets/live_now.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/user_avatar.dart';
import '../../theme/app_motion.dart';
import '../../widgets/verified_punch_sheet.dart';

class EmployeeDashboard extends StatefulWidget {
  final UserProfile userProfile;

  const EmployeeDashboard({super.key, required this.userProfile});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatDateHeader(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
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
      'Dec',
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}, ${dt.year}';
  }

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
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.streamUserProfile(widget.userProfile.uid),
      initialData: widget.userProfile,
      builder: (context, profileSnapshot) {
        final user = profileSnapshot.data ?? widget.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const AppHeaderLogo(height: 36, maxWidth: 158),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.companyName.isNotEmpty
                            ? user.companyName
                            : 'Workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${user.designation} • ${user.department}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  tooltip: 'My Profile',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyProfileScreen(userProfile: user),
                      ),
                    );
                  },
                  icon: UserAvatar(
                    avatarUrl: user.avatarUrl,
                    name: user.name,
                    radius: 16,
                    fontSize: 13,
                  ),
                ),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting Banner
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, ${user.name.split(' ').first} 👋',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateHeader(DateTime.now()),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _EmployeeShiftPanel(user: user),
                  const SizedBox(height: 24),

                  // Workspace Quick Actions
                  Text(
                    'My Workspace',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _workspaceCard(
                    index: 0,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(
                        Icons.history_rounded,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: 'Attendance History',
                    subtitle: 'View daily logs and working hours',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EmployeeAttendanceHistoryScreen(employee: user),
                        ),
                      );
                    },
                  ),
                  _workspaceCard(
                    index: 1,
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade50,
                      child: Icon(
                        Icons.event_available_rounded,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    title: 'Leave Applications',
                    subtitle: 'Request time off or check leave balance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeLeaveScreen(employee: user),
                        ),
                      );
                    },
                  ),
                  _workspaceCard(
                    index: 2,
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: Icon(
                        Icons.timer_outlined,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    title: 'My Timesheet',
                    subtitle: 'Log project hours',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TimesheetScreen(viewer: user, personalOnly: true),
                        ),
                      );
                    },
                  ),
                  _workspaceCard(
                    index: 3,
                    leading: CircleAvatar(
                      backgroundColor: Colors.brown.shade50,
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.brown.shade700,
                      ),
                    ),
                    title: 'My Expenses',
                    subtitle: 'Submit and track claims',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExpensesScreen(viewer: user, personalOnly: true),
                        ),
                      );
                    },
                  ),
                  _workspaceCard(
                    index: 4,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey.shade50,
                      child: Icon(
                        Icons.devices_outlined,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                    title: 'My Assets',
                    subtitle: 'Laptops, SIMs and ID cards assigned to you',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssetsScreen(viewer: user),
                        ),
                      );
                    },
                  ),
                  _workspaceCard(
                    index: 5,
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Icon(
                        Icons.payments_outlined,
                        color: Colors.green.shade700,
                      ),
                    ),
                    title: 'My Payslips',
                    subtitle: 'View issued salary slips',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PayslipsScreen(viewer: user),
                        ),
                      );
                    },
                  ),
                  _workspaceCard(
                    index: 6,
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: Icon(
                        Icons.mail_outline,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    title: 'My Letters',
                    subtitle: 'Offer and increment letters',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LettersScreen(
                            viewer: user,
                            personalOnly: true,
                            embedded: false,
                          ),
                        ),
                      );
                    },
                  ),
                  _workspaceCard(
                    index: 7,
                    leading: user.avatarUrl.isNotEmpty
                        ? UserAvatar(
                            avatarUrl: user.avatarUrl,
                            name: user.name,
                            radius: 20,
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.teal.shade50,
                            child: Icon(
                              Icons.badge_outlined,
                              color: Colors.teal.shade700,
                            ),
                          ),
                    title: 'My Profile Details',
                    subtitle:
                        'ID: ${user.employeeId.isNotEmpty ? user.employeeId : user.uid.substring(0, 8)} • ${user.email}',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyProfileScreen(userProfile: user),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _workspaceCard({
    required int index,
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MotionCard(
        delay: Duration(milliseconds: 40 * index),
        child: Card(
          child: ListTile(
            leading: leading,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _EmployeeShiftPanel extends StatefulWidget {
  final UserProfile user;

  const _EmployeeShiftPanel({required this.user});

  @override
  State<_EmployeeShiftPanel> createState() => _EmployeeShiftPanelState();
}

class _EmployeeShiftPanelState extends State<_EmployeeShiftPanel> {
  final _firestoreService = FirestoreService();
  bool _actionLoading = false;

  String _formatLiveTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute:$second $period';
  }

  Future<void> _clockIn() async {
    final capture = await showVerifiedPunchSheet(
      context: context,
      action: PunchAction.clockIn,
      workMode: widget.user.workMode,
    );
    if (capture == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      final record = await _firestoreService.clockIn(
        user: widget.user,
        capture: capture,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            record.isLate
                ? 'Clocked in (late against your shift start + grace).'
                : 'Clocked in successfully! Have a great shift.',
          ),
          backgroundColor: record.isLate
              ? Colors.orange.shade800
              : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clock in failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _clockOut(Attendance attendance) async {
    if (attendance.clockIn == null) return;

    final capture = await showVerifiedPunchSheet(
      context: context,
      action: PunchAction.clockOut,
      workMode: widget.user.workMode,
    );
    if (capture == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      final record = await _firestoreService.clockOut(
        attendanceId: attendance.id,
        clockInTime: attendance.clockIn!,
        capture: capture,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clocked out successfully! Total working time: ${record.formattedWorkingDuration}',
          ),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clock out failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _startBreak(Attendance attendance, String type) async {
    if (!attendance.isClockedIn) return;
    setState(() => _actionLoading = true);
    try {
      await _firestoreService.startBreak(
        attendanceId: attendance.id,
        type: type,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start break: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _endBreak(Attendance attendance) async {
    setState(() => _actionLoading = true);
    try {
      await _firestoreService.endBreak(attendanceId: attendance.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not end break: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Attendance?>(
      stream: _firestoreService.streamCurrentShiftAttendance(user: widget.user),
      builder: (context, snapshot) {
        return _buildAttendanceCard(
          Theme.of(context),
          snapshot.data,
          widget.user,
        );
      },
    );
  }

  Widget _buildAttendanceCard(
    ThemeData theme,
    Attendance? attendance,
    UserProfile user,
  ) {
    final bool hasClockedIn = attendance != null && attendance.clockIn != null;
    final bool hasClockedOut =
        attendance != null && attendance.clockOut != null;

    // 1. COMPLETED STATE (Clocked Out)
    if (hasClockedIn && hasClockedOut) {
      return FadeSlideIn(
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.green.shade200),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Attendance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'STATUS: ${attendance.status}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PunchProofRow(
                  clockIn: attendance.clockInCapture,
                  clockOut: attendance.clockOutCapture,
                ),
                const SizedBox(height: 12),

                // Completed metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      label: 'Clock In',
                      value: attendance.formattedClockInWithSeconds,
                      color: Colors.green.shade700,
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    _SummaryItem(
                      label: 'Clock Out',
                      value: attendance.formattedClockOutWithSeconds,
                      color: Colors.orange.shade700,
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    _SummaryItem(
                      label: 'Working',
                      value: attendance.liveWorkedLabel(attendance.clockOut),
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (attendance.expectedMinutes > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Expected ${attendance.formattedExpectedDuration}'
                      '${attendance.overtimeMinutes > 0 ? ' · OT ${attendance.formattedOvertimeDuration}' : ''}'
                      '${attendance.shortfallMinutes > 0 ? ' · short ${Attendance.formatDuration(Duration(minutes: attendance.shortfallMinutes))}' : ''}'
                      ' · ${attendance.workMode}/${attendance.shiftType}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (attendance.breaks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Breaks: ${attendance.liveBreakLabel(attendance.clockOut)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Shift completed for today! 🎉',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
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
    if (hasClockedIn && !hasClockedOut) {
      final isLate = attendance.isLate;
      final onBreak = attendance.isOnBreak;
      final activeBreak = attendance.activeBreak;
      final accent = onBreak
          ? Colors.amber
          : (isLate ? Colors.orange : Colors.blue);

      return FadeSlideIn(
        child: Card(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [accent.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: onBreak
                                  ? Colors.amber.shade700
                                  : (isLate ? Colors.orange : Colors.green),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              onBreak
                                  ? 'Status: On ${activeBreak!.label} Break'
                                  : (isLate
                                        ? 'Status: Late (Working)'
                                        : 'Status: Present'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: onBreak
                                    ? Colors.amber.shade900
                                    : (isLate
                                          ? Colors.orange.shade900
                                          : Colors.green.shade800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Since ${attendance.formattedClockInWithSeconds}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                PunchProofRow(
                  clockIn: attendance.clockInCapture,
                  clockOut: attendance.clockOutCapture,
                ),
                const SizedBox(height: 20),
                LiveClockText(
                  format: attendance.liveWorkedLabel,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: accent.shade900,
                  ),
                ),
                Text(
                  onBreak ? 'Time worked (paused)' : 'Time worked today',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (onBreak) ...[
                  const SizedBox(height: 8),
                  LiveClockText(
                    format: (now) =>
                        '${activeBreak!.label} break · ${attendance.liveBreakLabel(now)}',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (attendance.breaks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  LiveClockText(
                    format: (now) =>
                        'Breaks today: ${attendance.liveBreakLabel(now)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (onBreak)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _actionLoading
                          ? null
                          : () => _endBreak(attendance),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        'END ${activeBreak!.label.toUpperCase()} & RESUME',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _actionLoading
                              ? null
                              : () => _startBreak(attendance, 'LUNCH'),
                          icon: const Icon(Icons.restaurant_rounded),
                          label: const Text('Lunch break'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _actionLoading
                              ? null
                              : () => _startBreak(attendance, 'OTHER'),
                          icon: const Icon(Icons.coffee_rounded),
                          label: const Text('Other break'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _actionLoading
                        ? null
                        : () => _clockOut(attendance),
                    icon: _actionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text(
                      _actionLoading ? 'Processing...' : 'CLOCK OUT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeSlideIn(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50.withValues(alpha: 0.5),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Attendance",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Status: Not Clocked In',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              LiveClockText(
                format: _formatLiveTime,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'Current Time',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Clock In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _actionLoading ? null : _clockIn,
                  icon: _actionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    _actionLoading ? 'Clocking in...' : 'CLOCK IN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
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
