import 'package:flutter/material.dart';

import '../../models/company.dart';
import '../../models/payslip.dart';
import '../../models/user_profile.dart';
import '../../services/indian_payroll_engine.dart';
import '../../services/payslip_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

class PayslipPreviewScreen extends StatefulWidget {
  final Payslip payslip;
  final UserProfile viewer;
  final Company? company;
  final UserProfile? employee;

  const PayslipPreviewScreen({
    super.key,
    required this.payslip,
    required this.viewer,
    this.company,
    this.employee,
  });

  @override
  State<PayslipPreviewScreen> createState() => _PayslipPreviewScreenState();
}

class _PayslipPreviewScreenState extends State<PayslipPreviewScreen> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      await PayslipPdfService.download(
        payslip: widget.payslip,
        company: widget.company,
        employee: widget.employee,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payslip · ${widget.payslip.monthTitle}'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _busy ? null : _download,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: PayslipDocumentView(
                    payslip: widget.payslip,
                    company: widget.company,
                    employee: widget.employee,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _download,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download PDF'),
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class PayslipDocumentView extends StatelessWidget {
  final Payslip payslip;
  final Company? company;
  final UserProfile? employee;

  const PayslipDocumentView({
    super.key,
    required this.payslip,
    this.company,
    this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final name = PayslipPdfService.letterheadName(company);
    final address = PayslipPdfService.letterheadAddress(company);
    final designation = payslip.designation.trim().isNotEmpty
        ? payslip.designation
        : (employee?.designation ?? '');
    final department = payslip.department.trim().isNotEmpty
        ? payslip.department
        : (employee?.department ?? '');
    final employeeId = payslip.employeeId.trim().isNotEmpty
        ? payslip.employeeId
        : (employee?.employeeId ?? '');

    final earnings = <(String, double)>[
      ('Basic', payslip.basic),
      if (payslip.hra > 0) ('HRA', payslip.hra),
      if (payslip.allowances > 0) ('Allowances', payslip.allowances),
    ];
    final deductions = <(String, double)>[
      if (payslip.employeePf > 0) ('EPF', payslip.employeePf),
      if (payslip.employeeEsi > 0) ('ESI', payslip.employeeEsi),
      if (payslip.tds > 0) ('TDS', payslip.tds),
      if (payslip.isLegacy &&
          payslip.deductions > 0 &&
          payslip.employeePf == 0 &&
          payslip.employeeEsi == 0 &&
          payslip.tds == 0)
        ('Deductions', payslip.deductions),
    ];

    final border = TableBorder.all(color: Colors.black87, width: 0.8);
    const cellPad = EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    Widget infoCell(String label, String value) {
      return Padding(
        padding: cellPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
            Text(
              value.isEmpty ? ' ' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    Widget headCell(String text, {bool right = false}) {
      return Padding(
        padding: cellPad,
        child: Align(
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      );
    }

    Widget moneyCell(String text, {bool right = false, bool bold = false}) {
      return Padding(
        padding: cellPad,
        child: Align(
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final pairCount = earnings.length > deductions.length
        ? earnings.length
        : deductions.length;
    final rows = <TableRow>[
      TableRow(
        children: [
          headCell('Earnings'),
          headCell('Amount', right: true),
          headCell('Deductions'),
          headCell('Amount', right: true),
        ],
      ),
    ];
    for (var i = 0; i < pairCount; i++) {
      final e = i < earnings.length ? earnings[i] : null;
      final d = i < deductions.length ? deductions[i] : null;
      rows.add(
        TableRow(
          children: [
            moneyCell(e?.$1 ?? ''),
            moneyCell(e == null ? '' : PayslipPdfService.inr(e.$2), right: true),
            moneyCell(d?.$1 ?? ''),
            moneyCell(d == null ? '' : PayslipPdfService.inr(d.$2), right: true),
          ],
        ),
      );
    }
    rows.add(
      TableRow(
        children: [
          moneyCell('Total Earnings (Rs)', bold: true),
          moneyCell(PayslipPdfService.inr(payslip.resolvedGross), right: true, bold: true),
          moneyCell('Total Deductions (Rs)', bold: true),
          moneyCell(PayslipPdfService.inr(payslip.deductions), right: true, bold: true),
        ],
      ),
    );

    final employerCtc = payslip.ctcMonthly > 0
        ? payslip.ctcMonthly
        : payslip.resolvedGross + payslip.employerPf + payslip.employerEsi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogo(size: 56, radius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 56),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Payslip for the Month of ${payslip.monthTitle}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Table(
          border: border,
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                Table(
                  children: [
                    TableRow(children: [infoCell('Name:', payslip.employeeName)]),
                    TableRow(children: [infoCell('Designation:', designation)]),
                    TableRow(children: [infoCell('Department:', department)]),
                    TableRow(children: [infoCell('Location:', 'Hyderabad')]),
                    TableRow(
                      children: [
                        infoCell(
                          'Effective Work Days:',
                          '${IndianPayrollEngine.calendarDaysInMonth(payslip.month)}',
                        ),
                      ],
                    ),
                    TableRow(children: [infoCell('LOP:', '0.0')]),
                  ],
                ),
                Table(
                  children: [
                    TableRow(children: [infoCell('Employee ID:', employeeId)]),
                    TableRow(children: [infoCell('Bank Name:', '')]),
                    TableRow(children: [infoCell('Bank Account No.:', '')]),
                    TableRow(children: [infoCell('PAN No.:', '')]),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Table(
          border: border,
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FlexColumnWidth(0.8),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(0.8),
          },
          children: rows,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text(
              'Net Pay For The Month:',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 16),
            Text(
              PayslipPdfService.inr(payslip.netPay),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '(${IndianPayrollEngine.rupeesInWords(payslip.netPay)})',
          style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
        ),
        if (payslip.employerPf > 0 || payslip.employerEsi > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Employer contributions (not deducted from net):  '
            'PF ₹${PayslipPdfService.inr(payslip.employerPf)}  ·  '
            'ESI ₹${PayslipPdfService.inr(payslip.employerEsi)}  ·  '
            'Monthly CTC ₹${PayslipPdfService.inr(employerCtc)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(color: Colors.black87),
        const SizedBox(height: 8),
        Text(
          'This is a system generated payslip and does not require signature.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 6),
        Text(
          '${payslip.fyLabel} · New tax regime',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppTheme.primary.withValues(alpha: 0.9)),
        ),
      ],
    );
  }
}
