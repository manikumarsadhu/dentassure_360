import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/company.dart';
import '../models/payslip.dart';
import '../models/user_profile.dart';
import 'indian_payroll_engine.dart';

class PayslipPdfService {
  static const defaultCompanyName = 'DentAssure Health Plans Pvt Ltd';
  static const defaultAddress =
      'PLOT 11, INSIGNIA, Margadarshi Colony, Hyderabad, Telangana 500102';

  static String letterheadName(Company? company) {
    final name = company?.name.trim() ?? '';
    return name.isNotEmpty ? name : defaultCompanyName;
  }

  static String letterheadAddress(Company? company) {
    final address = company?.address.trim() ?? '';
    return address.isNotEmpty ? address : defaultAddress;
  }

  static String inr(num value) => _indianGroup(value.round());

  static String _indianGroup(int n) {
    final sign = n < 0 ? '-' : '';
    final s = n.abs().toString();
    if (s.length <= 3) return '$sign$s';
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '$sign${parts.join(',')},$last3';
  }

  static Future<Uint8List> buildPdf({
    required Payslip payslip,
    Company? company,
    UserProfile? employee,
  }) async {
    final doc = pw.Document();
    pw.ImageProvider? logo;
    try {
      final data = await rootBundle.load('assets/branding/app_icon.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final name = letterheadName(company);
    final address = letterheadAddress(company);
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
    final totalEarn = payslip.resolvedGross;
    final totalDed = payslip.deductions;

    final border = pw.TableBorder.all(color: PdfColors.black, width: 0.8);
    const cellPad = pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5);
    final labelStyle = pw.TextStyle(fontSize: 9);
    final valueStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final headStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

    pw.Widget infoCell(String label, String value) {
      return pw.Padding(
        padding: cellPad,
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$label\n', style: labelStyle),
              pw.TextSpan(
                text: value.isEmpty ? ' ' : value,
                style: valueStyle,
              ),
            ],
          ),
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logo != null)
                    pw.Container(
                      width: 64,
                      height: 64,
                      margin: const pw.EdgeInsets.only(right: 16),
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          name,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          address,
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  if (logo != null) pw.SizedBox(width: 80),
                ],
              ),
              pw.SizedBox(height: 22),
              pw.Text(
                'Payslip for the Month of ${payslip.monthTitle}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: border,
                columnWidths: const {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Table(
                        children: [
                          pw.TableRow(
                            children: [
                              infoCell('Name:', payslip.employeeName),
                            ],
                          ),
                          pw.TableRow(
                            children: [infoCell('Designation:', designation)],
                          ),
                          pw.TableRow(
                            children: [infoCell('Department:', department)],
                          ),
                          pw.TableRow(
                            children: [infoCell('Location:', 'Hyderabad')],
                          ),
                          pw.TableRow(
                            children: [
                              infoCell(
                                'Effective Work Days:',
                                '${IndianPayrollEngine.calendarDaysInMonth(payslip.month)}',
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [infoCell('LOP:', '0.0')],
                          ),
                        ],
                      ),
                      pw.Table(
                        children: [
                          pw.TableRow(
                            children: [infoCell('Employee ID:', employeeId)],
                          ),
                          pw.TableRow(
                            children: [infoCell('Bank Name:', '')],
                          ),
                          pw.TableRow(
                            children: [infoCell('Bank Account No.:', '')],
                          ),
                          pw.TableRow(
                            children: [infoCell('PAN No.:', '')],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Table(
                border: border,
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.4),
                  1: pw.FlexColumnWidth(0.8),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(0.8),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Text('Earnings', style: headStyle),
                      ),
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Amount', style: headStyle),
                        ),
                      ),
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Text('Deductions', style: headStyle),
                      ),
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Amount', style: headStyle),
                        ),
                      ),
                    ],
                  ),
                  ..._pairedRows(earnings, deductions),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Text(
                          'Total Earnings (Rs)',
                          style: headStyle,
                        ),
                      ),
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(inr(totalEarn), style: headStyle),
                        ),
                      ),
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Text(
                          'Total Deductions (Rs)',
                          style: headStyle,
                        ),
                      ),
                      pw.Padding(
                        padding: cellPad,
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(inr(totalDed), style: headStyle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Text(
                    'Net Pay For The Month:',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Text(
                    inr(payslip.netPay),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '(${IndianPayrollEngine.rupeesInWords(payslip.netPay)})',
                style: const pw.TextStyle(fontSize: 9),
              ),
              if (payslip.employerPf > 0 || payslip.employerEsi > 0) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Employer contributions (not deducted from net):  '
                  'PF Rs ${inr(payslip.employerPf)}  ·  '
                  'ESI Rs ${inr(payslip.employerEsi)}  ·  '
                  'Monthly CTC Rs ${inr(payslip.ctcMonthly > 0 ? payslip.ctcMonthly : payslip.resolvedGross + payslip.employerPf + payslip.employerEsi)}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
              pw.SizedBox(height: 18),
              pw.Divider(color: PdfColors.black, thickness: 0.8),
              pw.SizedBox(height: 10),
              pw.Text(
                'This is a system generated payslip and does not require signature.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static List<pw.TableRow> _pairedRows(
    List<(String, double)> earnings,
    List<(String, double)> deductions,
  ) {
    final count =
        earnings.length > deductions.length ? earnings.length : deductions.length;
    if (count == 0) {
      return [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text('—', style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('0', style: const pw.TextStyle(fontSize: 9)),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text('—', style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('0', style: const pw.TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      ];
    }
    final rows = <pw.TableRow>[];
    for (var i = 0; i < count; i++) {
      final e = i < earnings.length ? earnings[i] : null;
      final d = i < deductions.length ? deductions[i] : null;
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text(
                e?.$1 ?? '',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  e == null ? '' : inr(e.$2),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text(
                d?.$1 ?? '',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  d == null ? '' : inr(d.$2),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return rows;
  }

  static Future<void> download({
    required Payslip payslip,
    Company? company,
    UserProfile? employee,
  }) async {
    final bytes = await buildPdf(
      payslip: payslip,
      company: company,
      employee: employee,
    );
    await Printing.sharePdf(bytes: bytes, filename: payslip.pdfFilename);
  }
}
