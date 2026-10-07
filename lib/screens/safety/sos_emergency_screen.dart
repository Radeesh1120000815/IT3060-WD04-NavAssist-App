import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/emergency_contact.dart';
import 'data/emergency_contact_repository.dart';
import 'safety_routes.dart';
import 'widgets/safety_widgets.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key, this.repository});

  final EmergencyContactDataSource? repository;

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 3);
  late final AnimationController _holdController;
  late final EmergencyContactDataSource _repository;
  late Stream<List<EmergencyContact>> _contacts;
  bool _holding = false;
  bool _active = false;
  String? _holdStatus;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmergencyContactRepository();
    _contacts = _contactStream();
    _holdController = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() {
          _holding = false;
          _active = true;
          _holdStatus = null;
        });
      });
  }

  Stream<List<EmergencyContact>> _contactStream() {
    try {
      return _repository.streamEmergencyContacts();
    } on Object catch (error) {
      return Stream<List<EmergencyContact>>.error(error);
    }
  }

  void _retryContacts() {
    setState(() => _contacts = _contactStream());
  }

  void _startHold() {
    if (_active || _holding) return;
    setState(() {
      _holding = true;
      _holdStatus = null;
    });
    _holdController.forward(from: 0);
  }

  void _releaseHold() {
    if (!_holding || _active) return;
    _holdController
      ..stop()
      ..reset();
    setState(() {
      _holding = false;
      _holdStatus = 'Hold cancelled. Press and hold again when you are ready.';
    });
  }

  void _cancelSos() {
    _holdController.reset();
    setState(() {
      _active = false;
      _holding = false;
      _holdStatus = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Simulated SOS cancelled. No call, message, or location was sent.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<List<EmergencyContact>>(
      stream: _contacts,
      builder: (context, contactSnapshot) => Scaffold(
        appBar: AppBar(title: const Text('SOS / Emergency')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: _active
              ? _buildActiveContent(context, colors, contactSnapshot)
              : _buildInactiveContent(context, colors, contactSnapshot),
        ),
      ),
    );
  }

  List<Widget> _buildInactiveContent(
    BuildContext context,
    ColorScheme colors,
    AsyncSnapshot<List<EmergencyContact>> contactSnapshot,
  ) {
    return [
      const DemoDataBanner(
        message: 'Prototype only. No calls, messages, location sharing, or emergency dispatch will occur.',
      ),
      const SizedBox(height: 20),
      const SafetySectionTitle('Emergency assistance'),
      const SizedBox(height: 6),
      const Text(
        'The demo will show how an SOS could notify your chosen contact and share your location.',
      ),
      const SizedBox(height: 20),
      const SafetySectionTitle('Emergency contact'),
      const SizedBox(height: 8),
      _buildContactContent(context, contactSnapshot),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => context.push(SafetyRoutes.manageEmergencyContacts),
        icon: const Icon(Icons.manage_accounts_outlined),
        label: const Text('Manage contacts'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
      const SizedBox(height: 16),
      const SafetySectionTitle('Location sharing'),
      const SizedBox(height: 8),
      const _EmergencyInfoCard(
        icon: Icons.location_on_outlined,
        title: 'Main Street, near the bus stop',
        primaryDetail: 'Demo location ready to share',
        secondaryDetail: 'Device location is not being accessed or transmitted',
      ),
      const SizedBox(height: 24),
      Text(
        'Press and hold for 3 seconds to activate.',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      const Text('Release early to cancel.', textAlign: TextAlign.center),
      const SizedBox(height: 12),
      AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          final progress = _holdController.value;
          final remainingSeconds = ((1 - progress) * 3).ceil().clamp(0, 3);
          return Semantics(
            button: true,
            label: 'Activate SOS. Press and hold for 3 seconds. Release early to cancel.',
            value: _holding
                ? '${(progress * 100).round()} percent complete. About $remainingSeconds seconds remaining.'
                : 'Inactive',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _startHold(),
              onTapUp: (_) => _releaseHold(),
              onTapCancel: _releaseHold,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 176),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  border: Border.all(
                    color: colors.error,
                    width: _holding ? 4 : 2.5,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos, size: 58, color: colors.error),
                    const SizedBox(height: 8),
                    Text(
                      _holding ? 'Keep holding' : 'Hold to activate SOS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      color: colors.error,
                      backgroundColor: colors.surface,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _holding
                          ? '$remainingSeconds seconds remaining • Release to cancel'
                          : '3-second safety hold required',
                      style: TextStyle(color: colors.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      if (_holdStatus != null) ...[
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: Text(
            _holdStatus!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildActiveContent(
    BuildContext context,
    ColorScheme colors,
    AsyncSnapshot<List<EmergencyContact>> contactSnapshot,
  ) {
    final availableContacts =
        contactSnapshot.data ?? const <EmergencyContact>[];
    final primaryContacts = availableContacts.where(
      (contact) => contact.isPrimary,
    );
    final contact =
        primaryContacts.firstOrNull ?? availableContacts.firstOrNull;
    return [
      Semantics(
        liveRegion: true,
        container: true,
        label: 'Simulated SOS activated. Prototype only. No emergency service was contacted.',
        child: ExcludeSemantics(
          child: Card(
            color: colors.errorContainer,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.error, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.sos, size: 54, color: colors.error),
                  const SizedBox(height: 10),
                  Text(
                    'SOS activated',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simulated active state',
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _EmergencyInfoCard(
        icon: Icons.person_outline,
        title: 'Emergency contact',
        primaryDetail: contact == null
            ? 'No emergency contact was selected'
            : '${contact.name} - ${contact.relationship} - ${contact.phone}',
        secondaryDetail: 'No call or message was actually sent. No real contact was notified.',
      ),
      const SizedBox(height: 12),
      const _EmergencyInfoCard(
        icon: Icons.location_on_outlined,
        title: 'Location sharing',
        primaryDetail: 'Enabled for this demo',
        secondaryDetail: 'No device location was accessed or shared',
      ),
      const SizedBox(height: 16),
      Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This is a prototype. No police, ambulance, emergency service, or external contact was notified.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: _cancelSos,
        icon: const Icon(Icons.close),
        label: const Text('Cancel SOS'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: colors.error,
          side: BorderSide(color: colors.error, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ];
  }

  Widget _buildContactContent(
    BuildContext context,
    AsyncSnapshot<List<EmergencyContact>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const _ContactLoadingCard();
    }
    if (snapshot.hasError) {
      return _ContactErrorCard(
        message: emergencyContactErrorMessage(
          snapshot.error!,
          operation: 'load',
        ),
        onRetry: _retryContacts,
      );
    }
    final contacts = snapshot.data ?? const <EmergencyContact>[];
    if (contacts.isEmpty) {
      return _NoContactCard(
        onAdd: () => context.push(SafetyRoutes.addEmergencyContact),
      );
    }
    final primaryContacts = contacts.where((contact) => contact.isPrimary);
    final contact = primaryContacts.firstOrNull ?? contacts.first;
    return _EmergencyInfoCard(
      icon: Icons.person_outline,
      title: contact.name,
      primaryDetail: '${contact.relationship} - ${contact.phone}',
      secondaryDetail: contacts.length > 1
          ? 'Primary saved contact. ${contacts.length} contacts saved. No call or message will be sent.'
          : 'Saved emergency contact. No call or message will be sent.',
    );
  }
}

class _ContactLoadingCard extends StatelessWidget {
  const _ContactLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Semantics(
          liveRegion: true,
          label: 'Loading emergency contacts',
          child: const Row(
            children: [
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 14),
              Expanded(child: Text('Loading emergency contact...')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoContactCard extends StatelessWidget {
  const _NoContactCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No emergency contact saved',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('Add someone you trust for the SOS prototype.'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add emergency contact'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactErrorCard extends StatelessWidget {
  const _ContactErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not load emergency contacts',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(message),
              const SizedBox(height: 12),
              OutlinedButton.icon(
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

class _EmergencyInfoCard extends StatelessWidget {
  const _EmergencyInfoCard({
    required this.icon,
    required this.title,
    required this.primaryDetail,
    required this.secondaryDetail,
  });

  final IconData icon;
  final String title;
  final String primaryDetail;
  final String secondaryDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(primaryDetail),
                  const SizedBox(height: 4),
                  Text(
                    secondaryDetail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
