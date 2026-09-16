import 'package:cloud_firestore/cloud_firestore.dart';

class PerformanceGoal {
  final String id;
  final String companyId;
  final String uid;
  final String employeeName;
  final String reportingManagerUid;
  final String title;
  final String description;
  final String cycle;
  final String status;
  final int rating;
  final String reviewComment;
  final String reviewerUid;
  final String reviewerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PerformanceGoal({
    required this.id,
    required this.companyId,
    required this.uid,
    required this.employeeName,
    this.reportingManagerUid = '',
    required this.title,
    this.description = '',
    this.cycle = '',
    this.status = 'OPEN',
    this.rating = 0,
    this.reviewComment = '',
    this.reviewerUid = '',
    this.reviewerName = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isDone => status.toUpperCase() == 'DONE';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'uid': uid,
      'employeeName': employeeName,
      'reportingManagerUid': reportingManagerUid,
      'title': title,
      'description': description,
      'cycle': cycle,
      'status': status,
      'rating': rating,
      'reviewComment': reviewComment,
      'reviewerUid': reviewerUid,
      'reviewerName': reviewerName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory PerformanceGoal.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PerformanceGoal(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      uid: map['uid'] ?? '',
      employeeName: map['employeeName'] ?? '',
      reportingManagerUid: map['reportingManagerUid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      cycle: map['cycle'] ?? '',
      status: map['status'] ?? 'OPEN',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      reviewComment: map['reviewComment'] ?? '',
      reviewerUid: map['reviewerUid'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
