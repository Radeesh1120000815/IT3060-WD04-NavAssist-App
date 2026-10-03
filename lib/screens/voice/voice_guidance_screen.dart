import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/instruction_history_entry.dart';
import 'data/voice_repository.dart';
import 'data/voice_settings.dart';
import 'data/voice_settings_provider.dart';
import 'services/voice_service.dart';
import 'theme/voice_theme.dart';
import 'widgets/voice_widgets.dart';

/// Voice Guidance settings (voice_guidance.png), UR-01.
///
/// Voice on/off, volume, speech speed, which things are announced and a
/// test button. Added (see DEVIATIONS.md): the current instruction with a
/// Replay button, and the instruction history with a Clear button.
class VoiceGuidanceScreen extends StatefulWidget {
  const VoiceGuidanceScreen({super.key});

  @override
  State<VoiceGuidanceScreen> createState() => _VoiceGuidanceScreenState();
}

class _VoiceGuidanceScreenState extends State<VoiceGuidanceScreen> {
  // Volume while the slider is being dragged; saved when the drag ends,
  // so Firestore gets one write instead of one per pixel.
  double? _dragVolume;

  // "0.75×", "1×", "1.25×", "1.5×"
  static String _speedText(double rate) =>
      rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : '$rate';

  Future<void> _testVoice() async {
    final spoken = await context.read<VoiceService>().testAnnouncement();
    if (!spoken && mounted) {
      showMessage(context, 'Text-to-speech is not available on this phone.');
    }
  }

  Future<void> _replay() async {
    final spoken = await context.read<VoiceService>().replay();
    if (!spoken && mounted) {
      showMessage(context, 'Voice guidance is off. Turn it on to hear it.');
    }
  }

  Future<void> _clearHistory() async {
    final repository = context.read<VoiceSettingsProvider>().repository;
    final ok = await confirmAction(
      context,
      title: 'Clear instruction history?',
      message: 'This deletes every saved spoken instruction.',
      confirmLabel: 'Clear',
    );
    if (!ok) return;
    try {
      await repository.clearInstructionHistory();
      if (mounted) showMessage(context, 'Instruction history cleared.');
    } on VoiceDataException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final provider = context.watch<VoiceSettingsProvider>();
    final s = provider.settings;
    final volume = _dragVolume ?? s.volume;
    void save(VoiceSettings changed) => provider.updateSettings(changed);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const VoiceHeader(title: 'Voice Guidance'),
            if (provider.errorMessage != null)
              NoteText(provider.errorMessage!, icon: Icons.cloud_off),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Voice guidance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Spoken turn-by-turn instructions'),
              value: s.voiceEnabled,
              onChanged: (v) => save(s.copyWith(voiceEnabled: v)),
            ),
            const SizedBox(height: 8),
            // The slider reads its own value, so this row is hidden from
            // TalkBack to avoid hearing the volume twice.
            ExcludeSemantics(
              child: Row(
                children: [
                  Text(
                    'Volume',
                    style: TextStyle(
                      color: p.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(volume * 100).round()}%',
                    style: TextStyle(
                      color: p.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Volume',
              child: Slider(
                value: volume,
                divisions: 20,
                semanticFormatterCallback: (v) =>
                    '${(v * 100).round()} percent',
                onChanged: (v) => setState(() => _dragVolume = v),
                onChangeEnd: (v) {
                  setState(() => _dragVolume = null);
                  save(s.copyWith(volume: v));
                },
              ),
            ),
            const SectionTitle('Speech speed'),
            ChoiceRow<double>(
              options: VoiceSettings.allowedSpeechRates,
              selected: s.speechRate,
              labelOf: (r) => '${_speedText(r)}×',
              semanticLabelOf: (r) => 'Speech speed ${_speedText(r)} times',
              onSelected: (r) => save(s.copyWith(speechRate: r)),
            ),
            const SectionTitle('Announce'),
            ..._announceSwitches(s, save),
            const SizedBox(height: 24),
            TonalButton(
              icon: Icons.volume_up,
              label: 'Test voice announcement',
              onPressed: _testVoice,
            ),
            const SectionTitle('Current instruction'),
            _CaptionCard(onReplay: _replay),
            SectionTitle(
              'Instruction history',
              trailing: TextButton(
                onPressed: _clearHistory,
                child: const Text(
                  'Clear',
                  semanticsLabel: 'Clear instruction history',
                ),
              ),
            ),
            StreamList<InstructionHistoryEntry>(
              createStream: () =>
                  provider.repository.watchInstructionHistory(limit: 10),
              emptyText: 'No instructions spoken yet.',
              itemBuilder: (context, entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.record_voice_over, color: p.primary),
                title: Text(entry.text),
                subtitle: Text('Spoken at ${formatTime(entry.spokenAt)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The five "Announce" switches.
  List<Widget> _announceSwitches(
    VoiceSettings s,
    void Function(VoiceSettings) save,
  ) {
    return [
      _announceTile(
        'Turn instructions',
        s.announceTurns,
        (v) => save(s.copyWith(announceTurns: v)),
      ),
      _announceTile(
        'Obstacle alerts',
        s.announceObstacles,
        (v) => save(s.copyWith(announceObstacles: v)),
      ),
      _announceTile(
        'Road crossing alerts',
        s.announceCrossings,
        (v) => save(s.copyWith(announceCrossings: v)),
      ),
      _announceTile(
        'Arrival announcement',
        s.announceArrival,
        (v) => save(s.copyWith(announceArrival: v)),
      ),
      _announceTile(
        'Distance updates',
        s.announceDistance,
        (v) => save(s.copyWith(announceDistance: v)),
      ),
    ];
  }

  // One switch with a divider under it.
  Widget _announceTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value,
          onChanged: onChanged,
        ),
        const Divider(),
      ],
    );
  }
}

/// Shows the current instruction as text, with a Replay button.
class _CaptionCard extends StatelessWidget {
  const _CaptionCard({required this.onReplay});

  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = context.watch<VoiceService>().lastInstruction;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            last ?? 'No instruction yet. Start navigating to hear directions.',
            style: TextStyle(
              color: p.text,
              fontSize: 18,
              fontWeight: last == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: last == null ? null : onReplay,
              icon: const Icon(Icons.replay),
              label: const Text('Replay'),
            ),
          ),
        ],
      ),
    );
  }
}
