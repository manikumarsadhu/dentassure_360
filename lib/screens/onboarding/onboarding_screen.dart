import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_motion.dart';

class OnboardingScreen extends StatelessWidget {
  final UserProfile viewer;

  const OnboardingScreen({super.key, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return StreamBuilder<List<UserProfile>>(
      stream: firestore.streamCompanyEmployees(viewer.companyId),
      builder: (context, snapshot) {
        final people = (snapshot.data ?? [])
            .where((u) => !u.isPlatformAdmin)
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Employee Onboarding',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track day-one readiness: documents, assets, and access.',
            ),
            const SizedBox(height: 16),
            if (people.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...people.map(
                (emp) => MotionCard(
                  child: Card(
                    child: ExpansionTile(
                      title: Text(emp.name),
                      subtitle: Text(
                        emp.isOnboardingComplete
                            ? 'Day-one ready'
                            : 'Checklist in progress',
                      ),
                      trailing: Icon(
                        emp.isOnboardingComplete
                            ? Icons.check_circle
                            : Icons.pending_outlined,
                        color: emp.isOnboardingComplete
                            ? Colors.green
                            : Colors.orange,
                      ),
                      children: [
                        CheckboxListTile(
                          value: emp.onboardingDocsCollected,
                          title: const Text('Documents collected'),
                          onChanged: viewer.isPeopleOps
                              ? (v) => firestore.updateOnboardingChecklist(
                                  uid: emp.uid,
                                  docsCollected: v ?? false,
                                  assetsAssigned: emp.onboardingAssetsAssigned,
                                  accessReady: emp.onboardingAccessReady,
                                )
                              : null,
                        ),
                        CheckboxListTile(
                          value: emp.onboardingAssetsAssigned,
                          title: const Text('Assets assigned'),
                          onChanged: viewer.isPeopleOps
                              ? (v) => firestore.updateOnboardingChecklist(
                                  uid: emp.uid,
                                  docsCollected: emp.onboardingDocsCollected,
                                  assetsAssigned: v ?? false,
                                  accessReady: emp.onboardingAccessReady,
                                )
                              : null,
                        ),
                        CheckboxListTile(
                          value: emp.onboardingAccessReady,
                          title: const Text('Access ready'),
                          onChanged: viewer.isPeopleOps
                              ? (v) => firestore.updateOnboardingChecklist(
                                  uid: emp.uid,
                                  docsCollected: emp.onboardingDocsCollected,
                                  assetsAssigned: emp.onboardingAssetsAssigned,
                                  accessReady: v ?? false,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
