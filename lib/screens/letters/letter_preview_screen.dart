import 'package:flutter/material.dart';

import '../../models/hr_letter.dart';
import '../../models/recruitment_candidate.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/letter_pdf_service.dart';
import '../../theme/app_theme.dart';

class LetterPreviewScreen extends StatefulWidget {
  final HrLetter letter;
  final UserProfile viewer;
  final bool alreadyIssued;

  const LetterPreviewScreen({
    super.key,
    required this.letter,
    required this.viewer,
    this.alreadyIssued = true,
  });

  @override
  State<LetterPreviewScreen> createState() => _LetterPreviewScreenState();
}

class _LetterPreviewScreenState extends State<LetterPreviewScreen> {
  final _firestore = FirestoreService();
  late HrLetter _letter;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter.body.trim().isEmpty
        ? widget.letter.withRenderedBody()
        : widget.letter;
  }

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      await LetterPdfService.download(_letter);
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

  Future<void> _issue() async {
    setState(() => _busy = true);
    try {
      final id = await _firestore.issueLetter(_letter);
      if (_letter.candidateId.isNotEmpty) {
        final candidates = await _firestore
            .streamCompanyCandidates(_letter.companyId)
            .first;
        final match = candidates.where((c) => c.id == _letter.candidateId);
        if (match.isNotEmpty) {
          final candidate = match.first;
          if (!candidate.isHired &&
              candidate.stage.toUpperCase() != 'REJECTED') {
            await _firestore.saveCandidate(
              RecruitmentCandidate(
                id: candidate.id,
                companyId: candidate.companyId,
                name: candidate.name,
                email: candidate.email,
                phone: candidate.phone,
                role: candidate.role,
                stage: 'OFFER',
                notes: candidate.notes,
              ),
            );
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_letter.displayType} issued for ${_letter.recipientName}.')),
      );
      Navigator.pop(context, _letter.copyWith(id: id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not issue letter: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canIssue = !widget.alreadyIssued && widget.viewer.isPeopleOps;

    return Scaffold(
      appBar: AppBar(
        title: Text(_letter.title),
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
              constraints: const BoxConstraints(maxWidth: 720),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _letter.companyName.isNotEmpty
                            ? _letter.companyName
                            : 'Dentassure 360',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (_letter.companyAddress.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _letter.companyAddress,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(height: 2, color: AppTheme.primary),
                      const SizedBox(height: 20),
                      Text(
                        _letter.title.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        _letter.body,
                        style: const TextStyle(height: 1.55, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _download,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download PDF'),
                ),
                if (canIssue)
                  FilledButton.icon(
                    onPressed: _busy ? null : _issue,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Issue letter'),
                  ),
              ],
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
