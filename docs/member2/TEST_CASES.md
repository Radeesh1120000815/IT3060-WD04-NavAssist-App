# Member 2 – Test Cases (Voice Guidance & Accessibility)

Requirements used: **UR-01** clear voice-guided directions, **UR-02** obstacle detection alerts, **UR-03** vibration-based alerts, **UR-04** screen-reader / accessibility support.

## How these were run

- **Automated tests:** `flutter test test/voice --concurrency=1 -r expanded`, run on **2026-10-03** (Flutter 3.47.5, Dart 3.13.4, Windows host).
  Final line of the real output: `00:21 +65 ~1: All tests passed!`, meaning **65 passed, 1 skipped, 0 failed**.
  The skipped test, TC-M2-48, was checked manually on the Redmi 9 on 3 October 2026 and passed.
- `flutter analyze lib/screens/voice test/voice`: "No issues found!" (same day).
- **Actual result / Pass/Fail** are filled **only** for automated tests that really ran and passed in that run, plus manual tests I did on my Redmi 9 on 3 October 2026.
- **MANUAL** rows must be done by hand on the phone (Redmi 9, Android 12). All 16 MANUAL rows were done on my Redmi 9 on 3 October 2026, and all passed.
- The repository tests use `fake_cloud_firestore` (an in-memory Firestore) and a fake signed-in user, so no real data is touched.
- In widget tests, the vibration and text-to-speech plugins are answered by `test/voice/fake_plugins.dart`. There is no phone in a test, so these tests check *what the app asks for*, not what is felt or heard. Feeling and hearing are covered by the MANUAL rows.

CRUD column: **C** create, **R** read, **U** update, **D** delete, **–** no database operation.

## Automated tests

### Accessibility Settings (`test/voice/accessibility_settings_test.dart`)

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-01 | UR-04 | Accessibility Settings | U | Open the screen with default settings. Tap "Large text". | The switch turns on, the setting is on straight away, and an update with `largeText: true` is sent to the repository. | As expected | Pass |
| TC-M2-02 | UR-04 | Accessibility Settings | – | Turn on High contrast and Large text. Tap "Reset to default", then "Cancel" in the dialog. | The dialog "Reset to default?" is shown. After Cancel it closes, no reset is sent, and High contrast is still on. | As expected | Pass |
| TC-M2-03 | UR-04 | Accessibility Settings | D + C | As TC-M2-02, but press "Reset" in the dialog. | One reset is sent. High contrast and Large text are off again, and "All settings are back to default." is shown. | As expected | Pass |

### Active Navigation layout (`test/voice/active_navigation_layout_test.dart`), covers defect D-01

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-04 | UR-01 | Active Navigation | – | Open Active Navigation at Redmi 9 size (393 × 851) with normal text. | No layout error. "Central Library", "Head north" and the "Settings" quick button are shown. | As expected | Pass |
| TC-M2-05 | UR-04 | Active Navigation | – | Same, with text size 2×. Scroll down to the bottom panel. | No layout error before or after scrolling. The destination and quick buttons are shown. | As expected | Pass |

### Audio/Haptic Alert, high severity (`test/voice/alert_overlay_test.dart`)

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-06 | UR-02, UR-03 | Audio/Haptic Alert (high) | C + U | Fire a high "Obstacle ahead" alert. Tap "Dismiss alert". | "WARNING" and "OBSTACLE AHEAD" are shown full screen, the alert is logged (C), and the warning is spoken. After Dismiss the alert is gone, the screen underneath is visible, the alert is marked acknowledged (U), and vibration `cancel` and voice `stop` are sent. | As expected | Pass |
| TC-M2-07 | UR-02, UR-04 | Audio/Haptic Alert (high) | U | Fire a high alert. Press the phone's Back button. | Back works like Dismiss: the alert closes, the screen underneath stays, and the alert is marked acknowledged. | As expected | Pass |

### Back button (`test/voice/back_navigation_test.dart`)

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-08 | UR-04 | Accessibility Settings → Active Navigation | – | Open Accessibility directly (nothing underneath). Tap "< Back". | Active Navigation opens (fallback route `/navigate`). | As expected | Pass |
| TC-M2-09 | UR-04 | Accessibility Settings → Active Navigation | – | From Active Navigation, open Accessibility. Tap "< Back". | Returns to Active Navigation (normal pop). | As expected | Pass |

