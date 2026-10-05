# Member 2 – Traceability (Voice Guidance & Accessibility)

Requirement → design → code → tests. Only UR-01 to UR-04 are used (the old FR/NFR IDs in the wireframes are not used).
Test case IDs are in `docs/member2/TEST_CASES.md`. All file paths are under `lib/screens/voice/` unless the row says otherwise.

| Requirement | Meaning |
|---|---|
| **UR-01** | Clear voice-guided directions |
| **UR-02** | Obstacle detection alerts |
| **UR-03** | Vibration-based alerts |
| **UR-04** | Screen-reader / accessibility support |

## UR-01 – Clear voice-guided directions

| Hi-fi / wireframe | Screen | Implementation files | Automated tests | Manual tests |
|---|---|---|---|---|
| `active_navigation.png` | Active Navigation | `active_navigation_screen.dart`, `services/navigation_session.dart`, `services/voice_service.dart`, `data/nav_step.dart`, `data/demo_route.dart`, `widgets/route_map.dart` | TC-M2-04, TC-M2-23 – TC-M2-31, TC-M2-33 | TC-M2-67, TC-M2-68, TC-M2-81 |
| `voice_guidance.png` | Voice Guidance | `voice_guidance_screen.dart`, `services/voice_service.dart`, `data/voice_settings.dart`, `data/instruction_history_entry.dart`, `data/voice_repository.dart` | TC-M2-35, TC-M2-40 – TC-M2-42, TC-M2-44, TC-M2-49 – TC-M2-52 | TC-M2-72, TC-M2-82 |
| `voice_command_wireframe.png` | Voice Command | `voice_command_screen.dart`, `services/command_service.dart`, `data/custom_command.dart`, `data/voice_repository.dart` | TC-M2-10 – TC-M2-22, TC-M2-34, TC-M2-53 – TC-M2-58 | TC-M2-74, TC-M2-75 |
| `instruction_feedback_wireframe.png` | Navigation Instruction Feedback | `instruction_feedback_screen.dart`, `data/instruction_feedback.dart`, `data/voice_repository.dart` | TC-M2-37, TC-M2-62 – TC-M2-65 | TC-M2-79 |

## UR-02 – Obstacle detection alerts

| Hi-fi / wireframe | Screen | Implementation files | Automated tests | Manual tests |
|---|---|---|---|---|
| `alert_popup_wireframe.png` | Audio/Haptic Alert – high severity (pop-up) | `widgets/alert_overlay.dart` (`_HighAlert`), `services/alert_service.dart`, `data/alert_log_entry.dart`, `voice_shell.dart` (shows the overlay over every screen) | TC-M2-06, TC-M2-07, TC-M2-59, TC-M2-60 | TC-M2-71 |
| `alert_banner_wireframe.png` | Audio/Haptic Alert – low severity (banner) | `widgets/alert_overlay.dart` (`_LowAlertBanner`), `services/alert_service.dart` | – (no automated test for the banner yet) | TC-M2-70 |
| `haptic_alerts.png` (alert log section added) | Haptic Alerts | `haptic_alerts_screen.dart`, `data/voice_repository.dart` | TC-M2-36, TC-M2-61 | TC-M2-70, TC-M2-71 |
| `active_navigation.png` | Active Navigation (demo steps 2 and 4 fire the alerts) | `data/demo_route.dart`, `services/navigation_session.dart` | – | TC-M2-70, TC-M2-71 |

## UR-03 – Vibration-based alerts

| Hi-fi / wireframe | Screen | Implementation files | Automated tests | Manual tests |
|---|---|---|---|---|
| `haptic_alerts.png` | Haptic Alerts | `haptic_alerts_screen.dart`, `services/haptic_service.dart`, `data/haptic_cue.dart`, `data/voice_settings.dart` (`hapticEnabled`, `hapticIntensity`) | TC-M2-40 – TC-M2-42 | TC-M2-73 |
| `alert_popup_wireframe.png`, `alert_banner_wireframe.png` | Audio/Haptic Alert pop-ups | `services/alert_service.dart`, `services/haptic_service.dart` (high: strong repeating; low: one pulse) | TC-M2-06 (vibration stopped on Dismiss) | TC-M2-70, TC-M2-71 |
| `active_navigation.png` | Active Navigation (cue per step, Vibration on/off toggle) | `services/navigation_session.dart`, `data/nav_step.dart` (`guessCue`), `active_navigation_screen.dart` (`_QuickToggles`) | TC-M2-23, TC-M2-31, TC-M2-32 | TC-M2-69 |
| `instruction_feedback_wireframe.png` | Instruction Feedback (short pulse instead of the chime) | `instruction_feedback_screen.dart` | – | TC-M2-79 |

## UR-04 – Screen-reader / accessibility support

| Hi-fi / wireframe | Screen | Implementation files | Automated tests | Manual tests |
|---|---|---|---|---|
| `accessibility_settings.png` | Accessibility Settings | `accessibility_settings_screen.dart`, `data/voice_settings.dart`, `data/voice_settings_provider.dart`, `data/voice_repository.dart` | TC-M2-01 – TC-M2-03, TC-M2-38 – TC-M2-47, TC-M2-66 | TC-M2-48, TC-M2-77, TC-M2-80 |
| all hi-fi screens | All Member 2 screens (Large text, High contrast, Reduce motion, TalkBack labels, live regions, 48 × 48 targets) | `voice_shell.dart` (`VoiceAccessibilityScope`), `theme/voice_theme.dart`, `widgets/voice_widgets.dart` | TC-M2-05 (2× text), TC-M2-08, TC-M2-09 (Back), TC-M2-07 (Back on an alert) | TC-M2-76 (TalkBack, Redmi 9, 3 Oct 2026: Pass), TC-M2-77 |
| `voice_command_wireframe.png` | Voice Command (hands-free use, press-and-hold fallback) | `voice_command_screen.dart`, `services/command_service.dart` | TC-M2-10 – TC-M2-22, TC-M2-34, TC-M2-53 – TC-M2-58 | TC-M2-74, TC-M2-75, TC-M2-82 |

## Defects and the tests that cover them

| Defect (`DEFECTS.md`) | Covered by |
|---|---|
| D-01 Active Navigation layout error | TC-M2-04, TC-M2-05 (automated); TC-M2-81 (phone retest) |
| D-02 Stream listened to twice | TC-M2-34 – TC-M2-37 (automated); TC-M2-82 (phone retest) |
