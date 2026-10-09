import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/hazard.dart';
import 'data/hazard_repository.dart';
import 'safety_routes.dart';
import 'widgets/safety_widgets.dart';

class CommunityHazardScreen extends StatefulWidget {
  const CommunityHazardScreen({super.key, this.repository});

  final HazardDataSource? repository;

  @override
  State<CommunityHazardScreen> createState() => _CommunityHazardScreenState();
}

class _CommunityHazardScreenState extends State<CommunityHazardScreen> {
  late final HazardDataSource _repository;
  late Stream<List<Hazard>> _hazards;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HazardRepository();
    _hazards = _repository.watchHazards();
  }

  void _retry() {
    setState(() => _hazards = _repository.watchHazards());
  }

  Future<void> _confirmDelete(Hazard hazard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete hazard report?'),
        content: Text(
          '${hazard.type} will be permanently removed from community hazards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep report'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Delete report'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteHazard(hazard.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hazard report deleted.')));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community hazards')),
      body: StreamBuilder<List<Hazard>>(
        stream: _hazards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _LoadingHazards();
          }
          if (snapshot.hasError) {
            return _HazardError(
              message: _friendlyError(snapshot.error!),
              onRetry: _retry,
            );
          }

          final hazards = snapshot.data ?? const <Hazard>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              const DemoDataBanner(
                message: 'Community reports update in real time. Distances are unavailable until live location support is added.',
              ),
              const SizedBox(height: 20),
              if (hazards.isEmpty)
                const _EmptyHazards()
              else ...[
                const SafetySectionTitle('Nearby reports'),
                const SizedBox(height: 8),
                for (final hazard in hazards)
                  _HazardCard(
                    hazard: hazard,
                    isOwner: _repository.currentUserId == hazard.reporterId,
                    onEdit: () => context.push(
                      SafetyRoutes.editHazardPath(hazard.id),
                      extra: hazard,
                    ),
                    onDelete: () => _confirmDelete(hazard),
                  ),
              ],
            ],
          );
        },
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
  const _HazardCard({
    required this.hazard,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final Hazard hazard;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (
      badgeColor,
      badgeTextColor,
      severityIcon,
    ) = switch (hazard.severity) {
      HazardSeverity.high => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.dangerous_outlined,
      ),
      HazardSeverity.medium => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.warning_amber_rounded,
      ),
      HazardSeverity.low => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.info_outline,
      ),
    };
    final reportedTime = _reportedTime(hazard.createdAt);
    final semanticSummary =
        '${hazard.type}. ${hazard.severity.label} severity. Distance unavailable. ${hazard.locationName}. '
        '${hazard.description.isEmpty ? 'No additional note.' : hazard.description}. Reported $reportedTime.';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              label: semanticSummary,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hazard.type,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Icon(severityIcon, color: badgeTextColor, size: 22),
                          Text(
                            '${hazard.severity.label} SEVERITY',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: badgeTextColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _HazardFact(
                      icon: Icons.directions_walk_outlined,
                      label: 'Distance',
                      value: 'Not calculated',
                      emphasize: true,
                    ),
                    const SizedBox(height: 10),
                    _HazardFact(
                      icon: Icons.place_outlined,
                      label: 'Location',
                      value: hazard.locationName,
                      emphasize: true,
                    ),
                    if (hazard.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(hazard.description),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Reported $reportedTime',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            if (isOwner) ...[
              const Divider(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Semantics(
                    button: true,
                    label: 'Edit ${hazard.type} hazard report',
                    excludeSemantics: true,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Delete ${hazard.type} hazard report',
                    excludeSemantics: true,
                    child: TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HazardFact extends StatelessWidget {
  const _HazardFact({
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
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: style,
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

class _LoadingHazards extends StatelessWidget {
  const _LoadingHazards();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Loading community hazards',
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading community hazards...'),
          ],
        ),
      ),
    );
  }
}

class _HazardError extends StatelessWidget {
  const _HazardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load hazards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHazards extends StatelessWidget {
  const _EmptyHazards();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No community hazards are currently available.',
      child: ExcludeSemantics(
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No hazards to show',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'New community reports will appear here.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _reportedTime(DateTime? createdAt) {
  if (createdAt == null) return 'just now';
  final difference = DateTime.now().difference(createdAt);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
  if (difference.inHours < 24) return '${difference.inHours} hours ago';
  if (difference.inDays == 1) return 'yesterday';
  return '${difference.inDays} days ago';
}

String _friendlyError(Object error) {
  if (error is HazardRepositoryException) return error.message;
  return 'Check your connection and Firestore permissions, then try again.';
}