### Voice command matching (`test/voice/command_matching_test.dart`)

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-10 | UR-01, UR-04 | Voice Command | – | `normalise("  Hey,   NavAssist!  ")` | `"hey navassist"` | As expected | Pass |
| TC-M2-11 | UR-01, UR-04 | Voice Command | – | `removeWakePhrase("Hey NavAssist, open settings", "hey navassist")` | `"open settings"` | As expected | Pass |
| TC-M2-12 | UR-01, UR-04 | Voice Command | – | Remove the wake phrase from "HEY NAV ASSIST repeat" and "heynavassist repeat". | Both give `"repeat"` (capitals and spaces ignored). | As expected | Pass |
| TC-M2-13 | UR-01, UR-04 | Voice Command | – | Remove the wake phrase from "hello there repeat". | `null` (wake phrase not said). | As expected | Pass |
| TC-M2-14 | UR-01, UR-04 | Voice Command | – | Wake phrase on: match "Hey NavAssist, repeat", "hey nav assist next", "heynavassist settings", "Hey NavAssist stop". | repeat, next, settings, stop | As expected | Pass |
| TC-M2-15 | UR-01, UR-04 | Voice Command | – | Wake phrase on: match "repeat". | No command (wake phrase missing). | As expected | Pass |
| TC-M2-16 | UR-01, UR-04 | Voice Command | – | Wake phrase on: match "hey navassist" alone. | No command. | As expected | Pass |
| TC-M2-17 | UR-01, UR-04 | Voice Command | – | Wake phrase off: match "please repeat that". | repeat | As expected | Pass |
| TC-M2-18 | UR-01, UR-04 | Voice Command | – | Wake phrase off: match "nexus". | No command (whole words only). | As expected | Pass |
| TC-M2-19 | UR-01, UR-04 | Voice Command | – | Wake phrase off: match "" and "good morning". | No command. | As expected | Pass |
| TC-M2-20 | UR-01, UR-04 | Voice Command | – | Custom command "say again" → repeat. Match "hey navassist say again". | repeat | As expected | Pass |
| TC-M2-21 | UR-01, UR-04 | Voice Command | – | Custom command "stop talking" → repeat. Match "stop talking". | repeat (the custom phrase wins over the built-in "stop"). | As expected | Pass |
| TC-M2-22 | UR-01, UR-04 | Voice Command | – | Switched-off custom command "go on" → next. Match "go on". | No command. | As expected | Pass |

### Route from Member 1 and instruction text (`test/voice/nav_route_test.dart`)

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-23 | UR-01, UR-03 | Active Navigation | – | `NavRoute.fromExtra` with a destination and 3 instructions. | Destination "Central Library"; 3 steps in order; cues straight, turn right, arrival. | As expected | Pass |
| TC-M2-24 | UR-01 | Active Navigation | – | Destination "  City Park  ". | "City Park" | As expected | Pass |
| TC-M2-25 | UR-01 | Active Navigation | – | Destination missing, or only spaces. | "your destination" | As expected | Pass |
| TC-M2-26 | UR-01 | Active Navigation | – | Instructions `['Head north', '', '   ', 42, null, 'Turn left']`. | Only "Head north" and "Turn left" are kept. | As expected | Pass |
| TC-M2-27 | UR-01 | Active Navigation | – | `fromExtra(null)` | `null`, so the demo route is used. | As expected | Pass |
| TC-M2-28 | UR-01 | Active Navigation | – | extra is a String or a List, not a Map. | `null` | As expected | Pass |
| TC-M2-29 | UR-01 | Active Navigation | – | instructions missing, or a String instead of a List. | `null` | As expected | Pass |
| TC-M2-30 | UR-01 | Active Navigation | – | instructions empty, or with no usable text. | `null` | As expected | Pass |
| TC-M2-31 | UR-01, UR-03 | Active Navigation | – | `NavStep.fromText("  Turn left onto King Street.  ")` | Action "Turn left onto King Street", cue turn left. | As expected | Pass |
| TC-M2-32 | UR-03 | Active Navigation | – | `fromText` for "Turn right", "Cross the road", "Arrive at Central Library", "You reached your destination", "Head north". | Cues turn right, crossing, arrival, arrival, straight. | As expected | Pass |
| TC-M2-33 | UR-01 | Active Navigation | – | `fromText("Head north")` | No street, distance 0, spoken text "Head north." | As expected | Pass |

