import 'package:flutter/material.dart';

import '../../models/hr_letter.dart';
import '../../models/recruitment_candidate.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import 'letter_preview_screen.dart';

class GenerateLetterFlow {
  static Future<void> startOffer({
    required BuildContext context,
    required UserProfile viewer,
    RecruitmentCandidate? candidate,
  }) async {
    final letter = await showDialog<HrLetter>(
      context: context,
      builder: (_) => _OfferFormDialog(
        viewer: viewer,
        initialCandidate: candidate,
      ),
    );
    if (letter == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterPreviewScreen(
          letter: letter,
          viewer: viewer,
          alreadyIssued: false,
        ),
      ),
    );
  }

  static Future<void> startIncrement({
    required BuildContext context,
    required UserProfile viewer,
  }) async {
    final letter = await showDialog<HrLetter>(
      context: context,
      builder: (_) => _IncrementFormDialog(viewer: viewer),
    );
    if (letter == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterPreviewScreen(
          letter: letter,
          viewer: viewer,
          alreadyIssued: false,
        ),
      ),
    );
  }
}

List<UserProfile> _staffOf(List<UserProfile> people) {
  return people.where((u) => !u.isPlatformAdmin).toList();
}

class _OfferFormDialog extends StatefulWidget {
  final UserProfile viewer;
  final RecruitmentCandidate? initialCandidate;

  const _OfferFormDialog({
    required this.viewer,
    this.initialCandidate,
  });

  @override
  State<_OfferFormDialog> createState() => _OfferFormDialogState();
}

class _OfferFormDialogState extends State<_OfferFormDialog> {
  final _firestore = FirestoreService();
  final _salaryController = TextEditingController();
  final _roleController = TextEditingController();
  late DateTime _joiningDate;
  String _source = 'EMPLOYEE';
  String? _employeeUid;
  String? _candidateId;
  bool _loading = true;
  String? _error;
  List<UserProfile> _people = [];
  List<RecruitmentCandidate> _candidates = [];
  String _companyName = '';
  String _companyAddress = '';

