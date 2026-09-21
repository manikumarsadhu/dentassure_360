import 'package:flutter/material.dart';

import '../../models/company.dart';
import '../../models/payslip.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/indian_payroll_engine.dart';
import '../../services/payslip_pdf_service.dart';
import '../../theme/app_motion.dart';
import 'payslip_preview_screen.dart';

class PayslipsScreen extends StatelessWidget {
  final UserProfile viewer;

  const PayslipsScreen({super.key, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final personal = !viewer.isPeopleOps;
    final title = personal ? 'My Payslips' : 'Payslips';

    return StreamBuilder<Company?>(
      stream: firestore.streamCompany(viewer.companyId),
      builder: (context, companySnap) {
        final company = companySnap.data;
        return StreamBuilder<List<UserProfile>>(
          stream: firestore.streamCompanyEmployees(viewer.companyId),
          builder: (context, usersSnap) {
            final people = usersSnap.data ?? [];
            return StreamBuilder<List<Payslip>>(
              stream: personal
                  ? firestore.streamEmployeePayslips(viewer.uid)
                  : firestore.streamCompanyPayslips(viewer.companyId),
              builder: (context, snapshot) {
                final slips = snapshot.data ?? [];
                return Scaffold(
                  appBar: AppBar(title: Text(title)),
                  floatingActionButton: viewer.isPeopleOps
                      ? FloatingActionButton.extended(
                          onPressed: () => _issue(
                            context,
                            viewer: viewer,
                            people: people,
                            company: company,
                            slips: slips,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Issue payslip'),
                        )
                      : null,
                  body: slips.isEmpty
                      ? _PayslipEmptyState(
                          personal: personal,
                          onIssue: viewer.isPeopleOps
                              ? () => _issue(
                                    context,
                                    viewer: viewer,
                                    people: people,
                                    company: company,
                                    slips: slips,
                                  )
                              : null,
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              'New tax regime · ${slips.first.fyLabel}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            if (viewer.isCompanyAdmin || viewer.isPlatformAdmin)
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Cap PF wages at ₹15,000'),
                                subtitle: const Text(
                                  'Statutory EPF ceiling. Turn off to contribute 12% on full basic.',
                                ),
                                value: company?.pfRestrictToStatutoryCeiling ?? true,
                                onChanged: company == null
                                    ? null
                                    : (v) {
                                        firestore.updateCompany(
                                          company.copyWith(
                                            pfRestrictToStatutoryCeiling: v,
                                          ),
                                        );
                                      },
                              )
                            else if (viewer.isPeopleOps)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  (company?.pfRestrictToStatutoryCeiling ?? true)
                                      ? 'PF wage ceiling ₹15,000 (company setting)'
                                      : 'PF is 12% of full basic (company setting)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            ...slips.map((p) {
                              final emp = _employeeOf(people, p.uid);
                              return MotionCard(
                                child: Card(
                                  child: ListTile(
                                    onTap: () => _openPreview(
                                      context,
                                      viewer: viewer,
                                      payslip: p,
                                      company: company,
                                      employee: emp,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${p.employeeName} • ${p.month}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '₹${PayslipPdfService.inr(p.netPay)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(_subtitle(p)),
                                    trailing: IconButton(
                                      tooltip: 'Download PDF',
                                      onPressed: () => _download(
                                        context,
                                        payslip: p,
                                        company: company,
                                        employee: emp,
                                      ),
                                      icon: const Icon(Icons.download_outlined),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  static UserProfile? _employeeOf(List<UserProfile> people, String uid) {
    for (final u in people) {
      if (u.uid == uid) return u;
    }
    return null;
  }

  static String _subtitle(Payslip p) {
    if (p.isLegacy) {
      return 'Basic ₹${p.basic.toStringAsFixed(0)}  HRA ₹${p.hra.toStringAsFixed(0)}  '
          'Allowances ₹${p.allowances.toStringAsFixed(0)}  Deductions ₹${p.deductions.toStringAsFixed(0)}';
    }
    return 'Gross ₹${PayslipPdfService.inr(p.resolvedGross)}  '
        'EPF ₹${PayslipPdfService.inr(p.employeePf)}  '
        'ESI ₹${PayslipPdfService.inr(p.employeeEsi)}  '
        'TDS ₹${PayslipPdfService.inr(p.tds)}';
  }

  static Future<void> _openPreview(
    BuildContext context, {
    required UserProfile viewer,
    required Payslip payslip,
    Company? company,
    UserProfile? employee,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PayslipPreviewScreen(
          payslip: payslip,
          viewer: viewer,
          company: company,
          employee: employee,
        ),
      ),
    );
  }

  static Future<void> _download(
    BuildContext context, {
    required Payslip payslip,
    Company? company,
    UserProfile? employee,
  }) async {
    try {
      await PayslipPdfService.download(
        payslip: payslip,
        company: company,
        employee: employee,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download PDF: $e')),
        );
      }
    }
  }

  static Future<void> _issue(
    BuildContext context, {
    required UserProfile viewer,
    required List<UserProfile> people,
    required List<Payslip> slips,
    Company? company,
  }) async {
    if (people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employees found to issue a payslip.')),
      );
      return;
    }

    final issued = await showDialog<Payslip>(
      context: context,
      builder: (ctx) => _IssuePayslipDialog(
        people: people,
        viewer: viewer,
        company: company,
        existing: slips,
      ),
    );
    if (issued == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payslip issued for ${issued.employeeName} (${issued.month}).',
        ),
      ),
    );
  }
}

class _IssuePayslipDialog extends StatefulWidget {
  final List<UserProfile> people;
  final UserProfile viewer;
  final Company? company;
  final List<Payslip> existing;

  const _IssuePayslipDialog({
    required this.people,
    required this.viewer,
    required this.company,
    required this.existing,
  });

  @override
  State<_IssuePayslipDialog> createState() => _IssuePayslipDialogState();
}

class _IssuePayslipDialogState extends State<_IssuePayslipDialog> {
  late String _uid;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _uid = widget.people.first.uid;
  }

  UserProfile get _emp =>
      widget.people.firstWhere((u) => u.uid == _uid, orElse: () => widget.viewer);

  String get _month {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  PayrollBreakdown? get _preview {
    if (_emp.monthlySalary <= 0) return null;
    final ytd = IndianPayrollEngine.ytdFromSlips(
      slips: widget.existing
          .map(
            (p) => YtdSlip(
              uid: p.uid,
              month: p.month,
              gross: p.resolvedGross,
              tds: p.tds,
            ),
          )
          .toList(),
      uid: _emp.uid,
      month: _month,
    );
    return IndianPayrollEngine.compute(
      monthlySalary: _emp.monthlySalary,
      month: _month,
      pfRestrictToStatutoryCeiling:
          widget.company?.pfRestrictToStatutoryCeiling ?? true,
      ytdGross: ytd.gross,
      ytdTds: ytd.tds,
    );
  }

  Future<void> _save() async {
    if (_emp.monthlySalary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set monthly salary on the employee profile first (HR & People → Edit).',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final ytd = IndianPayrollEngine.ytdFromSlips(
        slips: widget.existing
            .map(
              (p) => YtdSlip(
                uid: p.uid,
                month: p.month,
                gross: p.resolvedGross,
                tds: p.tds,
              ),
            )
            .toList(),
        uid: _emp.uid,
        month: _month,
      );
      final payslip = Payslip.fromSalary(
        id: '${_emp.uid}_$_month',
        companyId: _emp.companyId,
        uid: _emp.uid,
        employeeName: _emp.name,
        employeeId: _emp.employeeId,
        designation: _emp.designation,
        department: _emp.department,
        month: _month,
        monthlySalary: _emp.monthlySalary,
        pfRestrictToStatutoryCeiling:
            widget.company?.pfRestrictToStatutoryCeiling ?? true,
        ytdGross: ytd.gross,
        ytdTds: ytd.tds,
      );
      await FirestoreService().issuePayslip(payslip);
      if (mounted) Navigator.pop(context, payslip);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not issue payslip: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = _preview;
    return AlertDialog(
      title: const Text('Issue payslip'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(_uid),
                initialValue: _uid,
                items: widget.people
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.uid,
                        child: Text(
                          '${u.name} (₹${u.monthlySalary.toStringAsFixed(0)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _uid = v ?? _uid),
                decoration: const InputDecoration(labelText: 'Employee'),
              ),
              const SizedBox(height: 8),
              Text(
                'Month $_month · ${IndianPayrollEngine.fyLabel(_month)} · New tax regime',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              if (calc != null) ...[
                const SizedBox(height: 12),
                _CalcLine('Gross', calc.gross),
                _CalcLine('Employee PF', calc.employeePf),
                _CalcLine('Employee ESI', calc.employeeEsi),
                _CalcLine('TDS', calc.tds),
                _CalcLine('Net pay', calc.netPay, bold: true),
                const Divider(),
                _CalcLine('Employer PF', calc.employerPf),
                _CalcLine('Employer ESI', calc.employerEsi),
                _CalcLine('Monthly CTC', calc.ctcMonthly),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Set monthly salary on the employee profile first.',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || calc == null ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Issue'),
        ),
      ],
    );
  }
}

class _CalcLine extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _CalcLine(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('₹${PayslipPdfService.inr(amount)}', style: style),
        ],
      ),
    );
  }
}

class _PayslipEmptyState extends StatelessWidget {
  final bool personal;
  final VoidCallback? onIssue;

  const _PayslipEmptyState({required this.personal, this.onIssue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No payslips yet',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                personal
                    ? 'HR has not issued a payslip yet. After they issue your month, you can preview and download it here.'
                    : 'Issue a payslip after setting monthly salary on the employee profile (HR & People → Edit employee).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (onIssue != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onIssue,
                  icon: const Icon(Icons.add),
                  label: const Text('Issue payslip'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
