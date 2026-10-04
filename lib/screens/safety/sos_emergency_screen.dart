import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/safety_widgets.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  static const _holdDuration = Duration(seconds: 3);
  Timer? _timer;
  bool _holding = false;
  bool _confirmed = false;

  void _startHold() {
    if (_confirmed) return;
    setState(() => _holding = true);
    _timer?.cancel();
    _timer = Timer(_holdDuration, () {
      if (!mounted || !_holding) return;
      setState(() {
        _holding = false;
        _confirmed = true;
      });
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    if (mounted && _holding) setState(() => _holding = false);
  }

  void _cancelConfirmation() {
    setState(() => _confirmed = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prototype SOS cancelled. No call or message was sent.'),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS / Emergency')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoDataBanner(
            message: 'Prototype only. This screen does not call, message, or dispatch emergency services.',
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: _holding ? 'Continue holding SOS for three seconds' : 'Press and hold SOS for three seconds. A short tap will not activate it.',
            child: GestureDetector(
              onLongPressStart: (_) => _startHold(),
              onLongPressEnd: (_) => _cancelHold(),
              onLongPressCancel: _cancelHold,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 180),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  border: Border.all(color: colors.error, width: 3),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sos, size: 64, color: colors.error),
                    Text(
                      _holding ? 'Keep holding…' : 'Press and hold',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '3 seconds',
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_holding) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              semanticsLabel: 'SOS hold in progress',
            ),
            const SizedBox(height: 8),
            const Text('Release now to cancel.'),
          ],
          if (_confirmed) ...[
            const SizedBox(height: 24),
            Card(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SOS confirmed — prototype only',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No emergency action has been sent. You can safely cancel this confirmation.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _cancelConfirmation,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel SOS'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const SafetySectionTitle('Emergency contacts'),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              minVerticalPadding: 16,
              leading: Icon(Icons.person_outline, size: 32),
              title: Text('Maya Perera'),
              subtitle: Text(
                'Sister • 077 123 4567\nDemo contact — calling is not enabled',
              ),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}
