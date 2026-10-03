import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/nav_step.dart';
import 'data/voice_settings.dart';
import 'data/voice_settings_provider.dart';
import 'services/command_service.dart';
import 'services/haptic_service.dart';
import 'services/navigation_session.dart';
import 'services/voice_service.dart';
import 'theme/voice_theme.dart';
import 'voice_routes.dart';
import 'widgets/route_map.dart';
import 'widgets/voice_widgets.dart';

/// Active Navigation (active_navigation.png).
///
/// Shows the current instruction, the next step, a drawn route map, the
/// destination with time and distance left, and quick buttons to the
/// voice, haptic and accessibility screens.
/// Speaks each instruction (UR-01) and vibrates its cue (UR-03).
/// Press and hold the map to give a voice command without the wake phrase.
class ActiveNavigationScreen extends StatefulWidget {
  const ActiveNavigationScreen({super.key, this.routeExtra});

  /// The route from Member 1's Start Navigation screen (GoRouter `extra`).
  /// Null or unusable = the demo route is used.
  final Object? routeExtra;

  @override
  State<ActiveNavigationScreen> createState() => _ActiveNavigationScreenState();
}

class _ActiveNavigationScreenState extends State<ActiveNavigationScreen> {
  @override
  void initState() {
    super.initState();
    final session = context.read<NavigationSession>();
    final route = NavRoute.fromExtra(widget.routeExtra);
    // After the first frame: load Member 1's route (if any) and speak
    // the first instruction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route != null) session.loadRoute(route);
      session.start();
    });
  }

  // Long-press fallback: listen once without the wake phrase.
  Future<void> _listenFromLongPress() async {
    final commands = context.read<CommandService>();
    final settings = context.read<VoiceSettingsProvider>().settings;
    if (!settings.longPressFallback) {
      showMessage(
        context,
        'Press-and-hold listening is off. Turn it on in Voice Command.',
      );
      return;
    }
    final ready = await commands.ensureReady();
    if (!mounted) return;
    if (!ready) {
      showMessage(
        context,
        commands.errorMessage ?? 'Voice commands are not available.',
      );
      return;
    }
    showMessage(context, 'Listening. Say a command, for example "repeat".');
    await commands.listenFromLongPress();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final session = context.watch<NavigationSession>();
    final mapHeight = (MediaQuery.sizeOf(context).height * 0.32).clamp(
      180.0,
      360.0,
    );

    return Scaffold(
      backgroundColor: p.navBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                const _TopBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _InstructionCard(
                    step: session.currentStep,
                    stepIndex: session.stepIndex,
                  ),
                ),
                if (session.nextStep != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _NextStepRow(step: session.nextStep!),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: mapHeight,
                  child: _MapArea(
                    progress: session.progress,
                    onLongPress: _listenFromLongPress,
                  ),
                ),
              ]),
            ),
            // The white panel fills the rest of the screen.
            SliverFillRemaining(
              hasScrollBody: false,
              child: _BottomPanel(session: session),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back button, "NAVIGATING" title and the SOS placeholder.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: Row(
        children: [
          if (context.canPop())
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.chevron_left, color: p.onNav),
              tooltip: 'Back',
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'NAVIGATING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: p.onNavMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          // PLACEHOLDER: the real SOS button belongs to Member 3.
          FilledButton(
            onPressed: () => showMessage(
              context,
              'SOS belongs to the Safety section and is not connected yet.',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: p.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 48),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'SOS',
              semanticsLabel: 'SOS emergency help, not connected yet',
            ),
          ),
        ],
      ),
    );
  }
}

