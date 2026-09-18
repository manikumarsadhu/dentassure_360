import 'package:flutter/material.dart';

import '../../models/hr_letter.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_motion.dart';
import 'generate_letter_flow.dart';
import 'letter_preview_screen.dart';

class LettersScreen extends StatelessWidget {
  final UserProfile viewer;
  final bool personalOnly;
  final bool embedded;

  const LettersScreen({
    super.key,
    required this.viewer,
    this.personalOnly = false,
    this.embedded = true,
  });

  Future<void> _pickGenerate(BuildContext context) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Offer letter'),
                  subtitle: const Text('New joiner or candidate'),
                  onTap: () => Navigator.pop(ctx, HrLetter.typeOffer),
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up_outlined),
                  title: const Text('Increment letter'),
                  subtitle: const Text('Revised salary for an employee'),
                  onTap: () => Navigator.pop(ctx, HrLetter.typeIncrement),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted || type == null) return;
    if (type == HrLetter.typeOffer) {
      await GenerateLetterFlow.startOffer(context: context, viewer: viewer);
    } else {
      await GenerateLetterFlow.startIncrement(context: context, viewer: viewer);
    }
  }

  void _openLetter(BuildContext context, HrLetter letter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterPreviewScreen(
          letter: letter,
          viewer: viewer,
          alreadyIssued: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final canGenerate = !personalOnly && viewer.isPeopleOps;
    final title = personalOnly ? 'My Letters' : 'Letters & Documents';

    return StreamBuilder<List<HrLetter>>(
      stream: personalOnly
          ? firestore.streamEmployeeLetters(viewer.uid)
          : firestore.streamCompanyLetters(viewer.companyId),
      builder: (context, snapshot) {
        final letters = snapshot.data ?? [];
        final body = ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!embedded)
              const SizedBox.shrink()
            else ...[
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                personalOnly
                    ? 'Offer and increment letters issued to you. Open one to preview or download PDF.'
                    : 'Generate an offer or increment letter from a person, preview it, issue it, and download PDF.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
            ],
            if (!personalOnly) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  Chip(label: Text('Offer letter · Live')),
                  Chip(label: Text('Increment letter · Live')),
                  Chip(label: Text('Appointment letter · Soon')),
                  Chip(label: Text('Warning letter · Soon')),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Could not load letters: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else if (!snapshot.hasData)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (letters.isEmpty)
              _LettersEmptyState(
                personal: personalOnly,
                onGenerate: canGenerate ? () => _pickGenerate(context) : null,
              )
            else
              ...letters.map(
                (letter) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MotionCard(
                    child: Card(
                      child: ListTile(
                        leading: Icon(
                          letter.isOffer
                              ? Icons.mail_outline
                              : Icons.trending_up_outlined,
                        ),
                        title: Text(letter.recipientName),
                        subtitle: Text(
                          [
                            letter.displayType,
                            if (letter.designation.isNotEmpty) letter.designation,
                            if (letter.isOffer)
                              'Joining ${HrLetter.formatDisplayDate(letter.joiningDate)}'
                            else
                              'Effective ${HrLetter.formatDisplayDate(letter.effectiveDate)}',
                            HrLetter.formatInr(letter.monthlySalary),
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openLetter(context, letter),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: embedded
              ? null
              : AppBar(title: Text(title)),
          floatingActionButton: canGenerate
              ? FloatingActionButton.extended(
                  onPressed: () => _pickGenerate(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Generate letter'),
                )
              : null,
          body: body,
        );
      },
    );
  }
}

class _LettersEmptyState extends StatelessWidget {
  final bool personal;
  final VoidCallback? onGenerate;

  const _LettersEmptyState({required this.personal, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            personal ? 'No letters yet' : 'No letters issued yet',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            personal
                ? 'When HR issues an offer or increment letter to you, it will appear here.'
                : 'Generate an offer letter for a new joiner, or an increment letter for existing staff.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          if (onGenerate != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.add),
              label: const Text('Generate letter'),
            ),
          ],
        ],
      ),
    );
  }
}
