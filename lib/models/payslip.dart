import 'package:cloud_firestore/cloud_firestore.dart';

class Payslip {
  final String id;
  final String companyId;
  final String uid;
  final String employeeName;
  final String month;
  final double basic;
  final double hra;
  final double allowances;
  final double deductions;
  final double netPay;
  final String status;
  final DateTime? createdAt;

  Payslip({
    required this.id,
    required this.companyId,
    required this.uid,
    required this.employeeName,
    required this.month,
    required this.basic,
    required this.hra,
    required this.allowances,
    required this.deductions,
    required this.netPay,
    this.status = 'ISSUED',
    this.createdAt,
  });

  factory Payslip.fromSalary({
    required String id,
    required String companyId,
    required String uid,
    required String employeeName,
    required String month,
    required double monthlySalary,
  }) {
    final basic = monthlySalary * 0.5;
    final hra = monthlySalary * 0.2;
    final allowances = monthlySalary * 0.3;
    final deductions = basic * 0.12;
    return Payslip(
      id: id,
      companyId: companyId,
      uid: uid,
      employeeName: employeeName,
      month: month,
      basic: basic,
      hra: hra,
      allowances: allowances,
      deductions: deductions,
      netPay: basic + hra + allowances - deductions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'uid': uid,
      'employeeName': employeeName,
      'month': month,
      'basic': basic,
      'hra': hra,
      'allowances': allowances,
      'deductions': deductions,
      'netPay': netPay,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Payslip.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Payslip(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      uid: map['uid'] ?? '',
      employeeName: map['employeeName'] ?? '',
      month: map['month'] ?? '',
      basic: (map['basic'] as num?)?.toDouble() ?? 0,
      hra: (map['hra'] as num?)?.toDouble() ?? 0,
      allowances: (map['allowances'] as num?)?.toDouble() ?? 0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0,
      netPay: (map['netPay'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'ISSUED',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
