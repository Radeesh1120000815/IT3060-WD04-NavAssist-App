import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/haptic_cue.dart';
import '../theme/voice_theme.dart';

// Small building blocks used by all Member 2 screens.

/// Returns [normal], or zero when "Reduce motion" (or the phone's own
/// "remove animations" setting) is on.
Duration motion(BuildContext context, Duration normal) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;

/// "14:05" for today, "3/10 14:05" for other days, "—" while the server
/// time is still missing.
String formatTime(DateTime? time) {
  if (time == null) return '—';
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = '${two(time.hour)}:${two(time.minute)}';
  final isToday =
      time.year == now.year && time.month == now.month && time.day == now.day;
  return isToday ? clock : '${time.day}/${time.month} $clock';
}

/// The arrow / icon shown for a navigation cue.
IconData iconForCue(HapticCue cue) {
  switch (cue) {
    case HapticCue.turnLeft:
      return Icons.turn_left;
    case HapticCue.turnRight:
      return Icons.turn_right;
    case HapticCue.straight:
      return Icons.arrow_upward;
    case HapticCue.obstacle:
      return Icons.warning_amber_rounded;
    case HapticCue.crossing:
      return Icons.directions_walk;
    case HapticCue.arrival:
      return Icons.flag;
  }
}

/// Shows a short message at the bottom of the screen.
void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Asks the user to confirm. Returns true only if they press [confirmLabel].
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    // Keeps the dialog inside our theme (large text / high contrast).
    useRootNavigator: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// "< Back" link, big screen title and a divider, as in the hi-fi.
class VoiceHeader extends StatelessWidget {
  const VoiceHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (context.canPop())
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: p.mutedText,
              padding: const EdgeInsets.only(right: 12),
            ),
          ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: text.bodyLarge?.copyWith(color: p.mutedText),
            ),
          ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}

/// A bold section heading such as "Announce". Read as a heading by TalkBack.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing; // e.g. a "Clear" button

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700, color: context.palette.text);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(text, style: style)),
          ),
          ?trailing, // "?" = only added when trailing is not null
        ],
      ),
    );
  }
}

/// A row of boxes where exactly one is selected, e.g. 0.75x / 1x / 1.25x.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.semanticLabelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf; // shown text
  final String Function(T option) semanticLabelOf; // read by TalkBack
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _choiceBox(context, options[i])),
        ],
      ],
    );
  }

  Widget _choiceBox(BuildContext context, T option) {
    final p = context.palette;
    final isSelected = option == selected;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: isSelected
            ? p.primary
            : (p.borderWidth == 0 ? p.divider : p.text),
        width: p.borderWidth == 0 ? 1 : p.borderWidth,
      ),
    );

    // Selected = filled AND bold text, so it is not shown by colour only.
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: semanticLabelOf(option),
      excludeSemantics: true,
      onTap: () => onSelected(option),
      child: Material(
        color: isSelected ? p.primary : p.background,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => onSelected(option),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Text(
                  labelOf(option),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? p.onPrimary : p.text,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The wide light-blue button used for "Test voice announcement".
class TonalButton extends StatelessWidget {
  const TonalButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: p.tile,
          foregroundColor: p.primary,
          minimumSize: const Size(48, 56),
          side: p.borderWidth == 0
              ? null
              : BorderSide(color: p.text, width: p.borderWidth),
        ),
      ),
    );
  }
}

/// A light rounded card (outlined in high contrast mode).
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? p.tile,
        borderRadius: BorderRadius.circular(14),
        border: p.border,
      ),
      child: child,
    );
  }
}

/// Small grey text for "Loading…", "No items yet" or an error.
class NoteText extends StatelessWidget {
  const NoteText(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: p.mutedText),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(text, style: TextStyle(color: p.mutedText)),
          ),
        ],
      ),
    );
  }
}

/// Shows a live Firestore list with loading, error and empty messages.
/// The parent must create [stream] once (in initState), not in build.
class StreamList<T> extends StatelessWidget {
  const StreamList({
    super.key,
    required this.stream,
    required this.emptyText,
    required this.itemBuilder,
    this.maxItems,
  });

  final Stream<List<T>> stream;
  final String emptyText;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NoteText('${snapshot.error}', icon: Icons.error_outline);
        }
        if (!snapshot.hasData) return const NoteText('Loading…');

        var items = snapshot.data!;
        if (maxItems != null) items = items.take(maxItems!).toList();
        if (items.isEmpty) return NoteText(emptyText);
        return Column(
          children: [for (final item in items) itemBuilder(context, item)],
        );
      },
    );
  }
}

/// Draws a vibration pattern as dots (short) and dashes (long), like the
/// hi-fi. Hidden from TalkBack because the text next to it says the same.
class PatternGlyph extends StatelessWidget {
  const PatternGlyph(this.cue, {super.key});

  final HapticCue cue;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.primary;
    final strong = cue.alwaysStrong;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final buzz in cue.buzzes)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: buzz >= 400 ? 18 : (strong ? 10 : 6),
              height: strong ? 10 : 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
        ],
      ),
    );
  }
}

/// PLACEHOLDER for the shared bottom tab bar (Home, Active Nav, Nearby,
/// Hazards, SOS). It belongs to the shared layout, which does not exist
/// yet. Delete this when the real tab bar is added.
class TabBarPlaceholder extends StatelessWidget {
  const TabBarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: p.background,
          border: Border(top: BorderSide(color: p.divider)),
        ),
        child: Text(
          'Tab bar placeholder (shared layout)',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.mutedText, fontSize: 13),
        ),
      ),
    );
  }
}
