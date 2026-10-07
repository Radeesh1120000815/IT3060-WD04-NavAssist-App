import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'landmark_info_screen.dart';
import 'safety_routes.dart';
import 'widgets/safety_widgets.dart';

class SurroundingsScreen extends StatelessWidget {
  const SurroundingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const centralLibrary = LandmarkData.demo;

    return Scaffold(
      appBar: AppBar(title: const Text('Explore surroundings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoDataBanner(
            message: 'Nearby information shown here is demonstration data, not live location data.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Nearby places: ${centralLibrary.name}, ${centralLibrary.distance}, ${centralLibrary.direction}. Main Street bus stop, 250 metres away, ahead on the right.',
                ),
              ),
            ),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Speak / replay nearby places'),
          ),
          const SizedBox(height: 20),
          const SafetySectionTitle('Nearby places'),
          const SizedBox(height: 8),
          _PlaceCard(
            name: centralLibrary.name,
            category: centralLibrary.category,
            distance: centralLibrary.distance,
            direction: centralLibrary.direction,
            icon: Icons.local_library_outlined,
            actionLabel: 'View landmark',
            onTap: () =>
                context.push(SafetyRoutes.landmark, extra: centralLibrary),
          ),
          _PlaceCard(
            name: 'Main Street bus stop',
            category: 'Public transport',
            distance: '250 metres away',
            direction: 'Ahead, on the right',
            icon: Icons.directions_bus_outlined,
            actionLabel: 'View transport',
            onTap: () => context.push(SafetyRoutes.publicTransport),
          ),
          const SizedBox(height: 20),
          const SafetySectionTitle('Safety shortcuts'),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.warning_amber_rounded,
            title: 'Community hazards',
            subtitle: 'Review reported obstacles nearby',
            onTap: () => context.push(SafetyRoutes.hazards),
          ),
          _ActionTile(
            icon: Icons.sos,
            title: 'SOS / Emergency',
            subtitle: 'Open the safe press-and-hold prototype',
            isEmergency: true,
            onTap: () => context.push(SafetyRoutes.sos),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.name,
    required this.category,
    required this.distance,
    required this.direction,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String name;
  final String category;
  final String distance;
  final String direction;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Semantics(
        container: true,
        label: '$name, $category, $distance, $direction.',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(category),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _PlaceFact(icon: Icons.straighten, text: distance),
                    _PlaceFact(icon: Icons.explore_outlined, text: direction),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceFact extends StatelessWidget {
  const _PlaceFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(text)],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isEmergency = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: isEmergency ? colors.errorContainer : null,
      child: ListTile(
        minVerticalPadding: 16,
        leading: ExcludeSemantics(
          child: Icon(icon, size: 32, color: isEmergency ? colors.error : null),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
