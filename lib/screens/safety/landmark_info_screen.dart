import 'package:flutter/material.dart';

import 'widgets/safety_widgets.dart';

class LandmarkInfoScreen extends StatelessWidget {
  const LandmarkInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Landmark information')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoDataBanner(
            message: 'This landmark profile uses demonstration data.',
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              'Central Library',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          const DetailRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: 'Public library',
          ),
          const DetailRow(
            icon: Icons.straighten,
            label: 'Distance',
            value: '120 metres ahead',
          ),
          const SizedBox(height: 16),
          const SafetySectionTitle('About this landmark'),
          const SizedBox(height: 8),
          const Text(
            'A public library beside the civic square, with its main entrance facing Maple Street.',
          ),
          const SizedBox(height: 20),
          const SafetySectionTitle('Accessibility'),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Step-free entrance, tactile paving at the main door, and an accessible service desk.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigation is not connected in this prototype.'),
              ),
            ),
            icon: const Icon(Icons.navigation_outlined),
            label: const Text('Navigate'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Spoken information will be connected during integration.',
                ),
              ),
            ),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Speak information (prototype)'),
          ),
        ],
      ),
    );
  }
}
