import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseClaim {
  final String id;
  final String companyId;
  final String uid;
  final String employeeName;
  final String reportingManagerUid;
  final String title;
  final String category;
  final double amount;
  final String receiptDataUrl;
  final String date;
  final String status;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpenseClaim({
    required this.id,
    required this.companyId,
    required this.uid,
    required this.employeeName,
    this.reportingManagerUid = '',
    required this.title,
    this.category = 'General',
    required this.amount,
    this.receiptDataUrl = '',
    required this.date,
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
      'title': title,
      'category': category,
      'amount': amount,
      'receiptDataUrl': receiptDataUrl,
      'date': date,
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

  factory ExpenseClaim.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ExpenseClaim(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      uid: map['uid'] ?? '',
      employeeName: map['employeeName'] ?? '',
      reportingManagerUid: map['reportingManagerUid'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      receiptDataUrl: map['receiptDataUrl'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? 'PENDING',
      reviewedBy: map['reviewedBy'],
      reviewedByName: map['reviewedByName'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