/// The big card with the direction arrow and a Repeat button.
class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.step, required this.stepIndex});

  final NavStep step;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final screenReader = context
        .watch<VoiceSettingsProvider>()
        .settings
        .screenReaderSupport;
    final subtitle = [
      if (step.street.isNotEmpty) step.street,
      if (step.distanceMetres > 0) '${step.distanceMetres} m',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        color: p.navCard,
        borderRadius: BorderRadius.circular(14),
        border: p.navBorder,
      ),
      child: Row(
        children: [
          Expanded(
            // Live region: TalkBack reads the new instruction by itself.
            child: Semantics(
              liveRegion: screenReader,
              label: 'Current instruction: ${step.spokenText}',
              excludeSemantics: true,
              child: AnimatedSwitcher(
                duration: motion(context, const Duration(milliseconds: 250)),
                child: Row(
                  key: ValueKey(stepIndex),
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: p.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconForCue(step.cue),
                        color: p.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.action,
                            style: TextStyle(
                              color: p.onNav,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: p.onNavMuted,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.read<NavigationSession>().repeat(),
            icon: Icon(Icons.replay, color: p.onNav),
            tooltip: 'Repeat instruction',
          ),
        ],
      ),
    );
  }
}

/// "Then turn right onto King Street".
class _NextStepRow extends StatelessWidget {
  const _NextStepRow({required this.step});

  final NavStep step;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final action = step.displayText;
    final text = 'Then ${action[0].toLowerCase()}${action.substring(1)}';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: p.navCard,
            borderRadius: BorderRadius.circular(8),
            border: p.navBorder,
          ),
          child: Icon(iconForCue(step.cue), color: p.onNav, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: p.onNavMuted, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

/// The drawn map. Press and hold it to give a voice command.
class _MapArea extends StatelessWidget {
  const _MapArea({required this.progress, required this.onLongPress});

  final double progress;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Route map',
      onLongPressHint: 'speak a voice command',
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Stack(
          children: [
            RouteMap(progress: progress),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: ExcludeSemantics(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.navCard,
                      borderRadius: BorderRadius.circular(20),
                      border: p.navBorder,
                    ),
                    child: Text(
                      'Press and hold the map to speak a command',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.onNav, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White panel: destination, time left, quick buttons and extra actions.
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.session});

  final NavigationSession session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DestinationRow(session: session),
          const SizedBox(height: 16),
          const _QuickToggles(),
          const SizedBox(height: 10),
          const _QuickButtons(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: session.isArrived ? session.restart : session.next,
                icon: Icon(
                  session.isArrived ? Icons.restart_alt : Icons.skip_next,
                ),
                label: Text(session.isArrived ? 'Start again' : 'Next step'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(VoiceRoutes.voiceCommand),
                icon: const Icon(Icons.keyboard_voice),
                label: const Text('Voice commands'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(VoiceRoutes.instructionFeedback),
                icon: const Icon(Icons.thumbs_up_down),
                label: const Text('Feedback'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Central Library — Arriving in ~9 min · 600 m remaining" and "9 min".
class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.session});

  final NavigationSession session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final minutes = session.minutesRemaining;
    final metres = session.remainingMetres;

    final String shown;
    final String spoken;
    if (session.isArrived) {
      shown = 'You have arrived';
      spoken = 'You have arrived at ${session.destination}.';
    } else if (session.hasDistances) {
      shown = 'Arriving in ~$minutes min · $metres m remaining';
      spoken =
          '${session.destination}. Arriving in about $minutes minutes, '
          '$metres metres remaining.';
    } else {
      final step = 'Step ${session.stepIndex + 1} of ${session.steps.length}';
      shown = step;
      spoken = '${session.destination}. $step.';
    }

    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.destination,
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                Text(
                  shown,
                  style: text.bodyLarge?.copyWith(color: p.mutedText),
                ),
              ],
            ),
          ),
          if (session.hasDistances && !session.isArrived)
            Column(
              children: [
                Text(
                  '$minutes',
                  style: text.headlineMedium?.copyWith(
                    color: p.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('min', style: TextStyle(color: p.mutedText)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Two quick switches: Voice on/off and Vibration on/off.
/// READ: the values come from settings/{uid} (VoiceSettingsProvider).
/// UPDATE: a tap saves the new value to settings/{uid}.
class _QuickToggles extends StatelessWidget {
  const _QuickToggles();

  // Saves the change and shows a message if it could not be saved.
  Future<void> _save(BuildContext context, VoiceSettings changed) async {
    final provider = context.read<VoiceSettingsProvider>();
    await provider.updateSettings(changed);
    if (provider.errorMessage != null && context.mounted) {
      showMessage(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<VoiceSettingsProvider>().settings;
    return Row(
      children: [
        Expanded(
          child: _QuickToggle(
            name: 'Voice',
            value: s.voiceEnabled,
            onIcon: Icons.volume_up,
            offIcon: Icons.volume_off,
            onChanged: (v) {
              if (!v) context.read<VoiceService>().stop(); // silence now
              _save(context, s.copyWith(voiceEnabled: v));
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickToggle(
            name: 'Vibration',
            value: s.hapticEnabled,
            onIcon: Icons.vibration,
            offIcon: Icons.mobile_off,
            onChanged: (v) {
              if (!v) context.read<HapticService>().stop(); // stop buzzing now
              _save(context, s.copyWith(hapticEnabled: v));
            },
          ),
        ),
      ],
    );
  }
}

/// One on/off tile. On = filled blue; Off = outlined. The icon and the
/// words "On" / "Off" also change, so the state is not shown by colour only.
class _QuickToggle extends StatelessWidget {
  const _QuickToggle({
    required this.name,
    required this.value,
    required this.onIcon,
    required this.offIcon,
    required this.onChanged,
  });

  final String name; // "Voice" or "Vibration"
  final bool value;
  final IconData onIcon;
  final IconData offIcon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = value ? 'On' : 'Off';
    final foreground = value ? p.onPrimary : p.text;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: value ? p.primary : (p.borderWidth == 0 ? p.divider : p.text),
        width: p.borderWidth == 0 ? 1 : p.borderWidth,
      ),
    );

    // TalkBack reads e.g. "Voice on, switch. Double tap to turn off".
    return Semantics(
      toggled: value,
      label: '$name ${state.toLowerCase()}',
      onTapHint: value ? 'turn off' : 'turn on',
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: Material(
        color: value ? p.primary : p.background,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(value ? onIcon : offIcon, color: foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$name: $state',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The four quick buttons: Voice, Haptic, Nearby, Settings.
class _QuickButtons extends StatelessWidget {
  const _QuickButtons();

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _QuickButton(
        icon: Icons.mic,
        label: 'Voice',
        semanticLabel: 'Voice guidance settings',
        onTap: () => context.push(VoiceRoutes.voiceGuidance),
      ),
      _QuickButton(
        icon: Icons.vibration,
        label: 'Haptic',
        semanticLabel: 'Haptic alerts',
        onTap: () => context.push(VoiceRoutes.hapticAlerts),
      ),
      // PLACEHOLDER: Nearby (Surroundings) belongs to Member 3.
      _QuickButton(
        icon: Icons.visibility,
        label: 'Nearby',
        semanticLabel: 'Nearby, not connected yet',
        onTap: () => showMessage(
          context,
          'Nearby belongs to the Safety section and is not connected yet.',
        ),
      ),
      _QuickButton(
        icon: Icons.settings,
        label: 'Settings',
        semanticLabel: 'Accessibility settings',
        onTap: () => context.push(VoiceRoutes.accessibility),
      ),
    ];

    // Four in a row; two per row when the text is very large.
    final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 2 : 4;
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final b in buttons) SizedBox(width: width, child: b)],
        );
      },
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: p.borderWidth == 0
          ? BorderSide.none
          : BorderSide(color: p.text, width: p.borderWidth),
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: p.tile,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: p.primary),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
