import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../models/timesheet_entry.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../utils/team_scope.dart';

class TimesheetScreen extends StatefulWidget {
  final UserProfile viewer;
  final bool personalOnly;

  const TimesheetScreen({
    super.key,
    required this.viewer,
    this.personalOnly = false,
  });

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final _firestore = FirestoreService();

  Future<void> _logHours() async {
    final project = TextEditingController();
    final task = TextEditingController();
    final hours = TextEditingController(text: '8');
    var billable = true;
    final date = Attendance.formatDateKey(DateTime.now());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Log timesheet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: project,
                decoration: const InputDecoration(labelText: 'Project'),
              ),
              TextFormField(
                controller: task,
                decoration: const InputDecoration(labelText: 'Task'),
              ),
              TextFormField(
                controller: hours,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hours'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Billable'),
                value: billable,
                onChanged: (v) => setDialog(() => billable = v),
              ),
            ],
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
    final parsed = double.tryParse(hours.text.trim()) ?? 0;
    if (project.text.trim().isEmpty || parsed <= 0) return;

    await _firestore.submitTimesheet(
      TimesheetEntry(
        id: '',
        companyId: widget.viewer.companyId,
        uid: widget.viewer.uid,
        employeeName: widget.viewer.name,
        reportingManagerUid: widget.viewer.reportingManagerUid,
        date: date,
        project: project.text.trim(),
        task: task.text.trim(),
        hours: parsed,
        billable: billable,
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
        return StreamBuilder<List<TimesheetEntry>>(
          stream: widget.personalOnly
              ? _firestore.streamEmployeeTimesheets(widget.viewer.uid)
              : _firestore.streamCompanyTimesheets(widget.viewer.companyId),
          builder: (context, snapshot) {
            var entries = snapshot.data ?? [];
            if (!widget.personalOnly && !widget.viewer.isPeopleOps) {
              entries = entries
                  .where((e) =>
                      e.uid == widget.viewer.uid || allowed.contains(e.uid))
                  .toList();
            }
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.personalOnly ? 'My Timesheet' : 'Timesheets',
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _logHours,
                icon: const Icon(Icons.add),
                label: const Text('Log hours'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No timesheet entries yet.'),
                    )
                  else
                    ...entries.map((entry) => Card(
                          child: ListTile(
                            title: Text(
                              '${entry.employeeName} • ${entry.project}',
                            ),
                            subtitle: Text(
                              '${entry.date} • ${entry.hours}h • ${entry.billable ? "Billable" : "Non-billable"} • ${entry.status}',
                            ),
                            trailing: entry.isPending &&
                                    !widget.personalOnly &&
                                    widget.viewer.isTeamApprover &&
                                    entry.uid != widget.viewer.uid
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () =>
                                            _firestore.reviewTimesheet(
                                          id: entry.id,
                                          status: 'REJECTED',
                                          reviewedBy: widget.viewer.uid,
                                          reviewedByName: widget.viewer.name,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed: () =>
                                            _firestore.reviewTimesheet(
                                          id: entry.id,
                                          status: 'APPROVED',
                                          reviewedBy: widget.viewer.uid,
                                          reviewedByName: widget.viewer.name,
                                        ),
                                      ),
                                    ],
                                  )
                                : Chip(label: Text(entry.status)),
                          ),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
