import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/indian_payroll_engine.dart';

class Payslip {
  final String id;
  final String companyId;
  final String uid;
  final String employeeName;
  final String employeeId;
  final String designation;
  final String department;
  final String month;
  final double basic;
  final double hra;
  final double allowances;
  final double gross;
  final double employeePf;
  final double employerPf;
  final double employerEps;
  final double employerEpf;
  final double employeeEsi;
  final double employerEsi;
  final double tds;
  final double taxableAnnual;
  final double annualTaxEstimate;
  final double deductions;
  final double netPay;
  final double ctcMonthly;
  final double pfWages;
  final bool pfCeilingApplied;
  final String taxRegime;
  final String status;
  final DateTime? createdAt;

  Payslip({
    required this.id,
    required this.companyId,
    required this.uid,
    required this.employeeName,
    this.employeeId = '',
    this.designation = '',
    this.department = '',
    required this.month,
    required this.basic,
    required this.hra,
    required this.allowances,
    this.gross = 0,
    this.employeePf = 0,
    this.employerPf = 0,
    this.employerEps = 0,
    this.employerEpf = 0,
    this.employeeEsi = 0,
    this.employerEsi = 0,
    this.tds = 0,
    this.taxableAnnual = 0,
    this.annualTaxEstimate = 0,
    required this.deductions,
    required this.netPay,
    this.ctcMonthly = 0,
    this.pfWages = 0,
    this.pfCeilingApplied = false,
    this.taxRegime = 'NEW',
    this.status = 'ISSUED',
    this.createdAt,
  });

  bool get isLegacy =>
      taxRegime.isEmpty ||
      (employeePf == 0 && employeeEsi == 0 && tds == 0 && gross == 0);

  double get resolvedGross =>
      gross > 0 ? gross : _inr(basic + hra + allowances);

  String get monthTitle => IndianPayrollEngine.monthTitle(month);

  String get fyLabel => IndianPayrollEngine.fyLabel(month);

  String get pdfFilename {
    final slug = employeeName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final name = slug.isEmpty ? 'Employee' : slug;
    return 'Payslip_${name}_$month.pdf';
  }

  factory Payslip.fromSalary({
    required String id,
    required String companyId,
    required String uid,
    required String employeeName,
    required String month,
    required double monthlySalary,
    String employeeId = '',
    String designation = '',
    String department = '',
    bool pfRestrictToStatutoryCeiling = true,
    double ytdGross = 0,
    double ytdTds = 0,
  }) {
    final calc = IndianPayrollEngine.compute(
      monthlySalary: monthlySalary,
      month: month,
      pfRestrictToStatutoryCeiling: pfRestrictToStatutoryCeiling,
      ytdGross: ytdGross,
      ytdTds: ytdTds,
    );
    return Payslip(
      id: id,
      companyId: companyId,
      uid: uid,
      employeeName: employeeName,
      employeeId: employeeId,
      designation: designation,
      department: department,
      month: month,
      basic: calc.basic,
      hra: calc.hra,
      allowances: calc.allowances,
      gross: calc.gross,
      employeePf: calc.employeePf,
      employerPf: calc.employerPf,
      employerEps: calc.employerEps,
      employerEpf: calc.employerEpf,
      employeeEsi: calc.employeeEsi,
      employerEsi: calc.employerEsi,
      tds: calc.tds,
      taxableAnnual: calc.taxableAnnual,
      annualTaxEstimate: calc.annualTaxEstimate,
      deductions: calc.deductions,
      netPay: calc.netPay,
      ctcMonthly: calc.ctcMonthly,
      pfWages: calc.pfWages,
      pfCeilingApplied: calc.pfCeilingApplied,
      taxRegime: calc.taxRegime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'uid': uid,
      'employeeName': employeeName,
      'employeeId': employeeId,
      'designation': designation,
      'department': department,
      'month': month,
      'basic': basic,
      'hra': hra,
      'allowances': allowances,
      'gross': resolvedGross,
      'employeePf': employeePf,
      'employerPf': employerPf,
      'employerEps': employerEps,
      'employerEpf': employerEpf,
      'employeeEsi': employeeEsi,
      'employerEsi': employerEsi,
      'tds': tds,
      'taxableAnnual': taxableAnnual,
      'annualTaxEstimate': annualTaxEstimate,
      'deductions': deductions,
      'netPay': netPay,
      'ctcMonthly': ctcMonthly,
      'pfWages': pfWages,
      'pfCeilingApplied': pfCeilingApplied,
      'taxRegime': taxRegime,
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

    double numOf(String key) => (map[key] as num?)?.toDouble() ?? 0;

    final basic = numOf('basic');
    final hra = numOf('hra');
    final allowances = numOf('allowances');
    final storedGross = numOf('gross');

    return Payslip(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      uid: map['uid'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employeeId: map['employeeId'] ?? '',
      designation: map['designation'] ?? '',
      department: map['department'] ?? '',
      month: map['month'] ?? '',
      basic: basic,
      hra: hra,
      allowances: allowances,
      gross: storedGross > 0 ? storedGross : _inr(basic + hra + allowances),
      employeePf: numOf('employeePf'),
      employerPf: numOf('employerPf'),
      employerEps: numOf('employerEps'),
      employerEpf: numOf('employerEpf'),
      employeeEsi: numOf('employeeEsi'),
      employerEsi: numOf('employerEsi'),
      tds: numOf('tds'),
      taxableAnnual: numOf('taxableAnnual'),
      annualTaxEstimate: numOf('annualTaxEstimate'),
      deductions: numOf('deductions'),
      netPay: numOf('netPay'),
      ctcMonthly: numOf('ctcMonthly'),
      pfWages: numOf('pfWages'),
      pfCeilingApplied: map['pfCeilingApplied'] == true,
      taxRegime: map['taxRegime'] ?? '',
      status: map['status'] ?? 'ISSUED',
      createdAt: parseDate(map['createdAt']),
    );
  }

  static double _inr(num value) => value.roundToDouble();
}
