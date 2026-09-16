import 'package:cloud_firestore/cloud_firestore.dart';

class TimesheetEntry {
  final String id;
  final String companyId;
  final String uid;
  final String employeeName;
  final String reportingManagerUid;
  final String date;
  final String project;
  final String task;
  final double hours;
  final bool billable;
  final String status;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TimesheetEntry({
    required this.id,
    required this.companyId,
    required this.uid,
    required this.employeeName,
    this.reportingManagerUid = '',
    required this.date,
    required this.project,
    this.task = '',
    required this.hours,
    this.billable = true,
    this.status = 'PENDING',
    this.reviewedBy,
    this.reviewedByName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'uid': uid,
      'employeeName': employeeName,
      'reportingManagerUid': reportingManagerUid,
      'date': date,
      'project': project,
      'task': task,
      'hours': hours,
      'billable': billable,
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory TimesheetEntry.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return TimesheetEntry(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      uid: map['uid'] ?? '',
      employeeName: map['employeeName'] ?? '',
      reportingManagerUid: map['reportingManagerUid'] ?? '',
      date: map['date'] ?? '',
      project: map['project'] ?? '',
      task: map['task'] ?? '',
      hours: (map['hours'] as num?)?.toDouble() ?? 0,
      billable: map['billable'] != false,
      status: map['status'] ?? 'PENDING',
      reviewedBy: map['reviewedBy'],
      reviewedByName: map['reviewedByName'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
