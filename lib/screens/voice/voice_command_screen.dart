import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/custom_command.dart';
import 'data/voice_repository.dart';
import 'data/voice_settings_provider.dart';
import 'services/command_service.dart';
import 'theme/voice_theme.dart';
import 'widgets/voice_widgets.dart';

/// Short names for each command action.
String commandActionLabel(CommandAction action) {
  switch (action) {
    case CommandAction.repeat:
      return 'Repeat last instruction';
    case CommandAction.next:
      return 'Next instruction';
    case CommandAction.settings:
      return 'Open settings';
    case CommandAction.stop:
      return 'Stop speaking';
  }
}

/// Voice Command (voice_command_wireframe.png).
///
/// While this screen is open the phone listens for "wake phrase +
/// command", e.g. "hey navassist, repeat". Shows the listening state and
/// the last words heard. Press-and-hold works without the wake phrase.
/// Also: wake phrase settings and custom commands (add, edit, on/off,
/// delete).
class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({super.key});

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  late final CommandService _commands;
  late final VoiceRepository _repository;
  late final Stream<List<CustomCommand>> _customCommands;
  late final TextEditingController _wakeController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<VoiceSettingsProvider>();
    _commands = context.read<CommandService>();
    _repository = provider.repository;
    _customCommands = _repository.watchCustomCommands();
    _wakeController = TextEditingController(text: provider.settings.wakePhrase);
    _startListening();
  }

  @override
  void dispose() {
    _commands.stopListening(); // only listen while this screen is open
    _wakeController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (await _commands.ensureReady()) await _commands.startListening();
  }

  Future<void> _toggleListening() async {
    if (_commands.isListening) {
      await _commands.stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _longPress() async {
    final settings = context.read<VoiceSettingsProvider>().settings;
    if (!settings.longPressFallback) {
      showMessage(context, 'Press-and-hold listening is turned off below.');
      return;
    }
    if (!await _commands.ensureReady()) return;
    await _commands.listenFromLongPress();
  }

  void _saveWakePhrase() {
    final provider = context.read<VoiceSettingsProvider>();
    final phrase = CommandService.normalise(_wakeController.text);
    if (phrase.isEmpty) {
      showMessage(context, 'Please enter a wake phrase.');
      return;
    }
    _wakeController.text = phrase;
    provider.updateSettings(provider.settings.copyWith(wakePhrase: phrase));
    FocusScope.of(context).unfocus();
    showMessage(context, 'Wake phrase saved: "$phrase".');
  }

  // Runs a Firestore change, reloads the commands used for matching,
  // and shows any error as a message.
  Future<void> _change(Future<void> Function() action) async {
    try {
      await action();
      await _commands.reloadCustomCommands();
    } on VoiceDataException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _addOrEdit([CustomCommand? existing]) async {
    final result = await showDialog<_CommandDraft>(
      context: context,
      useRootNavigator: false,
      builder: (_) => _CommandDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _change(
        () => _repository.addCustomCommand(result.phrase, result.action),
      );
    } else {
      await _change(
        () => _repository.updateCustomCommand(
          existing.copyWith(phrase: result.phrase, action: result.action),
        ),
      );
    }
  }

  Future<void> _delete(CustomCommand command) async {
    final ok = await confirmAction(
      context,
      title: 'Delete command?',
      message: 'Delete the command "${command.phrase}"?',
      confirmLabel: 'Delete',
    );
    if (ok) await _change(() => _repository.deleteCustomCommand(command.id));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.watch<CommandService>();
    final provider = context.watch<VoiceSettingsProvider>();
    final s = provider.settings;

    final String status;
    if (!c.isAvailable) {
      status = 'Voice commands unavailable';
    } else if (!c.isListening) {
      status = 'Not listening';
    } else if (c.needsWakePhrase) {
      status = 'Listening for "${s.wakePhrase}"';
    } else {
      status = 'Listening for a command';
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const VoiceHeader(title: 'Voice Command'),
            const SizedBox(height: 8),
            // Listening status (text + icon, not colour only).
            Center(
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: p.text,
                      width: p.borderWidth == 0 ? 1 : 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.isListening ? Icons.hearing : Icons.hearing_disabled,
                        size: 20,
                        color: c.isListening ? p.success : p.mutedText,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(status, style: TextStyle(color: p.text)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _MicIndicator(
                listening: c.isListening,
                onTap: _toggleListening,
              ),
            ),
            if (c.errorMessage != null)
              NoteText(c.errorMessage!, icon: Icons.error_outline),
            const SizedBox(height: 16),
            InfoCard(
              color: p.background,
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Text(
                      'LAST HEARD COMMAND',
                      style: TextStyle(
                        color: p.mutedText,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.lastHeard.isEmpty
                          ? 'Nothing heard yet'
                          : '"${c.lastHeard}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (c.lastAction != null)
                      Text(
                        'Recognised: ${commandActionLabel(c.lastAction!)}',
                        style: TextStyle(color: p.mutedText),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LongPressArea(
              enabled: s.longPressFallback,
              onLongPress: _longPress,
            ),
            const SizedBox(height: 8),
            Text(
              'Built-in commands: repeat, next, settings, stop.',
              style: TextStyle(color: p.mutedText),
            ),
            const SectionTitle('Wake phrase'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Require wake phrase'),
              subtitle: const Text('Commands must start with the wake phrase'),
              value: s.wakeWordEnabled,
              onChanged: (v) =>
                  provider.updateSettings(s.copyWith(wakeWordEnabled: v)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wakeController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveWakePhrase(),
              decoration: const InputDecoration(
                labelText: 'Wake phrase',
                helperText: 'Capitals and spaces do not matter.',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saveWakePhrase,
                child: const Text('Save wake phrase'),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Press-and-hold fallback'),
              subtitle: const Text(
                'After a long press, listen once without the wake phrase',
              ),
              value: s.longPressFallback,
              onChanged: (v) =>
                  provider.updateSettings(s.copyWith(longPressFallback: v)),
            ),
            SectionTitle(
              'Custom commands',
              trailing: TextButton.icon(
                onPressed: () => _addOrEdit(),
                icon: const Icon(Icons.add),
                label: const Text('Add', semanticsLabel: 'Add custom command'),
              ),
            ),
            StreamList<CustomCommand>(
              stream: _customCommands,
              emptyText: 'No custom commands yet. Add one, for example "say again" for Repeat.',
              itemBuilder: (context, command) => _CommandTile(
                command: command,
                onToggle: (v) => _change(
                  () => _repository.updateCustomCommand(
                    command.copyWith(enabled: v),
                  ),
                ),
                onEdit: () => _addOrEdit(command),
                onDelete: () => _delete(command),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The round microphone. It pulses while listening (unless Reduce motion
/// is on). Tap to start or stop listening.
class _MicIndicator extends StatefulWidget {
  const _MicIndicator({required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback onTap;

  @override
  State<_MicIndicator> createState() => _MicIndicatorState();
}

class _MicIndicatorState extends State<_MicIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Starts or stops the pulse to match the current state.
  void _syncPulse() {
    final animate =
        widget.listening && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse(); // Reduce motion may have changed
  }

  @override
  void didUpdateWidget(_MicIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse(); // listening may have changed
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: widget.listening ? 'Stop listening' : 'Start listening',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.15).animate(_pulse),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.primary, width: 2),
                  ),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.listening ? p.primary : p.switchOff,
                ),
                child: Icon(
                  widget.listening ? Icons.mic : Icons.mic_off,
                  size: 40,
                  color: widget.listening ? p.onPrimary : p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big area to press and hold (TalkBack: double-tap and hold).
class _LongPressArea extends StatelessWidget {
  const _LongPressArea({required this.enabled, required this.onLongPress});

  final bool enabled;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = enabled
        ? 'Press and hold here to give a command without the wake phrase'
        : 'Press-and-hold fallback is off';
    return Semantics(
      button: true,
      enabled: enabled,
      label: text,
      onLongPressHint: 'listen for one command',
      excludeSemantics: true,
      onLongPress: onLongPress,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: InfoCard(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: enabled ? p.primary : p.mutedText,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: enabled ? p.text : p.mutedText,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One custom command: phrase, action, on/off switch, edit and delete.
class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.command,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomCommand command;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${command.phrase}"',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${commandActionLabel(command.action)}'
                      '${command.enabled ? '' : ' (off)'}',
                      style: TextStyle(color: p.mutedText),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Command "${command.phrase}" on',
                child: Switch(value: command.enabled, onChanged: onToggle),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                tooltip: 'Edit "${command.phrase}"',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: p.danger),
                tooltip: 'Delete "${command.phrase}"',
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// What the add / edit dialog returns.
class _CommandDraft {
  const _CommandDraft(this.phrase, this.action);

  final String phrase;
  final CommandAction action;
}

/// Dialog to add a new command or edit an existing one.
class _CommandDialog extends StatefulWidget {
  const _CommandDialog({this.existing});

  final CustomCommand? existing; // null = add a new command

  @override
  State<_CommandDialog> createState() => _CommandDialogState();
}

class _CommandDialogState extends State<_CommandDialog> {
  late final TextEditingController _phrase = TextEditingController(
    text: widget.existing?.phrase ?? '',
  );
  late CommandAction _action = widget.existing?.action ?? CommandAction.repeat;
  String? _error;

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  void _save() {
    final phrase = CommandService.normalise(_phrase.text);
    if (phrase.isEmpty) {
      setState(() => _error = 'Please enter a phrase.');
      return;
    }
    Navigator.pop(context, _CommandDraft(phrase, _action));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add command' : 'Edit command'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phrase,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Phrase, e.g. "say again"',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CommandAction>(
              initialValue: _action,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Action'),
              items: [
                for (final a in CommandAction.values)
                  DropdownMenuItem(
                    value: a,
                    child: Text(commandActionLabel(a)),
                  ),
              ],
              onChanged: (a) => setState(() => _action = a ?? _action),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
