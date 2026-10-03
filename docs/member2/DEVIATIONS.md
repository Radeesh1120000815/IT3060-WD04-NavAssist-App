# Member 2 – Deviations from the designs

This file lists every place where my built screens differ from the designs in `docs/member2/hifi/`, and why.

- Files **without** `_wireframe` are hi-fi designs. I matched them closely.
- Files **with** `_wireframe` are Milestone 02 wireframes. I built them in the same visual style as the hi-fi screens.

The wireframes show old FR/NFR requirement IDs. The code and these notes use only **UR-01 to UR-04**.

## General (all screens)

| # | What changed | Why |
|---|---|---|
| G1 | The colours are in my own `lib/screens/voice/theme/voice_theme.dart` (taken from the hi-fi: blue `#1D4ED8`, dark navy navigation screen, light blue-grey tiles). | The app has no shared theme or shared widgets yet, and `main.dart` is a shared file. |
| G2 | The default Android font (Roboto) is used instead of the rounded heading font in the hi-fi. | Adding a font means changing the shared `pubspec.yaml`. |
| G3 | The bottom tab bar (Home, Active Nav, Nearby, Hazards, SOS) is a **placeholder** bar with the text "Tab bar placeholder (shared layout)". It is shown **only** when the app is started from `voice_dev_main.dart` (flag `VoiceShell.showTabBarPlaceholder`). Inside the shared app it is hidden. | The tab bar belongs to the shared layout, which does not exist yet. I must not rebuild it, and the placeholder must not show twice once the real tab bar exists. |
| G4 | The **SOS** button on Active Navigation is a **placeholder**. Pressing it shows "SOS belongs to the Safety section and is not connected yet." | SOS belongs to Member 3, whose code does not exist yet. |
| G5 | My routes are in `lib/screens/voice/voice_routes.dart` (one `ShellRoute`), and I test with `lib/screens/voice/voice_dev_main.dart`. | `lib/router.dart` and `lib/main.dart` are shared files with no confirmed owner. Teammates can add `...voiceRoutes` to the shared router. |
| G6 | Large text, High contrast and Reduce motion change **my screens only** (through `VoiceAccessibilityScope` in `voice_shell.dart`). The Large text subtitle now says "on the navigation and voice screens" instead of "throughout the app". | Applying them to the whole app needs a change to the shared `main.dart`. The subtitle was changed so it does not promise something that is not true. |
| G7 | Every screen has a TalkBack label on each button and icon, touch targets of at least 48 × 48, and text that grows with the phone's text size. Selected options are shown by fill and bold text (and a tick where there is room), not by colour only. | Accessibility requirement UR-04. |

## Navigation between my screens

| # | What changed | Why |
|---|---|---|
| N1 | Every screen except Active Navigation **always** shows "< Back". If there is a screen underneath, Back goes to it. If the screen was opened directly (e.g. with `context.go` or a deep link), Back goes to Active Navigation (`/navigate`). | The hi-fi shows Back on every settings screen. Without the fallback, a screen opened directly had no way back. |
| N2 | While a **high** alert is showing, the phone's Back button or gesture works like **Dismiss**: it closes the alert and you stay on the same screen. | Without this, Back closed the screen *behind* the alert, so Dismiss did not return to the screen you were on. |
| N3 | After the "settings" voice command, Voice Command pauses listening while Accessibility is open and **listens again** when you come back. | Before, it came back showing "Not listening". |
| N4 | The demo alerts on Active Navigation come from the **demo route steps**: press Next step to reach step 2 (low hazard banner) and step 4 (high obstacle alert). Separate "Test high alert" / "Test low alert" buttons are on the Haptic Alerts screen (H2). Active Navigation has no extra "simulate" buttons. | The demo steps already fire both alert types. Adding more buttons would crowd the navigation screen. |

## Active Navigation (`active_navigation.png`)

| # | What changed | Why |
|---|---|---|
| A1 | The map is a simple **drawn** route (lines on a dark background) with a "you are here" dot that moves along the route. | There is no map package. The brief allowed a simple drawn route. |
| A2 | Added a **Repeat instruction** button (↻) on the instruction card. | Requested. It speaks the last instruction again (UR-01). |
| A3 | Added a row with **Next step**, **Voice commands** and **Feedback** buttons under the quick buttons. When the route is finished, Next step becomes **Start again**. | There is no GPS, so "Next step" moves through the demo route. The other two open screens that have no button in the hi-fi. |
| A4 | The **Nearby** quick button is a placeholder (it shows a message). | Nearby / Surroundings belongs to Member 3. |
| A5 | Added the hint "Press and hold the map to speak a command" on the map. | So users know about the long-press fallback (Milestone 02 recommendation T8). |
| A6 | The route is a **demo route** (`data/demo_route.dart`: Maple Street → King Street → Central Library, 600 m, about 9 minutes) until Member 1 sends real route data. | Member 1's Start Navigation screen does not exist yet. The handover format is in `MEMBER1_HANDOVER_NOTE.txt`. |
| A7 | The demo route fires a low alert (step 2) and a high alert (step 4). | So both alert types can be shown in a demo (UR-02). |
| A8 | With very large text the four quick buttons wrap to two per row, and the whole screen scrolls. | So nothing is cut off at large text sizes (UR-04). |
| A9 | **Addition to the hi-fi:** two quick toggles above the quick buttons, **Voice: On/Off** and **Vibration: On/Off**. They **read** `voiceEnabled` / `hapticEnabled` from `settings/{uid}` and **update** them there when tapped. Turning one off also stops speech or vibration straight away. Each is at least 48 × 48 (56 high). TalkBack reads e.g. "Voice on, switch". Besides the colour, the icon and the words "On" / "Off" change too. | Each interface needs at least 2 working CRUD operations. These give Active Navigation a Read and an Update on `settings/{uid}`, and they are a quick way to silence the phone while walking. |