  @override
  void initState() {
    super.initState();
    _joiningDate = DateTime.now().add(const Duration(days: 14));
    if (widget.initialCandidate != null) {
      _source = 'CANDIDATE';
      _candidateId = widget.initialCandidate!.id;
      _roleController.text = widget.initialCandidate!.role;
    }
    _load();
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final company = await _firestore.getCompany(widget.viewer.companyId);
      final people = await _firestore
          .streamCompanyEmployees(widget.viewer.companyId)
          .first;
      final candidates = await _firestore
          .streamCompanyCandidates(widget.viewer.companyId)
          .first;
      if (!mounted) return;
      final staff = _staffOf(people);
      setState(() {
        _people = staff;
        _candidates = candidates;
        _companyName = company?.name.isNotEmpty == true
            ? company!.name
            : widget.viewer.companyName;
        _companyAddress = company?.address ?? '';
        _employeeUid ??= staff.isNotEmpty ? staff.first.uid : null;
        _candidateId ??= candidates.isNotEmpty ? candidates.first.id : null;
        if (widget.initialCandidate == null && staff.isNotEmpty) {
          _applyEmployee(staff.first);
        } else if (_source == 'CANDIDATE') {
          final match = candidates.where((c) => c.id == _candidateId);
          if (match.isNotEmpty) {
            _applyCandidate(match.first);
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyEmployee(UserProfile emp) {
    _employeeUid = emp.uid;
    _roleController.text = emp.designation;
    if (emp.monthlySalary > 0) {
      _salaryController.text = emp.monthlySalary.toStringAsFixed(0);
    }
    if (emp.joiningDate != null) {
      _joiningDate = emp.joiningDate!;
    }
  }

  void _applyCandidate(RecruitmentCandidate candidate) {
    _candidateId = candidate.id;
    _roleController.text = candidate.role;
  }

  void _submit() {
    final salary = double.tryParse(_salaryController.text.trim()) ?? 0;
    if (salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a monthly salary greater than 0.')),
      );
      return;
    }
    final role = _roleController.text.trim();
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the offered role / designation.')),
      );
      return;
    }

    String uid = '';
    String candidateId = '';
    String name = '';
    String email = '';
    String department = '';

    if (_source == 'EMPLOYEE') {
      if (_people.isEmpty || _employeeUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add an employee first.')),
        );
        return;
      }
      final emp = _people.firstWhere((u) => u.uid == _employeeUid);
      uid = emp.uid;
      name = emp.name;
      email = emp.email;
      department = emp.department;
    } else {
      if (_candidates.isEmpty || _candidateId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a candidate first.')),
        );
        return;
      }
      final candidate = _candidates.firstWhere((c) => c.id == _candidateId);
      candidateId = candidate.id;
      name = candidate.name;
      email = candidate.email;
    }

    final now = DateTime.now();
    final letter = HrLetter(
      id: '',
      type: HrLetter.typeOffer,
      companyId: widget.viewer.companyId,
      companyName: _companyName,
      companyAddress: _companyAddress,
      uid: uid,
      candidateId: candidateId,
      recipientName: name,
      recipientEmail: email,
      designation: role,
      department: department,
      monthlySalary: salary,
      joiningDate: _joiningDate,
      issuedByUid: widget.viewer.uid,
      issuedByName: widget.viewer.name,
      createdAt: now,
    ).withRenderedBody();

    Navigator.pop(context, letter);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate offer letter'),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? Text(_error!)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.initialCandidate == null)
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'EMPLOYEE',
                            label: Text('Employee'),
                          ),
                          ButtonSegment(
                            value: 'CANDIDATE',
                            label: Text('Candidate'),
                          ),
                        ],
                        selected: {_source},
                        onSelectionChanged: (value) {
                          setState(() {
                            _source = value.first;
                            if (_source == 'EMPLOYEE' &&
                                _employeeUid != null) {
                              final match = _people.where(
                                (u) => u.uid == _employeeUid,
                              );
                              if (match.isNotEmpty) _applyEmployee(match.first);
                            } else if (_candidateId != null) {
                              final match = _candidates.where(
                                (c) => c.id == _candidateId,
                              );
                              if (match.isNotEmpty) {
                                _applyCandidate(match.first);
                              }
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    if (_source == 'EMPLOYEE' && _people.isEmpty)
                      const Text('No employees yet. Add someone in HR & People first.')
                    else if (_source == 'CANDIDATE' && _candidates.isEmpty)
                      const Text('No candidates yet. Add someone in Recruitment first.')
                    else if (_source == 'EMPLOYEE')
                      DropdownButtonFormField<String>(
                        key: ValueKey('offer-emp-$_employeeUid'),
                        initialValue: _people.any((u) => u.uid == _employeeUid)
                            ? _employeeUid
                            : null,
                        items: _people
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.uid,
                                child: Text(u.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          final emp = _people.where((u) => u.uid == v);
                          if (emp.isEmpty) return;
                          setState(() => _applyEmployee(emp.first));
                        },
                        decoration: const InputDecoration(
                          labelText: 'Employee',
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey('offer-cand-$_candidateId'),
                        initialValue: _candidates.any((c) => c.id == _candidateId)
                            ? _candidateId
                            : null,
                        items: _candidates
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name} · ${c.role}'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          final match = _candidates.where((c) => c.id == v);
                          if (match.isEmpty) return;
                          setState(() => _applyCandidate(match.first));
                        },
                        decoration: const InputDecoration(
                          labelText: 'Candidate',
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role / designation',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _salaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly salary (₹)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Joining date'),
                      subtitle: Text(HrLetter.formatDisplayDate(_joiningDate)),
                      trailing: const Icon(Icons.event_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _joiningDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _joiningDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: const Text('Preview'),
        ),
      ],
    );
  }
}

class _IncrementFormDialog extends StatefulWidget {
  final UserProfile viewer;

