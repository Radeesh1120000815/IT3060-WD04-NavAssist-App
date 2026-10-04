import 'package:flutter/material.dart';

import 'widgets/safety_widgets.dart';

class PublicTransportScreen extends StatelessWidget {
  const PublicTransportScreen({super.key});

  static const _services = [
    (
      '100',
      'City Centre',
      '5 minutes',
      '250 metres',
      'Low-floor bus; audio stop announcements',
    ),
    (
      '138',
      'Railway Station',
      '12 minutes',
      '250 metres',
      'Priority seating and wheelchair space',
    ),
    (
      '177',
      'University',
      '18 minutes',
      '420 metres',
      'Audio stop announcements reported',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public transport')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoDataBanner(
            message: 'Service times are demonstration values and are not live transport information.',
          ),
          const SizedBox(height: 20),
          const SafetySectionTitle('Nearby services'),
          const SizedBox(height: 8),
          for (final service in _services)
            Card(
              child: Semantics(
                label:
                    'Route ${service.$1} to ${service.$2}. Demo arrival ${service.$3}. ${service.$4} away. ${service.$5}.',
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route ${service.$1}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Towards ${service.$2}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      DetailRow(
                        icon: Icons.schedule,
                        label: 'Demo arrival',
                        value: service.$3,
                      ),
                      DetailRow(
                        icon: Icons.straighten,
                        label: 'Stop distance',
                        value: service.$4,
                      ),
                      DetailRow(
                        icon: Icons.accessible,
                        label: 'Accessibility',
                        value: service.$5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