### Lists survive scrolling (`test/voice/stream_list_rebuild_test.dart`), covers defect D-02

Each test scrolls to the list, back to the top (so the list is thrown away), and down again.

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-34 | UR-01, UR-04 | Voice Command | R | Scroll the custom commands list away and back. | No "Bad state" error; "say again" is shown again. | As expected | Pass |
| TC-M2-35 | UR-01 | Voice Guidance | R | Scroll the instruction history away and back. | No error; the history item is shown again. | As expected | Pass |
| TC-M2-36 | UR-02 | Haptic Alerts | R | Scroll the alert log away and back. | No error; the alert is shown again. | As expected | Pass |
| TC-M2-37 | UR-01 | Instruction Feedback | R | Scroll recent feedback away and back. | No error; the feedback item is shown again. | As expected | Pass |

### Data layer: every CRUD method of `VoiceRepository` (`test/voice/voice_repository_test.dart`)

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-38 | UR-04 | All (user id) | – | `currentUserId()` with a user signed in. | Returns that user's id. | As expected | Pass |
| TC-M2-39 | UR-04 | All (user id) | – | `currentUserId()` with nobody signed in. | Signs in anonymously once, then returns the id. | As expected | Pass |
| TC-M2-40 | UR-01, UR-03, UR-04 | Accessibility / Voice Guidance / Haptic Alerts | C | `createDefaultSettings()` | `settings/{uid}` holds the defaults (voice on, volume 0.8, medium, "hey navassist") and both timestamps. | As expected | Pass |
| TC-M2-41 | UR-01, UR-03, UR-04 | Accessibility / Voice Guidance / Haptic Alerts | R + C | `getSettings()` when no document exists. | Default settings are returned and the document is created. | As expected | Pass |
| TC-M2-42 | UR-01, UR-03, UR-04 | Accessibility / Voice Guidance / Haptic Alerts | R | Save volume 0.3, speed 1.5, large text, strong. Call `getSettings()`. | The saved values; missing fields use the defaults. | As expected | Pass |
| TC-M2-43 | UR-04 | Accessibility / Voice Guidance / Haptic Alerts | R | Store bad values (volume 5, speed 3.0, "extreme", "yes", blank phrase). Call `getSettings()`. | Volume 1.0, speed 1.0, medium, voice on, "hey navassist". No crash. | As expected | Pass |
| TC-M2-44 | UR-01, UR-04 | Accessibility / Voice Guidance | U | `updateSettings(volume 0.5, high contrast, 1.25×)` | Values saved, `updatedAt` set. | As expected | Pass |
| TC-M2-45 | UR-04 | Accessibility | U | `updateSettings(reduceMotion: true)` before the document exists. | The document is created with `reduceMotion: true` (merge). | As expected | Pass |
| TC-M2-46 | UR-04 | All (shared settings) | R | `watchSettings()`, then update Large text. | First value off, then on. | As expected | Pass |
| TC-M2-47 | UR-04 | Accessibility | D + C | Change settings, then `resetToDefault()`. | Every setting is back to its default. | As expected | Pass |
| TC-M2-48 | UR-04 | Accessibility | D + C | **MANUAL** on the phone (Redmi 9). The automated version is skipped because `fake_cloud_firestore` deletes sub-collections with their parent, but real Firestore does not. Have some instruction history, tap Reset to default and confirm, then open Voice Guidance and the Firebase console. | Settings are back to default; the instruction history is kept. | Tested on Redmi 9, 3 October 2026: after Reset to default, the Voice Guidance history was still there, and `instruction_history` was still in the Firebase console. | Pass |
| TC-M2-49 | UR-01 | Voice Guidance | C | `addInstructionHistory("Turn left")` | The document has the text and `spokenAt`. | As expected | Pass |
| TC-M2-50 | UR-01 | Voice Guidance | R | Add 2 entries, then `watchInstructionHistory()`. | Both are listed, each with a time. | As expected | Pass |
| TC-M2-51 | UR-01 | Voice Guidance | R | Add 5 entries, then `watchInstructionHistory(limit: 3)`. | 3 entries. | As expected | Pass |
| TC-M2-52 | UR-01 | Voice Guidance | D | Add 2 entries, then `clearInstructionHistory()`. | 0 entries. | As expected | Pass |
| TC-M2-53 | UR-01, UR-04 | Voice Command | C | `addCustomCommand("  Say AGAIN ", repeat)` | Saved as "say again", repeat, on. | As expected | Pass |
| TC-M2-54 | UR-01, UR-04 | Voice Command | C | `addCustomCommand("   ", next)` | Refused with a friendly error; nothing saved. | As expected | Pass |
| TC-M2-55 | UR-01, UR-04 | Voice Command | R | Add 2 commands, then `getCustomCommands()` and `watchCustomCommands()`. | Both list the 2 commands. | As expected | Pass |
| TC-M2-56 | UR-01, UR-04 | Voice Command | U | `updateCustomCommand` to " Go ON ", next, off. | Same id; "go on", next, off. | As expected | Pass |
| TC-M2-57 | UR-01, UR-04 | Voice Command | U | `updateCustomCommand` with phrase " ". | Refused with a friendly error; the old phrase is kept. | As expected | Pass |
| TC-M2-58 | UR-01, UR-04 | Voice Command | D | Add 2 commands, then delete "say again". | Only "go on" is left. | As expected | Pass |
| TC-M2-59 | UR-02 | Haptic Alerts / alert pop-ups | C | `logAlert(obstacle, high, "Obstacle ahead")` | Logged with type, severity, message, `firedAt`; not acknowledged. | As expected | Pass |
| TC-M2-60 | UR-02 | Haptic Alerts / alert pop-ups | U | Log an alert, then `acknowledgeAlert(id)`. | acknowledged = true. | As expected | Pass |
| TC-M2-61 | UR-02 | Haptic Alerts | D | Log 2 alerts, then `clearAlertLog()`. | 0 alerts. | As expected | Pass |
| TC-M2-62 | UR-01 | Instruction Feedback | C | `addFeedback("Head north", onTrack)` | Stored status "on_track"; read back with instruction and time. | As expected | Pass |
| TC-M2-63 | UR-01 | Instruction Feedback | U | Add feedback, then `updateFeedback(id, unclear)`. | Status unclear. | As expected | Pass |
| TC-M2-64 | UR-01 | Instruction Feedback | D | Add 2 entries, then delete one. | Only the other one is left. | As expected | Pass |
| TC-M2-65 | UR-01 | Instruction Feedback | U | Delete an entry, then try to update it. | A friendly error (`VoiceDataException`), not a crash. | As expected | Pass |
| TC-M2-66 | UR-04 | All | C | Save settings, history, a command, an alert and feedback. | Everything is under `settings/test-uid` and its 4 sub-collections only. | As expected | Pass |

