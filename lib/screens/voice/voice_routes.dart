import 'package:go_router/go_router.dart';

import 'accessibility_settings_screen.dart';
import 'active_navigation_screen.dart';
import 'haptic_alerts_screen.dart';
import 'instruction_feedback_screen.dart';
import 'voice_command_screen.dart';
import 'voice_guidance_screen.dart';
import 'voice_shell.dart';

/// Route paths for Member 2's screens.
class VoiceRoutes {
  VoiceRoutes._();

  /// Active Navigation. Member 1's Start Navigation screen opens this,
  /// optionally passing the route in `extra`
  /// (see docs/member2/MEMBER1_HANDOVER_NOTE.txt).
  static const String activeNavigation = '/navigate';
  static const String voiceGuidance = '/voice/guidance';
  static const String hapticAlerts = '/voice/haptics';
  static const String voiceCommand = '/voice/commands';
  static const String accessibility = '/voice/accessibility';
  static const String instructionFeedback = '/voice/feedback';
}

/// All Member 2 routes, for the shared router to import:
///
///   routes: [ ...otherRoutes, ...voiceRoutes ]
///
/// They sit inside one ShellRoute so all my screens share the same
/// settings and services, and alert pop-ups can appear over any of them.
/// The Audio/Haptic Alert screens are pop-ups (AlertOverlay), not routes.
final List<RouteBase> voiceRoutes = [
  ShellRoute(
    builder: (context, state, child) => VoiceShell(child: child),
    routes: [
      GoRoute(
        path: VoiceRoutes.activeNavigation,
        builder: (context, state) =>
            ActiveNavigationScreen(routeExtra: state.extra),
      ),
      GoRoute(
        path: VoiceRoutes.voiceGuidance,
        builder: (context, state) => const VoiceGuidanceScreen(),
      ),
      GoRoute(
        path: VoiceRoutes.hapticAlerts,
        builder: (context, state) => const HapticAlertsScreen(),
      ),
      GoRoute(
        path: VoiceRoutes.voiceCommand,
        builder: (context, state) => const VoiceCommandScreen(),
      ),
      GoRoute(
        path: VoiceRoutes.accessibility,
        builder: (context, state) => const AccessibilitySettingsScreen(),
      ),
      GoRoute(
        path: VoiceRoutes.instructionFeedback,
        builder: (context, state) => const InstructionFeedbackScreen(),
      ),
    ],
  ),
];