## Voice Guidance (`voice_guidance.png`)

| # | What changed | Why |
|---|---|---|
| V1 | Added a **Current instruction** card (the instruction as text, with a **Replay** button). | Requested. It also helps users who cannot hear the voice in a noisy street. |
| V2 | Added **Instruction history** (the last 10 spoken instructions) with a **Clear** button and a confirm dialog. | Requested. It shows the Create / Read / Delete of `instruction_history`. |
| V3 | The volume is saved when the user lets go of the slider, not while dragging. | Saves one Firestore write instead of dozens. |

## Haptic Alerts (`haptic_alerts.png`)

| # | What changed | Why |
|---|---|---|
| H1 | Tapping a pattern row **plays it** and selects it (a tick shows the selected one). **Test haptic pattern** plays the selected pattern. | The hi-fi does not say how a pattern is chosen for the test button. |
| H2 | Added an **Alert log** section with **Test high alert**, **Test low alert** and **Clear**. | Requested. It shows the alert pop-ups and the CRUD of `alert_log`. |
| H3 | A note appears if the phone cannot vibrate. | So the user knows why nothing is felt. |
| H4 | **Arrival** always plays at full strength. The other patterns use the chosen intensity. On phones that cannot change vibration strength, Gentle / Medium / Strong feel the same. | The hi-fi says arrival is "3 strong pulses". Strength control depends on the phone's hardware. |

## Accessibility Settings (`accessibility_settings.png`)

| # | What changed | Why |
|---|---|---|
| S1 | Added **Reset to default** with a confirm dialog. | Requested. |
| S2 | Added links to **Haptic alerts** and **Voice commands**. | Requested (Haptic). Voice commands had no other way in from settings. |
| S3 | The **Emergency contact** card is a **placeholder** ("No emergency contact set"). **Edit** is disabled, with a note. My code never reads or writes `emergency_contacts`. | The data belongs to Member 3, and Member 3's code does not provide a way to read it yet. |
| S4 | "Optimise for VoiceOver / TalkBack" became "Optimise for TalkBack: new instructions and alerts are read out". | The app is Android only (VoiceOver is iPhone). The new text says what the switch actually does: it turns on TalkBack "live regions" for the instruction card and alerts. |

## Voice Command (`voice_command_wireframe.png`)

| # | What changed | Why |
|---|---|---|
| C1 | The wake phrase is **"hey navassist"** (and the user can change it), not "Hey Navi" as in the wireframe. Capitals and spaces are ignored, so "Hey Nav Assist" and "heynavassist" also match. | NavAssist is the app name in the hi-fi. |
| C2 | The "Voice command settings" button became settings on the **same screen**: wake phrase field, "Require wake phrase" switch, "Press-and-hold fallback" switch, and the custom commands list (add, edit, on/off, delete). | Fewer screens to move between, which is better for a screen reader user. |
| C3 | Added a big **press-and-hold area**. The microphone circle can be tapped to start or stop listening. | Long-press fallback (Milestone 02 recommendation T8). |
| C4 | The phone listens **only while this screen is open** (or once after a long press on the map). The wireframe note says the indicator is "visible at all times during navigation". | Android's speech recogniser stops after a few seconds of silence. A true always-on wake word needs a background wake-word engine, which is beyond this project. |

## Audio / Haptic Alert pop-ups (`alert_popup_wireframe.png`, `alert_banner_wireframe.png`)

| # | What changed | Why |
|---|---|---|
| P1 | The alerts are **pop-ups over any of my screens**, not separate routes. | The wireframe says a high alert "interrupts the current screen" and the low banner "does not block the current task". |
| P2 | The high alert says "WARNING" + the message, has a red **Dismiss alert** button, and says whether it is vibrating ("Strong vibration until you dismiss" or "Vibration is turned off"). It closes only on Dismiss, not when the "obstacle is cleared". | There is no obstacle sensor that could tell us it was cleared. |
| P3 | The low banner starts with "Notice:" and has a ✕ (Dismiss notice) button as well as hiding itself after about 4 seconds. | Not colour only. Users can also close it early. |
| P4 | The alert "tone" is the text-to-speech voice at a higher pitch ("Warning! Warning!"), not a sound file. | There is no audio-player package (it would need a change to the shared `pubspec.yaml`). |

## Navigation Instruction Feedback (`instruction_feedback_wireframe.png`)

| # | What changed | Why |
|---|---|---|
| F1 | The "chime" is **one short vibration plus the spoken words "You are on track."** | There is no audio-player package (shared `pubspec.yaml`). |
| F2 | Added **On track** and **Instruction unclear** buttons. "Unclear" changes the status card and repeats the instruction. | Requested. Both save to `feedback`. |
| F3 | Added **Recent feedback** (last 5) with **change status** (⇄) and **delete** buttons. | Requested. It shows the Read / Update / Delete of `feedback`. |
| F4 | The title is "Instruction Feedback", with "Navigation active" underneath. | The wireframe title "Navigation Active" is the same as other screens, which is confusing for TalkBack users. |
