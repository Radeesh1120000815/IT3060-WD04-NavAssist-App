import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'safety_routes.dart';
import 'widgets/safety_widgets.dart';

class CommunityHazardScreen extends StatelessWidget {
  const CommunityHazardScreen({super.key});

  static const _hazards = [
    (
      'Broken pavement',
      'Uneven slabs narrow the clear walking path.',
      'Maple Street, near the library',
      'High',
      '4 October 2026, 9:15 AM',
    ),
    (
      'Temporary obstruction',
      'Construction barrier partly blocks the pavement.',
      'Civic Square east entrance',
      'Medium',
      '3 October 2026, 4:40 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community hazards')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const DemoDataBanner(
            message: 'These reports are mock examples. Community reporting is not connected yet.',
          ),
          const SizedBox(height: 20),
          for (final hazard in _hazards) _HazardCard(hazard: hazard),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(SafetyRoutes.reportHazard),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Report hazard'),
      ),
    );
  }
}

class _HazardCard extends StatelessWidget {
  const _HazardCard({required this.hazard});

  final (String, String, String, String, String) hazard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hazard.$1,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(hazard.$2),
            const SizedBox(height: 8),
            DetailRow(
              icon: Icons.place_outlined,
              label: 'Location',
              value: hazard.$3,
            ),
            DetailRow(
              icon: Icons.priority_high,
              label: 'Severity',
              value: hazard.$4,
            ),
            DetailRow(
              icon: Icons.schedule,
              label: 'Reported',
              value: hazard.$5,
            ),
            const Text(
              'Edit and delete controls will appear only for reports owned by the signed-in user.',
            ),
          ],
        ),
      ),
    );
  }
}
