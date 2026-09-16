import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String id;
  final String companyId;
  final String uid;
  final String employeeId;
  final String employeeName;
  final String department;
  final String reportingManagerUid;
  final String leaveType; // CASUAL, SICK, ANNUAL, UNPAID
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final int totalDays;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED, CANCELLED

  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? reviewComment;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeaveRequest({
    required this.id,
    required this.companyId,
    required this.uid,
    required this.employeeId,
    required this.employeeName,
    this.department = 'General',
    this.reportingManagerUid = '',
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.status = 'PENDING',
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.reviewComment,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  /// Check if a specific date (YYYY-MM-DD) falls within this leave request
  bool coversDate(String dateKey) {
    return isApproved &&
        startDate.compareTo(dateKey) <= 0 &&
        endDate.compareTo(dateKey) >= 0;
  }

  /// Formats leave type to title case display (e.g. "Casual Leave")
  String get displayLeaveType {
    switch (leaveType.toUpperCase()) {
      case 'CASUAL':
        return 'Casual Leave';
      case 'SICK':
        return 'Sick Leave';
      case 'ANNUAL':
        return 'Annual Leave';
      case 'UNPAID':
        return 'Unpaid Leave';
      default:
        return '$leaveType Leave';
    }
  }

  /// Formatted date range like "Sep 18 – Sep 19" or "Sep 18, 2026"
  String get formattedDateRange {
    DateTime? parse(String d) => DateTime.tryParse(d);
    final s = parse(startDate);
    final e = parse(endDate);
    if (s == null) return '$startDate to $endDate';
    if (e == null || startDate == endDate) {
      return _formatSingleDate(s);
    }
    return '${_formatMonthDay(s)} – ${_formatMonthDay(e)}, ${e.year}';
  }

  static String _formatSingleDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _formatMonthDay(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  static String formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'uid': uid,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': department,
      'reportingManagerUid': reportingManagerUid,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'totalDays': totalDays,
      'reason': reason,
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewComment': reviewComment,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory LeaveRequest.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return LeaveRequest(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      uid: map['uid'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      department: map['department'] ?? 'General',
      reportingManagerUid: map['reportingManagerUid'] ?? '',
      leaveType: map['leaveType'] ?? 'CASUAL',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      totalDays: (map['totalDays'] as num?)?.toInt() ?? 1,
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'PENDING',
      reviewedBy: map['reviewedBy'],
      reviewedByName: map['reviewedByName'],
      reviewedAt: parseDate(map['reviewedAt']),
      reviewComment: map['reviewComment'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  LeaveRequest copyWith({
    String? id,
    String? companyId,
    String? uid,
    String? employeeId,
    String? employeeName,
    String? department,
    String? reportingManagerUid,
    String? leaveType,
    String? startDate,
    String? endDate,
    int? totalDays,
    String? reason,
    String? status,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? reviewComment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      reportingManagerUid: reportingManagerUid ?? this.reportingManagerUid,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewComment: reviewComment ?? this.reviewComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