  const _IncrementFormDialog({required this.viewer});

  @override
  State<_IncrementFormDialog> createState() => _IncrementFormDialogState();
}

class _IncrementFormDialogState extends State<_IncrementFormDialog> {
  final _firestore = FirestoreService();
  final _newSalaryController = TextEditingController();
  final _previousSalaryController = TextEditingController();
  late DateTime _effectiveDate;
  String? _employeeUid;
  bool _loading = true;
  String? _error;
  List<UserProfile> _people = [];
  String _companyName = '';
  String _companyAddress = '';

  @override
  void initState() {
    super.initState();
    _effectiveDate = DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _newSalaryController.dispose();
    _previousSalaryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final company = await _firestore.getCompany(widget.viewer.companyId);
      final people = await _firestore
          .streamCompanyEmployees(widget.viewer.companyId)
          .first;
      if (!mounted) return;
      final staff = _staffOf(people);
      setState(() {
        _people = staff;
        _companyName = company?.name.isNotEmpty == true
            ? company!.name
            : widget.viewer.companyName;
        _companyAddress = company?.address ?? '';
        if (staff.isNotEmpty) {
          _applyEmployee(staff.first);
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyEmployee(UserProfile emp) {
    _employeeUid = emp.uid;
    _previousSalaryController.text = emp.monthlySalary > 0
        ? emp.monthlySalary.toStringAsFixed(0)
        : '';
    if (_newSalaryController.text.isEmpty && emp.monthlySalary > 0) {
      _newSalaryController.text = emp.monthlySalary.toStringAsFixed(0);
    }
  }

  void _submit() {
    if (_people.isEmpty || _employeeUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an employee first.')),
      );
      return;
    }
    final previous = double.tryParse(_previousSalaryController.text.trim()) ?? 0;
    final next = double.tryParse(_newSalaryController.text.trim()) ?? 0;
    if (next <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the new monthly salary.')),
      );
      return;
    }
    final emp = _people.firstWhere((u) => u.uid == _employeeUid);
    final now = DateTime.now();
    final letter = HrLetter(
      id: '',
      type: HrLetter.typeIncrement,
      companyId: widget.viewer.companyId,
      companyName: _companyName,
      companyAddress: _companyAddress,
      uid: emp.uid,
      recipientName: emp.name,
      recipientEmail: emp.email,
      designation: emp.designation,
      department: emp.department,
      monthlySalary: next,
      previousSalary: previous,
      effectiveDate: _effectiveDate,
      issuedByUid: widget.viewer.uid,
      issuedByName: widget.viewer.name,
      createdAt: now,
    ).withRenderedBody();
    Navigator.pop(context, letter);
  }

  @override
  Widget build(BuildContext context) {
    final previousLocked =
        (_previousSalaryController.text.isNotEmpty &&
        (double.tryParse(_previousSalaryController.text) ?? 0) > 0);

    return AlertDialog(
      title: const Text('Generate increment letter'),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? Text(_error!)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_people.isEmpty)
                      const Text('No employees yet. Add someone in HR & People first.')
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey('inc-emp-$_employeeUid'),
                        initialValue: _people.any((u) => u.uid == _employeeUid)
                            ? _employeeUid
                            : null,
                        items: _people
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.uid,
                                child: Text(
                                  '${u.name} (${HrLetter.formatInr(u.monthlySalary)})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          final emp = _people.where((u) => u.uid == v);
                          if (emp.isEmpty) return;
                          setState(() => _applyEmployee(emp.first));
                        },
                        decoration: const InputDecoration(labelText: 'Employee'),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _previousSalaryController,
                      readOnly: previousLocked,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Current monthly salary (₹)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'New monthly salary (₹)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Effective date'),
                      subtitle: Text(
                        HrLetter.formatDisplayDate(_effectiveDate),
                      ),
                      trailing: const Icon(Icons.event_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _effectiveDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _effectiveDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: const Text('Preview'),
        ),
      ],
    );
  }
}
