import 'package:flutter/material.dart';

import '../../models/performance_goal.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../utils/team_scope.dart';

class PerformanceScreen extends StatefulWidget {
  final UserProfile viewer;

  const PerformanceScreen({super.key, required this.viewer});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _firestore = FirestoreService();

  Future<void> _addGoal(List<UserProfile> people) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final cycle = TextEditingController(text: '2026-Q3');
    var uid = widget.viewer.isPeopleOps || widget.viewer.isManager
        ? (people.isNotEmpty ? people.first.uid : widget.viewer.uid)
        : widget.viewer.uid;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('New goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.viewer.isTeamApprover)
                  DropdownButtonFormField<String>(
                    initialValue: uid,
                    items: [
                      DropdownMenuItem(
                        value: widget.viewer.uid,
                        child: Text('${widget.viewer.name} (me)'),
                      ),
                      ...people.map(
                        (u) => DropdownMenuItem(value: u.uid, child: Text(u.name)),
                      ),
                    ],
                    onChanged: (v) => setDialog(() => uid = v ?? uid),
                    decoration: const InputDecoration(labelText: 'Employee'),
                  ),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Goal title'),
                ),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: cycle,
                  decoration: const InputDecoration(labelText: 'Cycle'),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || title.text.trim().isEmpty) return;
    final subject = people.where((u) => u.uid == uid).firstOrNull ?? widget.viewer;
    await _firestore.savePerformanceGoal(
      PerformanceGoal(
        id: '',
        companyId: widget.viewer.companyId,
        uid: subject.uid,
        employeeName: subject.name,
        reportingManagerUid: subject.reportingManagerUid,
        title: title.text.trim(),
        description: description.text.trim(),
        cycle: cycle.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: _firestore.streamCompanyEmployees(widget.viewer.companyId),
      builder: (context, usersSnap) {
        final all = usersSnap.data ?? [];
        final team = TeamScope.reportsFor(widget.viewer, all);
        return StreamBuilder<List<PerformanceGoal>>(
          stream: widget.viewer.isPeopleOps || widget.viewer.isManager
              ? _firestore.streamCompanyGoals(widget.viewer.companyId)
              : _firestore.streamEmployeeGoals(widget.viewer.uid),
          builder: (context, snapshot) {
            var goals = snapshot.data ?? [];
            if (widget.viewer.isManager && !widget.viewer.isPeopleOps) {
              final allowed = team.map((u) => u.uid).toSet()..add(widget.viewer.uid);
              goals = goals.where((g) => allowed.contains(g.uid)).toList();
            }
            return Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _addGoal(team),
                icon: const Icon(Icons.add),
                label: const Text('Add goal'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Performance',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (goals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No goals yet for this cycle.'),
                    )
                  else
                    ...goals.map((goal) => Card(
                          child: ListTile(
                            title: Text('${goal.employeeName} • ${goal.title}'),
                            subtitle: Text(
                              '${goal.cycle} • ${goal.status}${goal.rating > 0 ? " • Rating ${goal.rating}/5" : ""}',
                            ),
                            trailing: widget.viewer.isTeamApprover && goal.isOpen
                                ? IconButton(
                                    icon: const Icon(Icons.rate_review_outlined),
                                    onPressed: () async {
                                      await _firestore.savePerformanceGoal(
                                        PerformanceGoal(
                                          id: goal.id,
                                          companyId: goal.companyId,
                                          uid: goal.uid,
                                          employeeName: goal.employeeName,
                                          reportingManagerUid:
                                              goal.reportingManagerUid,
                                          title: goal.title,
                                          description: goal.description,
                                          cycle: goal.cycle,
                                          status: 'DONE',
                                          rating: 4,
                                          reviewComment: 'Reviewed',
                                          reviewerUid: widget.viewer.uid,
                                          reviewerName: widget.viewer.name,
                                        ),
                                      );
                                    },
                                  )
                                : Chip(label: Text(goal.status)),
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
