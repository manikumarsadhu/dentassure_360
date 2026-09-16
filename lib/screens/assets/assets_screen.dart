import 'package:flutter/material.dart';

import '../../models/company_asset.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class AssetsScreen extends StatefulWidget {
  final UserProfile viewer;

  const AssetsScreen({super.key, required this.viewer});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _firestore = FirestoreService();

  Future<void> _addAsset(List<UserProfile> people) async {
    final name = TextEditingController();
    final serial = TextEditingController();
    var type = 'LAPTOP';
    String assignedUid = '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Register asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Asset name'),
                ),
                TextFormField(
                  controller: serial,
                  decoration: const InputDecoration(labelText: 'Serial / ID'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 'LAPTOP', child: Text('Laptop')),
                    DropdownMenuItem(value: 'SIM', child: Text('SIM')),
                    DropdownMenuItem(value: 'ID_CARD', child: Text('ID card')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) => setDialog(() => type = v ?? type),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: assignedUid,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Unassigned')),
                    ...people.map(
                      (u) => DropdownMenuItem(value: u.uid, child: Text(u.name)),
                    ),
                  ],
                  onChanged: (v) => setDialog(() => assignedUid = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Assign to'),
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

    if (saved != true || name.text.trim().isEmpty) return;
    final assignee = people.where((u) => u.uid == assignedUid).firstOrNull;
    await _firestore.saveAsset(
      CompanyAsset(
        id: '',
        companyId: widget.viewer.companyId,
        name: name.text.trim(),
        type: type,
        serial: serial.text.trim(),
        assignedUid: assignedUid,
        assignedName: assignee?.name ?? '',
        status: assignedUid.isEmpty ? 'AVAILABLE' : 'ASSIGNED',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personal = !widget.viewer.isPeopleOps;
    return StreamBuilder<List<UserProfile>>(
      stream: _firestore.streamCompanyEmployees(widget.viewer.companyId),
      builder: (context, usersSnap) {
        final people = usersSnap.data ?? [];
        return StreamBuilder<List<CompanyAsset>>(
          stream: personal
              ? _firestore.streamEmployeeAssets(widget.viewer.uid)
              : _firestore.streamCompanyAssets(widget.viewer.companyId),
          builder: (context, snapshot) {
            final assets = snapshot.data ?? [];
            return Scaffold(
              appBar: AppBar(
                title: Text(personal ? 'My Assets' : 'Company Assets'),
              ),
              floatingActionButton: widget.viewer.isPeopleOps
                  ? FloatingActionButton.extended(
                      onPressed: () => _addAsset(people),
                      icon: const Icon(Icons.add),
                      label: const Text('Add asset'),
                    )
                  : null,
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (assets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No assets found.'),
                    )
                  else
                    ...assets.map((asset) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.devices_other_outlined),
                            title: Text(asset.name),
                            subtitle: Text(
                              '${asset.type} • ${asset.serial.isEmpty ? "No serial" : asset.serial} • ${asset.assignedName.isEmpty ? "Unassigned" : asset.assignedName}',
                            ),
                            trailing: Chip(label: Text(asset.status)),
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
