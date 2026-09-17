import 'package:flutter/material.dart';

import '../../models/company.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class PlatformAuditLogsScreen extends StatefulWidget {
  final UserProfile platformAdmin;

  const PlatformAuditLogsScreen({
    super.key,
    required this.platformAdmin,
  });

  @override
  State<PlatformAuditLogsScreen> createState() =>
      _PlatformAuditLogsScreenState();
}

class _PlatformAuditLogsScreenState extends State<PlatformAuditLogsScreen> {
  final _firestoreService = FirestoreService();

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Platform Logs'),
      ),
      body: StreamBuilder<List<Company>>(
        stream: _firestoreService.streamAllCompanies(),
        builder: (context, companySnapshot) {
          final companies = companySnapshot.data ?? [];

          return StreamBuilder<List<UserProfile>>(
            stream: _firestoreService.streamAllPlatformUsers(),
            builder: (context, userSnapshot) {
              final users = userSnapshot.data ?? [];

              // Build combined timeline events
              final List<_AuditEvent> events = [];

              for (var c in companies) {
                if (c.createdAt != null) {
                  events.add(
                    _AuditEvent(
                      title: 'Tenant Provisioned: ${c.name}',
                      description:
                          'Organization created with Primary Admin ${c.adminEmail} (ID: ${c.id})',
                      timestamp: c.createdAt!,
                      type: _AuditEventType.tenantCreated,
                    ),
                  );
                }
              }

              for (var u in users) {
                if (u.createdAt != null) {
                  events.add(
                    _AuditEvent(
                      title: 'User Registered: ${u.name}',
                      description:
                          'Account created with role ${u.role} under ${u.companyName.isNotEmpty ? u.companyName : "Platform"} (${u.email})',
                      timestamp: u.createdAt!,
                      type: _AuditEventType.userRegistered,
                    ),
                  );
                }
              }

              // Sort chronologically (latest first)
              events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Security Status Card
                    Card(
                      elevation: 0,
                      color: Colors.indigo.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white24,
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Platform Audit Monitor',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tracking multi-tenant lifecycle & identity activities.',
                                    style: TextStyle(
                                      color: Colors.indigo.shade100,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'System Activity Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (events.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off_rounded,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No recent system events logged.'),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          Color iconBg = Colors.blue.shade50;
                          Color iconColor = Colors.blue.shade800;
                          IconData icon = Icons.event_note_rounded;

                          if (event.type == _AuditEventType.tenantCreated) {
                            iconBg = Colors.indigo.shade50;
                            iconColor = Colors.indigo.shade800;
                            icon = Icons.apartment_rounded;
                          } else if (event.type ==
                              _AuditEventType.userRegistered) {
                            iconBg = Colors.teal.shade50;
                            iconColor = Colors.teal.shade800;
                            icon = Icons.person_add_rounded;
                          }

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: iconBg,
                                    child: Icon(icon, color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          event.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(event.timestamp),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _AuditEventType {
  tenantCreated,
  userRegistered,
}

class _AuditEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final _AuditEventType type;

  _AuditEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });
}
