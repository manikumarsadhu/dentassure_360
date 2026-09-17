import 'package:flutter/material.dart';

import '../models/attendance.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../theme/app_motion.dart';
import 'live_now.dart';
import 'verified_punch_sheet.dart';

class ClockInCard extends StatefulWidget {
  final UserProfile user;

  const ClockInCard({super.key, required this.user});

  @override
  State<ClockInCard> createState() => _ClockInCardState();
}

class _ClockInCardState extends State<ClockInCard> {
  final _firestoreService = FirestoreService();
  bool _loading = false;

  Future<void> _clockIn() async {
    final capture = await showVerifiedPunchSheet(
      context: context,
      action: PunchAction.clockIn,
      workMode: widget.user.workMode,
    );
    if (capture == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await _firestoreService.clockIn(user: widget.user, capture: capture);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Clock-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clockOut(Attendance attendance) async {
    final capture = await showVerifiedPunchSheet(
      context: context,
      action: PunchAction.clockOut,
      workMode: widget.user.workMode,
    );
    if (capture == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await _firestoreService.clockOut(
        attendanceId: attendance.id,
        clockInTime: attendance.clockIn ?? DateTime.now(),
        capture: capture,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Clock-out failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startBreak(Attendance attendance, String type) async {
    setState(() => _loading = true);
    try {
      await _firestoreService.startBreak(
        attendanceId: attendance.id,
        type: type,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not start break: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _endBreak(Attendance attendance) async {
    setState(() => _loading = true);
    try {
      await _firestoreService.endBreak(attendanceId: attendance.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not end break: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Attendance?>(
      stream: _firestoreService.streamCurrentShiftAttendance(user: widget.user),
      builder: (context, snapshot) {
        final att = snapshot.data;
        final clockedIn = att?.isClockedIn == true;
        final onBreak = att?.isOnBreak == true;
        return FadeSlideIn(
          child: PressableScale(
            child: Card(
              elevation: 0,
              color: onBreak
                  ? Colors.amber.shade50
                  : clockedIn
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: onBreak
                      ? Colors.amber.shade200
                      : clockedIn
                      ? Colors.green.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          onBreak
                              ? Icons.free_breakfast_outlined
                              : clockedIn
                              ? Icons.timer_outlined
                              : Icons.login_rounded,
                          color: onBreak
                              ? Colors.amber.shade800
                              : clockedIn
                              ? Colors.green.shade800
                              : Colors.blue.shade800,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LiveClockText(
                                format: (now) => clockedIn
                                    ? onBreak
                                          ? 'On ${att!.activeBreak!.label} break · ${att.liveBreakLabel(now)}'
                                          : 'Worked ${att!.liveWorkedLabel(now)} · in at ${att.formattedClockInWithSeconds}'
                                    : att?.isCompleted == true
                                    ? 'Shift complete • ${att?.liveWorkedLabel(att.clockOut)}'
                                    : 'You have not clocked in yet',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                att?.status ?? 'ABSENT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (att != null && att.expectedMinutes > 0)
                                Text(
                                  'Expected ${att.formattedExpectedDuration}'
                                  '${att.overtimeMinutes > 0 ? ' · OT ${att.formattedOvertimeDuration}' : ''}'
                                  '${att.shortfallMinutes > 0 ? ' · short ${Attendance.formatDuration(Duration(minutes: att.shortfallMinutes))}' : ''}'
                                  ' · ${widget.user.workMode}/${widget.user.shiftType}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _loading
                              ? null
                              : clockedIn
                              ? () => _clockOut(att!)
                              : att?.isCompleted == true
                              ? null
                              : _clockIn,
                          child: Text(
                            clockedIn
                                ? 'Clock Out'
                                : att?.isCompleted == true
                                ? 'Done'
                                : 'Clock In',
                          ),
                        ),
                      ],
                    ),
                    if (att?.clockInCapture != null ||
                        att?.clockOutCapture != null)
                      PunchProofRow(
                        clockIn: att?.clockInCapture,
                        clockOut: att?.clockOutCapture,
                        compact: true,
                      ),
                    if (clockedIn) ...[
                      const SizedBox(height: 12),
                      if (onBreak)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : () => _endBreak(att!),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              'End ${att!.activeBreak!.label} & resume',
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () => _startBreak(att!, 'LUNCH'),
                              icon: const Icon(
                                Icons.restaurant_rounded,
                                size: 18,
                              ),
                              label: const Text('Lunch break'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () => _startBreak(att!, 'OTHER'),
                              icon: const Icon(Icons.coffee_rounded, size: 18),
                              label: const Text('Other break'),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