## Manual tests on the phone (Redmi 9, Android 12)

To do by hand with `flutter run -t lib/screens/voice/voice_dev_main.dart`.
Filled in from my manual phone test on 3 October 2026 (Redmi 9 (M2004J19C), Android 12, branch `feature/member2-voice`, tester Member 2): TC-M2-70, TC-M2-71, TC-M2-72, TC-M2-73, TC-M2-74, TC-M2-75 and TC-M2-79, all Pass. The Actual result is my own wording from that test. TC-M2-76 (TalkBack) was also tested on the Redmi 9 on 3 October 2026: Pass. The remaining rows TC-M2-67, TC-M2-68, TC-M2-69, TC-M2-77, TC-M2-80, TC-M2-81 and TC-M2-82 were tested on the Redmi 9 on 3 October 2026: all Pass. Every MANUAL row is now filled in.

| Test Case ID | Requirement | Screen | CRUD | Steps | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|---|---|
| TC-M2-67 | UR-01 | Active Navigation | C | Open the app. | "Head north on Maple Street, 120 metres" is spoken. The card shows "Head north". The instruction appears in Voice Guidance → Instruction history. | Redmi 9, 3 Oct 2026: the first instruction was spoken, shown on the card and added to the instruction history. | Pass |
| TC-M2-68 | UR-01 | Active Navigation | – | Tap the ↻ Repeat button on the instruction card. | The current instruction is spoken again. | Redmi 9, 3 Oct 2026: the current instruction was spoken again. | Pass |
| TC-M2-69 | UR-03 | Active Navigation | – | From the start, tap "Next step" once (step 2: "Turn right onto King Street"). | 2 short pulses are felt, and the instruction is spoken. | Redmi 9, 3 Oct 2026: 2 short pulses were felt and the instruction was spoken. | Pass |
| TC-M2-70 | UR-02, UR-03 | Active Navigation | C | Same step 2, straight after TC-M2-69. | The "Notice:" banner (broken pavement) appears at the top, 1 short pulse is felt, the notice is spoken, and the banner hides after about 4 s. The alert is in the Haptic Alerts → Alert log. | Check 1 Low banner + light buzz: pass | Pass |
| TC-M2-71 | UR-02, UR-03 | Active Navigation / high alert | C + U | Tap "Next step" twice more (step 4: "Continue straight"). Then tap "Dismiss alert". | Full-screen WARNING. "Warning! Warning! Obstacle ahead" is spoken at a higher pitch, and strong vibration repeats until Dismiss. After Dismiss: silent, still, and "Dismissed" in the Alert log. | Check 1 High alert + strong buzz: pass | Pass |
| TC-M2-72 | UR-01 | Voice Guidance | U | Set volume 30% and speed 1.5×, then "Test voice announcement". Restart the app. | Quieter and faster speech. The values are still set after the restart. | Check 4 Test announcement, volume, speed: pass | Pass |
| TC-M2-73 | UR-03 | Haptic Alerts | U | Tap each pattern with Gentle, then with Strong. | The six patterns feel different. Strong is stronger (if the phone supports amplitude). | Check 2 Six patterns feel different: pass; Check 2 Gentle/Medium/Strong feel different: yes | Pass |
| TC-M2-74 | UR-01, UR-04 | Voice Command | – | On Voice Command say "Hey NavAssist, repeat". Then go to Active Navigation, long-press the map and say "next". | The instruction is repeated, then the next step is announced. | Wake phrase + "repeat"/"next" recognised: yes; Press-and-hold fallback: yes | Pass |
| TC-M2-75 | UR-01, UR-04 | Voice Command | C/U/D | Add custom command "say again" → Repeat, switch it off and on, edit it, delete it. | The list updates each time. When on, saying "hey navassist say again" repeats the instruction. | Voice Command custom commands: Add pass, Edit pass, Switch off pass, Delete pass, still there after reopening yes | Pass |
| TC-M2-76 | UR-04 | All screens with TalkBack on | – | Swipe through Active Navigation and Accessibility. Press Next step. | Every button and switch has a spoken label. The new instruction and alerts are read out by themselves. | Tested with TalkBack on, Redmi 9, 3 Oct 2026: buttons and icons were read aloud, headings and switch states were announced, and I could use the screens by touch and swipe. | Pass |
| TC-M2-77 | UR-04 | Accessibility | U | Turn on Large text, High contrast and Reduce motion. Visit every Member 2 screen. | Bigger text, black/white with outlines, no animations. Nothing is cut off. | Redmi 9, 3 Oct 2026: bigger text, black/white with outlines and no animations on every screen, with nothing cut off. | Pass |
| TC-M2-79 | UR-01 | Instruction Feedback | C/U/D | Tap "On track", then "Instruction unclear". Change status (⇄) on one entry, then delete one. | Short pulse + "You are on track"; "unclear" repeats the instruction. The list shows the changes. | Check 3 On track: pass; Check 3 Instruction unclear repeats: pass; Check 3 Change + delete entry: pass | Pass |
| TC-M2-80 | UR-04 | Firebase console | – | After the tests above, open Firestore in the console. | Data is only under `settings/{anonymous uid}` and its sub-collections. | Redmi 9, 3 Oct 2026: the data was only under `settings/{anonymous uid}` and its sub-collections. | Pass |
| TC-M2-81 | UR-01, UR-04 | Active Navigation (defect D-01 retest) | – | Open Active Navigation on the phone. | The whole screen shows; no dark-blue-only screen and no red error. | Redmi 9, 3 Oct 2026: the whole screen showed, with no dark-blue-only screen and no red error. | Pass |
| TC-M2-82 | UR-01, UR-04 | Voice Command and the other 3 lists (defect D-02 retest) | R | On each of the 4 screens with a list, scroll down to the list, up to the top, and down again. | No "Bad state" error box; the list is shown each time. | Redmi 9, 3 Oct 2026: no "Bad state" error box, and each list was shown every time. | Pass |
