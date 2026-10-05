import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/instruction_feedback.dart';
import 'data/voice_repository.dart';
import 'data/voice_settings_provider.dart';
import 'services/haptic_service.dart';
import 'services/navigation_session.dart';
import 'services/voice_service.dart';
import 'theme/voice_theme.dart';
import 'widgets/voice_widgets.dart';

/// Navigation Instruction Feedback (instruction_feedback_wireframe.png),
/// UR-01.
///
/// Confirms "On track" with a short vibration and a spoken message (the
/// app has no audio player, so this replaces the chime), previews the next
/// instruction, and lets the user say whether the instruction was clear.
/// Feedback is saved to settings/{uid}/feedback (create, read, update,
/// delete).
class InstructionFeedbackScreen extends StatefulWidget {
  const InstructionFeedbackScreen({super.key});

  @override
  State<InstructionFeedbackScreen> createState() =>
      _InstructionFeedbackScreenState();
}

class _InstructionFeedbackScreenState extends State<InstructionFeedbackScreen> {
  late final VoiceRepository _repository;
  FeedbackStatus _status = FeedbackStatus.onTrack;

  @override
  void initState() {
    super.initState();
    _repository = context.read<VoiceSettingsProvider>().repository;
    // Play the confirmation when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _playConfirmation());
  }

  // Replaces the wireframe's chime: one short pulse + "You are on track."
  void _playConfirmation() {
    if (!mounted) return;
    context.read<HapticService>().vibrateLow();
    context.read<VoiceService>().speakMessage('You are on track.');
  }

  Future<void> _save(FeedbackStatus status) async {
    final session = context.read<NavigationSession>();
    setState(() => _status = status);
    if (status == FeedbackStatus.onTrack) {
      _playConfirmation();
    } else {
      session.repeat(); // say the unclear instruction again
    }
    try {
      await _repository.addFeedback(session.currentStep.displayText, status);
      if (!mounted) return;
      showMessage(
        context,
        status == FeedbackStatus.onTrack
            ? 'Saved: on track.'
            : 'Saved: instruction unclear. Repeating it now.',
      );
    } on VoiceDataException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on VoiceDataException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final session = context.watch<NavigationSession>();
    final next = session.nextStep;
    final onTrack = _status == FeedbackStatus.onTrack;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const VoiceHeader(
              title: 'Instruction Feedback',
              subtitle: 'Navigation active',
            ),
            const SizedBox(height: 8),
            // Status card (icon + words, not colour only).
            InfoCard(
              color: p.background,
              child: Semantics(
                liveRegion: true,
                container: true,
                child: Column(
                  children: [
                    Text(
                      'STATUS',
                      style: TextStyle(
                        color: p.mutedText,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          onTrack ? Icons.check_circle : Icons.help,
                          color: onTrack ? p.success : p.danger,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            onTrack ? 'On track' : 'Instruction unclear',
                            style: TextStyle(
                              color: p.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.vibration, color: p.mutedText, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Confirmation: one short vibration and the words "You are on track".',
                    style: TextStyle(color: p.mutedText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoCard(
              color: p.background,
              child: Column(
                children: [
                  Text(
                    'NEXT INSTRUCTION PREVIEW',
                    style: TextStyle(
                      color: p.mutedText,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    next?.previewText ??
                        'You will arrive at ${session.destination}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Now: ${session.currentStep.displayText}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _save(FeedbackStatus.onTrack),
              icon: const Icon(Icons.check),
              label: const Text('On track'),
              style: FilledButton.styleFrom(
                backgroundColor: p.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _save(FeedbackStatus.unclear),
              icon: const Icon(Icons.help_outline),
              label: const Text('Instruction unclear'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SectionTitle('Recent feedback'),
            StreamList<InstructionFeedback>(
              createStream: _repository.watchFeedback,
              maxItems: 5,
              emptyText: 'No feedback yet.',
              itemBuilder: (context, item) => _FeedbackTile(
                item: item,
                onSwitch: () => _run(
                  () => _repository.updateFeedback(
                    item.id,
                    item.status == FeedbackStatus.onTrack
                        ? FeedbackStatus.unclear
                        : FeedbackStatus.onTrack,
                  ),
                ),
                onDelete: () => _run(() => _repository.deleteFeedback(item.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One saved feedback: status, instruction, time, change and delete.
class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    required this.item,
    required this.onSwitch,
    required this.onDelete,
  });

  final InstructionFeedback item;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onTrack = item.status == FeedbackStatus.onTrack;
    return Column(
      children: [
        Row(
          children: [
            Icon(
              onTrack ? Icons.check_circle : Icons.help,
              color: onTrack ? p.success : p.danger,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onTrack ? 'On track' : 'Unclear',
                    style: TextStyle(
                      color: p.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(item.instruction, style: TextStyle(color: p.text)),
                  Text(
                    formatTime(item.createdAt),
                    style: TextStyle(color: p.mutedText),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onSwitch,
              icon: const Icon(Icons.swap_horiz),
              tooltip: onTrack ? 'Change to unclear' : 'Change to on track',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: p.danger),
              tooltip: 'Delete feedback',
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
