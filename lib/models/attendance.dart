import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String uid;
  final String companyId;
  final String employeeId;
  final String employeeName;
  final String department;
  final String date; // YYYY-MM-DD
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String status; // PRESENT, LATE, HALF_DAY, ABSENT
  final int workingMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attendance({
    required this.id,
    required this.uid,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    this.department = 'General',
    required this.date,
    this.clockIn,
    this.clockOut,
    this.status = 'PRESENT',
    this.workingMinutes = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isClockedIn => clockIn != null && clockOut == null;
  bool get isCompleted => clockIn != null && clockOut != null;

  bool get isPresent => status.toUpperCase() == 'PRESENT';
  bool get isLate => status.toUpperCase() == 'LATE';
  bool get isHalfDay => status.toUpperCase() == 'HALF_DAY';
  bool get isAbsent => status.toUpperCase() == 'ABSENT';

  /// Formatted working duration like "8h 03m"
  String get formattedWorkingDuration {
    final minutes = workingMinutes > 0
        ? workingMinutes
        : (isClockedIn && clockIn != null
            ? DateTime.now().difference(clockIn!).inMinutes
            : 0);

    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  /// Formatted clock in time (e.g. 09:02 AM)
  String get formattedClockIn {
    if (clockIn == null) return '—';
    return _formatTimeOfDay(clockIn!);
  }

  /// Formatted clock out time (e.g. 06:05 PM)
  String get formattedClockOut {
    if (clockOut == null) return '—';
    return _formatTimeOfDay(clockOut!);
  }

  static String _formatTimeOfDay(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
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
      'date': date,
      'clockIn': clockIn != null ? Timestamp.fromDate(clockIn!) : null,
      'clockOut': clockOut != null ? Timestamp.fromDate(clockOut!) : null,
      'status': status,
      'workingMinutes': workingMinutes,
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

    return Attendance(
      id: docId ?? map['id'] ?? '',
      uid: map['uid'] ?? '',
      companyId: map['companyId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      department: map['department'] ?? 'General',
      date: map['date'] ?? '',
      clockIn: parseDate(map['clockIn']),
      clockOut: parseDate(map['clockOut']),
      status: map['status'] ?? 'PRESENT',
      workingMinutes: (map['workingMinutes'] as num?)?.toInt() ?? 0,
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
    String? date,
    DateTime? clockIn,
    DateTime? clockOut,
    String? status,
    int? workingMinutes,
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
      date: date ?? this.date,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      status: status ?? this.status,
      workingMinutes: workingMinutes ?? this.workingMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
