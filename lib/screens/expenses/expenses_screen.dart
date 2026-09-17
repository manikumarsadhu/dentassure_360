import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/expense_claim.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/team_scope.dart';
import '../../theme/app_motion.dart';

class ExpensesScreen extends StatefulWidget {
  final UserProfile viewer;
  final bool personalOnly;

  const ExpensesScreen({
    super.key,
    required this.viewer,
    this.personalOnly = false,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _firestore = FirestoreService();
  final _storage = StorageService();

  Future<void> _submitClaim() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    var category = 'Travel';
    String receipt = '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('New expense claim'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: const [
                    DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                    DropdownMenuItem(value: 'Meals', child: Text('Meals')),
                    DropdownMenuItem(
                      value: 'Software',
                      child: Text('Software'),
                    ),
                    DropdownMenuItem(value: 'General', child: Text('General')),
                  ],
                  onChanged: (v) => setDialog(() => category = v ?? category),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await _storage.pickImage();
                    if (file == null) return;
                    final bytes = await file.readAsBytes();
                    receipt = await _storage.encodeImageAsDataUrl(bytes: bytes);
                    setDialog(() {});
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    receipt.isEmpty ? 'Attach receipt' : 'Receipt attached',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final parsed = double.tryParse(amount.text.trim()) ?? 0;
    if (title.text.trim().isEmpty || parsed <= 0) return;

    await _firestore.submitExpense(
      ExpenseClaim(
        id: '',
        companyId: widget.viewer.companyId,
        uid: widget.viewer.uid,
        employeeName: widget.viewer.name,
        reportingManagerUid: widget.viewer.reportingManagerUid,
        title: title.text.trim(),
        category: category,
        amount: parsed,
        receiptDataUrl: receipt,
        date: Attendance.formatDateKey(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: _firestore.streamCompanyEmployees(widget.viewer.companyId),
      builder: (context, usersSnap) {
        final allowed = TeamScope.reportUids(
          widget.viewer,
          usersSnap.data ?? [],
        );
        return StreamBuilder<List<ExpenseClaim>>(
          stream: widget.personalOnly
              ? _firestore.streamEmployeeExpenses(widget.viewer.uid)
              : _firestore.streamCompanyExpenses(widget.viewer.companyId),
          builder: (context, snapshot) {
            var claims = snapshot.data ?? [];
            if (!widget.personalOnly && !widget.viewer.isPeopleOps) {
              claims = claims
                  .where(
                    (e) =>
                        e.uid == widget.viewer.uid || allowed.contains(e.uid),
                  )
                  .toList();
            }
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.personalOnly ? 'My Expenses' : 'Expenses'),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _submitClaim,
                icon: const Icon(Icons.add),
                label: const Text('New claim'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (claims.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No expense claims yet.'),
                    )
                  else
                    ...claims.map(
                      (claim) => MotionCard(
                        child: Card(
                          child: ListTile(
                            title: Text(
                              '${claim.title} • ₹${claim.amount.toStringAsFixed(0)}',
                            ),
                            subtitle: Text(
                              '${claim.employeeName} • ${claim.category} • ${claim.date} • ${claim.status}',
                            ),
                            trailing:
                                claim.isPending &&
                                    widget.viewer.isTeamApprover &&
                                    claim.uid != widget.viewer.uid
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () =>
                                            _firestore.reviewExpense(
                                              id: claim.id,
                                              status: 'REJECTED',
                                              reviewedBy: widget.viewer.uid,
                                              reviewedByName:
                                                  widget.viewer.name,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed: () =>
                                            _firestore.reviewExpense(
                                              id: claim.id,
                                              status: 'APPROVED',
                                              reviewedBy: widget.viewer.uid,
                                              reviewedByName:
                                                  widget.viewer.name,
                                            ),
                                      ),
                                    ],
                                  )
                                : Chip(label: Text(claim.status)),
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
