import 'package:flutter/material.dart';

import '../../models/payslip.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_motion.dart';

class PayslipsScreen extends StatelessWidget {
  final UserProfile viewer;

  const PayslipsScreen({super.key, required this.viewer});

  Future<void> _issue(BuildContext context, List<UserProfile> people) async {
    if (people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employees found to issue a payslip.')),
      );
      return;
    }

    final firestore = FirestoreService();
    var uid = people.first.uid;
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Issue payslip'),
          content: DropdownButtonFormField<String>(
            initialValue: uid,
            items: people
                .map(
                  (u) => DropdownMenuItem(
                    value: u.uid,
                    child: Text(
                      '${u.name} (₹${u.monthlySalary.toStringAsFixed(0)})',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setDialog(() => uid = v ?? uid),
            decoration: const InputDecoration(labelText: 'Employee'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Issue'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final emp = people.firstWhere((u) => u.uid == uid, orElse: () => viewer);
    if (emp.monthlySalary <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set monthly salary on the employee profile first (HR & People → Edit).',
            ),
          ),
        );
      }
      return;
    }
    final payslip = Payslip.fromSalary(
      id: '${emp.uid}_$month',
      companyId: emp.companyId,
      uid: emp.uid,
      employeeName: emp.name,
      month: month,
      monthlySalary: emp.monthlySalary,
    );
    await firestore.issuePayslip(payslip);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payslip issued for ${emp.name} ($month).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final personal = !viewer.isPeopleOps;
    final title = personal ? 'My Payslips' : 'Payslips';

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
                      onPressed: () => _issue(context, people),
                      icon: const Icon(Icons.add),
                      label: const Text('Issue payslip'),
                    )
                  : null,
              body: slips.isEmpty
                  ? _PayslipEmptyState(
                      personal: personal,
                      onIssue: viewer.isPeopleOps
                          ? () => _issue(context, people)
                          : null,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Simplified salary breakdown (not statutory PF/ESI/TDS payroll).',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        ...slips.map(
                          (p) => MotionCard(
                            child: Card(
                              child: ListTile(
                                title: Text('${p.employeeName} • ${p.month}'),
                                subtitle: Text(
                                  'Basic ₹${p.basic.toStringAsFixed(0)}  HRA ₹${p.hra.toStringAsFixed(0)}  Allowances ₹${p.allowances.toStringAsFixed(0)}  Deductions ₹${p.deductions.toStringAsFixed(0)}',
                                ),
                                trailing: Text(
                                  '₹${p.netPay.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
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
                    ? 'Your company admin has not issued a payslip yet. Ask HR to set your monthly salary, then issue a slip from Payslips.'
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
