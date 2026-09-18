import 'package:flutter/material.dart';

import '../../models/recruitment_candidate.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../employee/add_employee_screen.dart';
import '../../theme/app_motion.dart';
import '../letters/generate_letter_flow.dart';

class RecruitmentScreen extends StatefulWidget {
  final UserProfile viewer;

  const RecruitmentScreen({super.key, required this.viewer});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  final _firestore = FirestoreService();
  static const stages = ['APPLIED', 'INTERVIEW', 'OFFER', 'HIRED', 'REJECTED'];

  Future<void> _addCandidate() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final role = TextEditingController(text: 'Software Engineer');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add candidate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: role,
              decoration: const InputDecoration(labelText: 'Role'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (saved != true || name.text.trim().isEmpty) return;
    await _firestore.saveCandidate(
      RecruitmentCandidate(
        id: '',
        companyId: widget.viewer.companyId,
        name: name.text.trim(),
        email: email.text.trim(),
        role: role.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RecruitmentCandidate>>(
      stream: _firestore.streamCompanyCandidates(widget.viewer.companyId),
      builder: (context, snapshot) {
        final candidates = snapshot.data ?? [];
        return Scaffold(
          floatingActionButton: widget.viewer.isPeopleOps
              ? FloatingActionButton.extended(
                  onPressed: _addCandidate,
                  icon: const Icon(Icons.add),
                  label: const Text('Add candidate'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Recruitment & ATS',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (candidates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No candidates in the pipeline.'),
                )
              else
                ...candidates.map(
                  (c) => MotionCard(
                    child: Card(
                      child: ListTile(
                        title: Text(c.name),
                        subtitle: Text('${c.email} • ${c.role}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.viewer.isPeopleOps)
                              IconButton(
                                tooltip: 'Generate offer',
                                onPressed: () => GenerateLetterFlow.startOffer(
                                  context: context,
                                  viewer: widget.viewer,
                                  candidate: c,
                                ),
                                icon: const Icon(Icons.mail_outline),
                              ),
                            DropdownButton<String>(
                              value: c.stage,
                              items: stages
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: widget.viewer.isPeopleOps
                                  ? (stage) async {
                                      if (stage == null) return;
                                      await _firestore.saveCandidate(
                                        RecruitmentCandidate(
                                          id: c.id,
                                          companyId: c.companyId,
                                          name: c.name,
                                          email: c.email,
                                          phone: c.phone,
                                          role: c.role,
                                          stage: stage,
                                          notes: c.notes,
                                        ),
                                      );
                                      if (stage == 'HIRED' &&
                                          context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddEmployeeScreen(
                                              adminProfile: widget.viewer,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ],
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
  }
}
