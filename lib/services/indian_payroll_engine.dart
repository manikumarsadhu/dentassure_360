class PayrollBreakdown {
  final double basic;
  final double hra;
  final double allowances;
  final double gross;
  final double pfWages;
  final bool pfCeilingApplied;
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
  final String taxRegime;
  final int remainingMonths;

  const PayrollBreakdown({
    required this.basic,
    required this.hra,
    required this.allowances,
    required this.gross,
    required this.pfWages,
    required this.pfCeilingApplied,
    required this.employeePf,
    required this.employerPf,
    required this.employerEps,
    required this.employerEpf,
    required this.employeeEsi,
    required this.employerEsi,
    required this.tds,
    required this.taxableAnnual,
    required this.annualTaxEstimate,
    required this.deductions,
    required this.netPay,
    required this.ctcMonthly,
    this.taxRegime = 'NEW',
    this.remainingMonths = 12,
  });
}

/// Statutory Indian payroll for v1: EPF, ESI, new-regime TDS (Budget 2025).
class IndianPayrollEngine {
  static const pfEmployeeRate = 0.12;
  static const pfEmployerRate = 0.12;
  static const epsRate = 0.0833;
  static const statutoryPfCeiling = 15000.0;
  static const maxMonthlyEps = 1250.0;
  static const esiGrossLimit = 21000.0;
  static const employeeEsiRate = 0.0075;
  static const employerEsiRate = 0.0325;
  static const standardDeduction = 75000.0;
  static const rebate87ALimit = 1200000.0;
  static const cessRate = 0.04;

  static const List<(double cap, double rate)> newRegimeSlabs = [
    (400000, 0),
    (800000, 0.05),
    (1200000, 0.10),
    (1600000, 0.15),
    (2000000, 0.20),
    (2400000, 0.25),
    (double.infinity, 0.30),
  ];

  static PayrollBreakdown compute({
    required double monthlySalary,
    required String month,
    bool pfRestrictToStatutoryCeiling = true,
    double ytdGross = 0,
    double ytdTds = 0,
  }) {
    final salary = monthlySalary < 0 ? 0.0 : monthlySalary;
    final basic = _inr(salary * 0.5);
    final hra = _inr(salary * 0.2);
    final allowances = _inr(salary * 0.3);
    final gross = _inr(basic + hra + allowances);

    final ceilingOn = pfRestrictToStatutoryCeiling;
    final pfWages = ceilingOn
        ? (basic < statutoryPfCeiling ? basic : statutoryPfCeiling)
        : basic;
    final employeePf = _inr(pfWages * pfEmployeeRate);
    final employerPf = _inr(pfWages * pfEmployerRate);
    final rawEps = pfWages * epsRate;
    final employerEps = _inr(rawEps > maxMonthlyEps ? maxMonthlyEps : rawEps);
    final employerEpf = _inr(employerPf - employerEps);

    final esiApplies = gross <= esiGrossLimit && gross > 0;
    final employeeEsi = esiApplies ? _inr(gross * employeeEsiRate) : 0.0;
    final employerEsi = esiApplies ? _inr(gross * employerEsiRate) : 0.0;

    final remaining = remainingMonthsIncluding(month);
    final estimatedAnnualGross = ytdGross + gross * remaining;
    final taxableAnnual =
        (estimatedAnnualGross - standardDeduction).clamp(0.0, double.infinity);
    final annualTax = annualNewRegimeTax(taxableAnnual);
    final tds = remaining <= 0
        ? 0.0
        : _inr(((annualTax - ytdTds) / remaining).clamp(0.0, double.infinity));

    final deductions = _inr(employeePf + employeeEsi + tds);
    final netPay = _inr(gross - deductions);
    final ctcMonthly = _inr(gross + employerPf + employerEsi);

    return PayrollBreakdown(
      basic: basic,
      hra: hra,
      allowances: allowances,
      gross: gross,
      pfWages: pfWages,
      pfCeilingApplied: ceilingOn && basic > statutoryPfCeiling,
      employeePf: employeePf,
      employerPf: employerPf,
      employerEps: employerEps,
      employerEpf: employerEpf,
      employeeEsi: employeeEsi,
      employerEsi: employerEsi,
      tds: tds,
      taxableAnnual: _inr(taxableAnnual),
      annualTaxEstimate: annualTax,
      deductions: deductions,
      netPay: netPay,
      ctcMonthly: ctcMonthly,
      remainingMonths: remaining,
    );
  }

