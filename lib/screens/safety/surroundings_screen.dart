import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'safety_routes.dart';
import 'widgets/safety_widgets.dart';

class SurroundingsScreen extends StatelessWidget {
  const SurroundingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore surroundings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoDataBanner(
            message: 'Nearby information shown here is demonstration data, not live location data.',
          ),
          const SizedBox(height: 20),
          const SafetySectionTitle('Nearby places'),
          const SizedBox(height: 8),
          _PlaceCard(
            name: 'Central Library',
            details: 'Landmark • 120 metres ahead',
            icon: Icons.local_library_outlined,
            onTap: () => context.push(SafetyRoutes.landmark),
          ),
          _PlaceCard(
            name: 'Main Street bus stop',
            details: 'Public transport • 250 metres',
            icon: Icons.directions_bus_outlined,
            onTap: () => context.push(SafetyRoutes.publicTransport),
          ),
          const SizedBox(height: 20),
          const SafetySectionTitle('Quick actions'),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.directions_bus_outlined,
            title: 'Public transport',
            subtitle: 'View nearby demo services',
            onTap: () => context.push(SafetyRoutes.publicTransport),
          ),
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
    required this.details,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String details;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Semantics(
        button: true,
        label: '$name. $details. Open details.',
        child: ListTile(
          minVerticalPadding: 16,
          leading: ExcludeSemantics(child: Icon(icon, size: 32)),
          title: Text(name),
          subtitle: Text(details),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
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
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: ListTile(
          minVerticalPadding: 16,
          leading: ExcludeSemantics(
            child: Icon(
              icon,
              size: 32,
              color: isEmergency ? colors.error : null,
            ),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
