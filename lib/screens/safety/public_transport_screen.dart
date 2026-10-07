import 'package:flutter/material.dart';

import 'widgets/safety_widgets.dart';

class TransportServiceData {
  const TransportServiceData({
    required this.stopName,
    required this.routeNumber,
    required this.destination,
    required this.distance,
    required this.estimatedArrival,
    required this.accessibilityInformation,
  });

  final String stopName;
  final String routeNumber;
  final String destination;
  final String distance;
  final String estimatedArrival;
  final String accessibilityInformation;
}

class PublicTransportScreen extends StatelessWidget {
  const PublicTransportScreen({super.key});

  static const _services = [
    TransportServiceData(
      stopName: 'Civic Square Bus Stop',
      routeNumber: '100',
      destination: 'City Centre',
      distance: '180 metres away',
      estimatedArrival: '5 minutes',
      accessibilityInformation: 'Low-floor bus with audio stop announcements.',
    ),
    TransportServiceData(
      stopName: 'Main Street Bus Stop',
      routeNumber: '138',
      destination: 'Colombo Fort',
      distance: '250 metres away',
      estimatedArrival: '8 minutes',
      accessibilityInformation: 'Priority seating and wheelchair space.',
    ),
    TransportServiceData(
      stopName: 'University Junction Stop',
      routeNumber: '177',
      destination: 'University',
      distance: '420 metres away',
      estimatedArrival: '18 minutes',
      accessibilityInformation: 'Audio stop announcements reported.',
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
            _TransportServiceCard(service: service),
        ],
      ),
    );
  }
}

class _TransportServiceCard extends StatelessWidget {
  const _TransportServiceCard({required this.service});

  final TransportServiceData service;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticSummary =
        '${service.stopName}. Route ${service.routeNumber} to ${service.destination}. ${service.distance}. Estimated arrival ${service.estimatedArrival}, demo information. ${service.accessibilityInformation}';

    return Semantics(
      container: true,
      label: semanticSummary,
      child: ExcludeSemantics(
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: const Icon(Icons.directions_bus_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service.stopName,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Route ${service.routeNumber}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    Text(
                      'To ${service.destination}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _TransportFact(
                  icon: Icons.directions_walk_outlined,
                  label: 'Distance',
                  value: service.distance,
                  emphasize: true,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TransportFact(
                        icon: Icons.schedule,
                        label: 'Next arrival',
                        value: service.estimatedArrival,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Demo information — not live',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _TransportFact(
                  icon: Icons.accessible,
                  label: 'Accessibility',
                  value: service.accessibilityInformation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransportFact extends StatelessWidget {
  const _TransportFact({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: textStyle,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
