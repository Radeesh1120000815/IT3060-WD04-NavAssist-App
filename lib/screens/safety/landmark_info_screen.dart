import 'package:flutter/material.dart';

import 'widgets/safety_widgets.dart';

class LandmarkData {
  const LandmarkData({
    required this.name,
    required this.category,
    required this.distance,
    required this.direction,
    required this.description,
    required this.accessibilityInformation,
  });

  final String name;
  final String category;
  final String distance;
  final String direction;
  final String description;
  final String accessibilityInformation;

  static const demo = LandmarkData(
    name: 'Central Library',
    category: 'Public library',
    distance: '120 metres away',
    direction: 'Ahead, slightly left',
    description:
        'The main entrance faces Maple Street beside the civic square.',
    accessibilityInformation:
        'Step-free entrance, tactile paving, and an accessible service desk.',
  );
}

class LandmarkInfoScreen extends StatelessWidget {
  const LandmarkInfoScreen({super.key, this.landmark = LandmarkData.demo});

  final LandmarkData landmark;

  void _showPrototypeMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final guidanceSummary =
        '${landmark.name}. ${landmark.distance}. ${landmark.direction}.';

    return Scaffold(
      appBar: AppBar(title: const Text('Landmark information')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoDataBanner(
            message: 'This landmark profile uses demonstration data.',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: const Icon(Icons.location_city_outlined, size: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            landmark.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          landmark.category,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            label: 'Guidance. ${landmark.distance}. ${landmark.direction}.',
            child: Card(
              color: colors.primaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ExcludeSemantics(
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 16,
                    children: [
                      _GuidanceFact(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value: landmark.distance,
                      ),
                      _GuidanceFact(
                        icon: Icons.explore_outlined,
                        label: 'Direction',
                        value: landmark.direction,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SafetySectionTitle('About'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(landmark.description),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  DetailRow(
                    icon: Icons.accessible,
                    label: 'Accessibility',
                    value: landmark.accessibilityInformation,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () => _showPrototypeMessage(
              context,
              '$guidanceSummary Spoken guidance is a prototype and is not connected yet.',
            ),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Speak / replay guidance'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showPrototypeMessage(
              context,
              'Guidance to ${landmark.name} is not connected in this prototype.',
            ),
            icon: const Icon(Icons.navigation_outlined),
            label: const Text('Start guidance'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceFact extends StatelessWidget {
  const _GuidanceFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.onPrimaryContainer, size: 28),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
