import 'package:cloud_firestore/cloud_firestore.dart';

class HrLetter {
  static const typeOffer = 'OFFER';
  static const typeIncrement = 'INCREMENT';

  final String id;
  final String type;
  final String companyId;
  final String companyName;
  final String companyAddress;
  final String uid;
  final String candidateId;
  final String recipientName;
  final String recipientEmail;
  final String designation;
  final String department;
  final double monthlySalary;
  final double previousSalary;
  final DateTime? joiningDate;
  final DateTime? effectiveDate;
  final String issuedByUid;
  final String issuedByName;
  final String status;
  final String body;
  final DateTime? createdAt;

  HrLetter({
    required this.id,
    required this.type,
    required this.companyId,
    this.companyName = '',
    this.companyAddress = '',
    this.uid = '',
    this.candidateId = '',
    required this.recipientName,
    this.recipientEmail = '',
    this.designation = '',
    this.department = '',
    this.monthlySalary = 0,
    this.previousSalary = 0,
    this.joiningDate,
    this.effectiveDate,
    this.issuedByUid = '',
    this.issuedByName = '',
    this.status = 'ISSUED',
    this.body = '',
    this.createdAt,
  });

  bool get isOffer => type.toUpperCase() == typeOffer;
  bool get isIncrement => type.toUpperCase() == typeIncrement;

  String get title =>
      isOffer ? 'Offer of Employment' : 'Salary Increment Letter';

  String get displayType => isOffer ? 'Offer letter' : 'Increment letter';

  String get pdfFilename {
    final slug = recipientName.trim().isEmpty
        ? 'Letter'
        : recipientName.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final date = formatIsoDate(createdAt ?? DateTime.now());
    return '${isOffer ? 'Offer' : 'Increment'}_${slug}_$date.pdf';
  }

  String renderBody() {
    final company = companyName.isNotEmpty ? companyName : 'the company';
    final role = designation.isNotEmpty ? designation : 'the offered role';
    final deptLine = department.trim().isEmpty
        ? ''
        : ' in the $department team';
    final issued = issuedByName.isNotEmpty ? issuedByName : 'Human Resources';
    final address = companyAddress.trim();

    if (isIncrement) {
      return [
        'Date: ${formatDisplayDate(createdAt ?? DateTime.now())}',
        '',
        'Dear ${recipientName.isNotEmpty ? recipientName : 'Team Member'},',
        '',
        'We are pleased to confirm a revision in your compensation for the role of $role.',
        '',
        'Your current monthly salary of ${formatInr(previousSalary)} will be revised to ${formatInr(monthlySalary)} with effect from ${formatDisplayDate(effectiveDate)}.',
        '',
        'All other terms of your employment remain unchanged.',
        '',
        'Yours sincerely,',
        issued,
        company,
        if (address.isNotEmpty) address,
      ].join('\n');
    }

    return [
      'Date: ${formatDisplayDate(createdAt ?? DateTime.now())}',
      '',
      'Dear ${recipientName.isNotEmpty ? recipientName : 'Candidate'},',
      '',
      'We are pleased to offer you the position of $role$deptLine at $company.',
      '',
      'Your monthly compensation will be ${formatInr(monthlySalary)} (CTC equivalent on a monthly basis). Your expected date of joining is ${formatDisplayDate(joiningDate)}.',
      '',
      'This offer is subject to verification of documents and successful completion of joining formalities. Kindly confirm your acceptance of this offer.',
      '',
      'We look forward to welcoming you to $company.',
      '',
      'Yours sincerely,',
      issued,
      company,
      if (address.isNotEmpty) address,
    ].join('\n');
  }

  HrLetter withRenderedBody() => copyWith(body: renderBody());

  static String formatIsoDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  static String formatDisplayDate(DateTime? dt) {
    if (dt == null) return 'the agreed date';
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String formatInr(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'companyId': companyId,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'uid': uid,
      'candidateId': candidateId,
      'recipientName': recipientName,
      'recipientEmail': recipientEmail,
      'designation': designation,
      'department': department,
      'monthlySalary': monthlySalary,
      'previousSalary': previousSalary,
      'joiningDate': joiningDate != null
          ? Timestamp.fromDate(joiningDate!)
          : null,
      'effectiveDate': effectiveDate != null
          ? Timestamp.fromDate(effectiveDate!)
          : null,
      'issuedByUid': issuedByUid,
      'issuedByName': issuedByName,
      'status': status,
      'body': body,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory HrLetter.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return HrLetter(
      id: docId ?? map['id'] ?? '',
      type: (map['type'] ?? typeOffer).toString().toUpperCase(),
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      companyAddress: map['companyAddress'] ?? '',
      uid: map['uid'] ?? '',
      candidateId: map['candidateId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientEmail: map['recipientEmail'] ?? '',
      designation: map['designation'] ?? '',
      department: map['department'] ?? '',
      monthlySalary: (map['monthlySalary'] as num?)?.toDouble() ?? 0,
      previousSalary: (map['previousSalary'] as num?)?.toDouble() ?? 0,
      joiningDate: parseDate(map['joiningDate']),
      effectiveDate: parseDate(map['effectiveDate']),
      issuedByUid: map['issuedByUid'] ?? '',
      issuedByName: map['issuedByName'] ?? '',
      status: map['status'] ?? 'ISSUED',
      body: map['body'] ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  HrLetter copyWith({
    String? id,
    String? type,
    String? companyId,
    String? companyName,
    String? companyAddress,
    String? uid,
    String? candidateId,
    String? recipientName,
    String? recipientEmail,
    String? designation,
    String? department,
    double? monthlySalary,
    double? previousSalary,
    DateTime? joiningDate,
    DateTime? effectiveDate,
    String? issuedByUid,
    String? issuedByName,
    String? status,
    String? body,
    DateTime? createdAt,
  }) {
    return HrLetter(
      id: id ?? this.id,
      type: type ?? this.type,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      uid: uid ?? this.uid,
      candidateId: candidateId ?? this.candidateId,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      previousSalary: previousSalary ?? this.previousSalary,
      joiningDate: joiningDate ?? this.joiningDate,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      issuedByUid: issuedByUid ?? this.issuedByUid,
      issuedByName: issuedByName ?? this.issuedByName,
      status: status ?? this.status,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