  /// Income-tax + surcharge + 4% cess, after 87A rebate and marginal relief.
  static double annualNewRegimeTax(double taxableIncome) {
    final taxable = taxableIncome < 0 ? 0.0 : taxableIncome;
    final slabTax = _slabTax(taxable);
    double afterRebate;
    if (taxable <= rebate87ALimit) {
      afterRebate = 0;
    } else {
      final excess = taxable - rebate87ALimit;
      afterRebate = slabTax < excess ? slabTax : excess;
    }
    final sur = _surcharge(afterRebate, taxable);
    final cess = (afterRebate + sur) * cessRate;
    return _inr(afterRebate + sur + cess);
  }

  static double _slabTax(double taxable) {
    var tax = 0.0;
    var prev = 0.0;
    for (final (cap, rate) in newRegimeSlabs) {
      if (taxable <= prev) break;
      final top = taxable < cap ? taxable : cap;
      final slice = top - prev;
      if (slice > 0) tax += slice * rate;
      prev = cap;
      if (taxable <= cap) break;
    }
    return tax;
  }

  static double _surcharge(double tax, double taxable) {
    if (taxable <= 5000000 || tax <= 0) return 0;
    final rate = taxable <= 10000000
        ? 0.10
        : taxable <= 20000000
            ? 0.15
            : 0.25;
    return tax * rate;
  }

  static int fyStartYear(String month) {
    final parsed = _parseMonth(month);
    return parsed.month >= 4 ? parsed.year : parsed.year - 1;
  }

  static String fyLabel(String month) {
    final start = fyStartYear(month);
    final end = (start + 1) % 100;
    return 'FY $start–${end.toString().padLeft(2, '0')}';
  }

  static bool monthInFy(String month, int fyStart) {
    return fyStartYear(month) == fyStart;
  }

  /// Apr → 12, May → 11, … Mar → 1.
  static int remainingMonthsIncluding(String month) {
    final m = _parseMonth(month).month;
    if (m >= 4) return 16 - m;
    return 4 - m;
  }

  static ({double gross, double tds}) ytdFromSlips({
    required List<YtdSlip> slips,
    required String uid,
    required String month,
  }) {
    final fy = fyStartYear(month);
    var gross = 0.0;
    var tds = 0.0;
    for (final slip in slips) {
      if (slip.uid != uid) continue;
      if (slip.month == month) continue;
      if (!monthInFy(slip.month, fy)) continue;
      gross += slip.gross;
      tds += slip.tds;
    }
    return (gross: gross, tds: tds);
  }

  static String monthTitle(String month) {
    final parsed = _parseMonth(month);
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final name = parsed.month >= 1 && parsed.month <= 12
        ? names[parsed.month - 1]
        : month;
    return '$name, ${parsed.year}';
  }

  static int calendarDaysInMonth(String month) {
    final parsed = _parseMonth(month);
    return DateTime(parsed.year, parsed.month + 1, 0).day;
  }

  static String rupeesInWords(num amount) {
    final n = amount.round();
    if (n == 0) return 'Rupees Zero Only';
    return 'Rupees ${_indianWords(n)} Only';
  }

  static String _indianWords(int n) {
    if (n >= 10000000) {
      final cr = n ~/ 10000000;
      final rest = n % 10000000;
      return '${_belowThousand(cr)} Crore${rest == 0 ? '' : ' ${_indianWords(rest)}'}';
    }
    if (n >= 100000) {
      final l = n ~/ 100000;
      final rest = n % 100000;
      return '${_belowThousand(l)} Lakh${rest == 0 ? '' : ' ${_indianWords(rest)}'}';
    }
    if (n >= 1000) {
      final t = n ~/ 1000;
      final rest = n % 1000;
      return '${_belowThousand(t)} Thousand${rest == 0 ? '' : ' ${_indianWords(rest)}'}';
    }
    return _belowThousand(n);
  }

  static const _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  static const _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String _belowThousand(int n) {
    if (n <= 0) return '';
    if (n < 20) return _ones[n];
    if (n < 100) {
      final unit = n % 10;
      return '${_tens[n ~/ 10]}${unit == 0 ? '' : ' ${_ones[unit]}'}';
    }
    final rem = n % 100;
    return '${_ones[n ~/ 100]} Hundred${rem == 0 ? '' : ' ${_belowThousand(rem)}'}';
  }

  static double _inr(num value) => value.roundToDouble();

  static ({int year, int month}) _parseMonth(String month) {
    final parts = month.split('-');
    final year = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 2026;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
    return (year: year, month: m.clamp(1, 12));
  }
}

class YtdSlip {
  final String uid;
  final String month;
  final double gross;
  final double tds;

  const YtdSlip({
    required this.uid,
    required this.month,
    required this.gross,
    required this.tds,
  });
}
