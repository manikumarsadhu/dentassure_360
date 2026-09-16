import 'package:flutter/material.dart';

import '../../models/user_profile.dart';

class LettersScreen extends StatelessWidget {
  final UserProfile viewer;

  const LettersScreen({super.key, required this.viewer});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Letters & Documents',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Offer, appointment, increment, and warning letters will be generated from approved templates and filed against the employee record.',
        ),
        const SizedBox(height: 20),
        ...[
          'Offer letter',
          'Appointment letter',
          'Increment letter',
          'Warning letter',
        ].map(
          (title) => Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(title),
              subtitle: const Text('Template ready — e-sign coming later'),
              trailing: const Chip(label: Text('Soon')),
            ),
          ),
        ),
      ],
    );
  }
}
