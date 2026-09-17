import 'package:cloud_firestore/cloud_firestore.dart';

import 'punch_capture.dart';

class AttendanceBreak {
  final String id;
  final String type; // LUNCH, OTHER
  final DateTime start;
  final DateTime? end;

  AttendanceBreak({
    required this.id,
    required this.type,
    required this.start,
    this.end,
  });

  bool get isActive => end == null;
  bool get isLunch => type.toUpperCase() == 'LUNCH';

  String get label => isLunch ? 'Lunch' : 'Break';

  Duration duration([DateTime? now]) {
    final until = end ?? now ?? DateTime.now();
    final value = until.difference(start);
    return value.isNegative ? Duration.zero : value;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'start': Timestamp.fromDate(start),
      'end': end != null ? Timestamp.fromDate(end!) : null,
    };
  }

  factory AttendanceBreak.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AttendanceBreak(
      id: map['id'] ?? '',
      type: (map['type'] ?? 'OTHER').toString().toUpperCase(),
      start: parseDate(map['start']) ?? DateTime.now(),
      end: parseDate(map['end']),
    );
  }

  AttendanceBreak copyWith({
    String? id,
    String? type,
    DateTime? start,
    DateTime? end,
  }) {
    return AttendanceBreak(
      id: id ?? this.id,
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class Attendance {
  final String id;
  final String uid;
  final String companyId;
  final String employeeId;
  final String employeeName;
  final String department;
  final String reportingManagerUid;
  final String date; // YYYY-MM-DD
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String status; // PRESENT, LATE, HALF_DAY, ABSENT
  final int workingMinutes;
  final List<AttendanceBreak> breaks;
  final PunchCapture? clockInCapture;
  final PunchCapture? clockOutCapture;
  final int expectedMinutes;
  final int overtimeMinutes;
  final int shortfallMinutes;
  final String workMode;
  final String shiftType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attendance({
    required this.id,
    required this.uid,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    this.department = 'General',
    this.reportingManagerUid = '',
    required this.date,
    this.clockIn,
    this.clockOut,
    this.status = 'PRESENT',
    this.workingMinutes = 0,
    this.breaks = const [],
    this.clockInCapture,
    this.clockOutCapture,
    this.expectedMinutes = 0,
    this.overtimeMinutes = 0,
    this.shortfallMinutes = 0,
    this.workMode = 'OFFICE',
    this.shiftType = 'DAY',
    this.createdAt,
    this.updatedAt,
  });

  bool get isClockedIn => clockIn != null && clockOut == null;
  bool get isCompleted => clockIn != null && clockOut != null;

  bool get isPresent => status.toUpperCase() == 'PRESENT';
  bool get isLate => status.toUpperCase() == 'LATE';
  bool get isHalfDay => status.toUpperCase() == 'HALF_DAY';
  bool get isAbsent => status.toUpperCase() == 'ABSENT';

  AttendanceBreak? get activeBreak {
    for (final item in breaks) {
      if (item.isActive) return item;
    }
    return null;
  }

  bool get isOnBreak => isClockedIn && activeBreak != null;

  Duration breakDuration([DateTime? now]) {
    return breaks.fold(
      Duration.zero,
      (total, item) => total + item.duration(now),
    );
  }

  Duration netWorkedDuration([DateTime? now]) {
    if (clockIn == null) return Duration.zero;
    final n = now ?? DateTime.now();
    final end = clockOut ?? n;
    var total = end.difference(clockIn!);
    if (total.isNegative) total = Duration.zero;
    final breaksTotal = breakDuration(clockOut ?? n);
    final net = total - breaksTotal;
    return net.isNegative ? Duration.zero : net;
  }

  String get formattedExpectedDuration =>
      formatDuration(Duration(minutes: expectedMinutes));

  String get formattedOvertimeDuration =>
      formatDuration(Duration(minutes: overtimeMinutes));

  /// Formatted working duration like "8h 03m"
  String get formattedWorkingDuration {
    if (workingMinutes > 0) {
      return formatDuration(Duration(minutes: workingMinutes));
    }
    return formatDuration(netWorkedDuration());
  }

  String liveWorkedLabel([DateTime? now]) {
    return formatDuration(netWorkedDuration(now), includeSeconds: true);
  }

  String liveBreakLabel([DateTime? now]) {
    final current = activeBreak;
    if (current != null) {
      return formatDuration(current.duration(now), includeSeconds: true);
    }
    return formatDuration(breakDuration(now), includeSeconds: true);
  }

  /// Formatted clock in time (e.g. 09:02 AM)
  String get formattedClockIn {
    if (clockIn == null) return '—';
    return _formatTimeOfDay(clockIn!);
  }

  String get formattedClockInWithSeconds {
    if (clockIn == null) return '—';
    return _formatTimeOfDay(clockIn!, includeSeconds: true);
  }

  /// Formatted clock out time (e.g. 06:05 PM)
  String get formattedClockOut {
    if (clockOut == null) return '—';
    return _formatTimeOfDay(clockOut!);
  }

  String get formattedClockOutWithSeconds {
    if (clockOut == null) return '—';
    return _formatTimeOfDay(clockOut!, includeSeconds: true);
  }

  static String formatDuration(
    Duration duration, {
    bool includeSeconds = false,
  }) {
    var seconds = duration.inSeconds;
    if (seconds < 0) seconds = 0;
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (!includeSeconds) {
      if (hours == 0) return '${mins}m';
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    if (hours == 0) {
      return '${mins}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${hours}h ${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
  }

  static String _formatTimeOfDay(DateTime dt, {bool includeSeconds = false}) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hm = '${displayHour.toString().padLeft(2, '0')}:$minute';
    if (includeSeconds) return '$hm:$second $period';
    return '$hm $period';
  }

  static String formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'companyId': companyId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': department,
      'reportingManagerUid': reportingManagerUid,
      'date': date,
      'clockIn': clockIn != null ? Timestamp.fromDate(clockIn!) : null,
      'clockOut': clockOut != null ? Timestamp.fromDate(clockOut!) : null,
      'status': status,
      'workingMinutes': workingMinutes,
      'breaks': breaks.map((b) => b.toMap()).toList(),
      'clockInCapture': clockInCapture?.toMap(),
      'clockOutCapture': clockOutCapture?.toMap(),
      'expectedMinutes': expectedMinutes,
      'overtimeMinutes': overtimeMinutes,
      'shortfallMinutes': shortfallMinutes,
      'workMode': workMode,
      'shiftType': shiftType,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawBreaks = map['breaks'];
    final parsedBreaks = <AttendanceBreak>[];
    if (rawBreaks is List) {
      for (final item in rawBreaks) {
        if (item is Map<String, dynamic>) {
          parsedBreaks.add(AttendanceBreak.fromMap(item));
        } else if (item is Map) {
          parsedBreaks.add(
            AttendanceBreak.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return Attendance(
      id: docId ?? map['id'] ?? '',
      uid: map['uid'] ?? '',
      companyId: map['companyId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      department: map['department'] ?? 'General',
      reportingManagerUid: map['reportingManagerUid'] ?? '',
      date: map['date'] ?? '',
      clockIn: parseDate(map['clockIn']),
      clockOut: parseDate(map['clockOut']),
      status: map['status'] ?? 'PRESENT',
      workingMinutes: (map['workingMinutes'] as num?)?.toInt() ?? 0,
      breaks: parsedBreaks,
      clockInCapture: PunchCapture.tryParse(map['clockInCapture']),
      clockOutCapture: PunchCapture.tryParse(map['clockOutCapture']),
      expectedMinutes: (map['expectedMinutes'] as num?)?.toInt() ?? 0,
      overtimeMinutes: (map['overtimeMinutes'] as num?)?.toInt() ?? 0,
      shortfallMinutes: (map['shortfallMinutes'] as num?)?.toInt() ?? 0,
      workMode: (map['workMode'] ?? 'OFFICE').toString(),
      shiftType: (map['shiftType'] ?? 'DAY').toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Attendance copyWith({
    String? id,
    String? uid,
    String? companyId,
    String? employeeId,
    String? employeeName,
    String? department,
    String? reportingManagerUid,
    String? date,
    DateTime? clockIn,
    DateTime? clockOut,
    String? status,
    int? workingMinutes,
    List<AttendanceBreak>? breaks,
    PunchCapture? clockInCapture,
    PunchCapture? clockOutCapture,
    int? expectedMinutes,
    int? overtimeMinutes,
    int? shortfallMinutes,
    String? workMode,
    String? shiftType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      companyId: companyId ?? this.companyId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      reportingManagerUid: reportingManagerUid ?? this.reportingManagerUid,
      date: date ?? this.date,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      status: status ?? this.status,
      workingMinutes: workingMinutes ?? this.workingMinutes,
      breaks: breaks ?? this.breaks,
      clockInCapture: clockInCapture ?? this.clockInCapture,
      clockOutCapture: clockOutCapture ?? this.clockOutCapture,
      expectedMinutes: expectedMinutes ?? this.expectedMinutes,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      shortfallMinutes: shortfallMinutes ?? this.shortfallMinutes,
      workMode: workMode ?? this.workMode,
      shiftType: shiftType ?? this.shiftType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
