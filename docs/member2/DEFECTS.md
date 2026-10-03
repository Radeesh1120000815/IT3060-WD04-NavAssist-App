# Member 2 – Defect Log (Voice Guidance & Accessibility)

Defects found during developer testing of my part on a real phone: **Redmi 9, Android 12**, running `flutter run -t lib/screens/voice/voice_dev_main.dart`.
Neither defect was caught by `flutter analyze`, because both happen only at runtime. Each one now has an automated regression test that **failed before the fix and passes after it**.

Severity scale: **Critical**: a main screen cannot be used. **Major**: one feature on a screen cannot be used. **Minor**: cosmetic, or a workaround exists.

| ID | Title | Screen | Requirement affected | Severity | Status |
|---|---|---|---|---|---|
| D-01 | Active Navigation shows only a dark blue screen (layout error) | Active Navigation | UR-01, UR-04 | Critical | Fixed and retested on the phone, 3 October 2026 (TC-M2-81). Automated retest also passed. |
| D-02 | "Bad state: Stream has already been listened to" in the lists | Voice Command, Voice Guidance, Haptic Alerts, Instruction Feedback | UR-01, UR-02, UR-04 | Major | Fixed and retested on the phone, 3 October 2026 (TC-M2-82). Automated retest also passed. |

---

## D-01 – Active Navigation layout error

- **Found:** 2026-10-03, on the phone.
- **What the user saw:** Active Navigation showed only the dark blue background and the tab bar placeholder. No instruction, map or buttons.
- **Error in the log:** `LayoutBuilder does not support returning intrinsic dimensions`, thrown during `performLayout` by the `SliverFillRemaining` at `active_navigation_screen.dart:114`. After it, `Null check operator used on a null value` was repeated many times.
- **Severity:** Critical. The main navigation screen could not be used at all.
- **Cause:** the white bottom panel is inside `SliverFillRemaining(hasScrollBody: false)`. That widget first asks its child for its *intrinsic* (natural) height. The four quick buttons used a `LayoutBuilder`, which can only work out its size during real layout and cannot answer that question, so layout failed. The repeated null-check errors were a knock-on effect inside Flutter's own scroll view (`RenderViewportBase` reading a size that was never set). They were not a second bug. Every `!` in my files is checked for null first.
- **Fix:** in `_QuickButtons`, the `LayoutBuilder` + `Wrap` was replaced by plain `Row`s of `Expanded` buttons (4 per row, or 2 per row with very large text). A `Row` can report its intrinsic height. The look did not change.
- **Fixed in commit:** `17a7e3d` "Member 2: fix Active Navigation layout error found on phone, add layout test".
- **Regression test:** `test/voice/active_navigation_layout_test.dart`, TC-M2-04 (normal text) and TC-M2-05 (2× text). Before the fix both failed with the same errors as the phone; after the fix both pass (run 2026-10-03).
- **Checked for the same problem elsewhere:** no other `LayoutBuilder`, `SliverFillRemaining` or `Intrinsic…` widget is in my folder. The other screens use `ListView`, which never asks for intrinsic sizes. A one-off test also showed that the Add command dialog (an `AlertDialog`, which uses `IntrinsicWidth`) lays out correctly.

## D-02 – Stream listened to twice

- **Found:** 2026-10-03, on the phone.
- **What the user saw:** on Voice Command, the Custom commands list showed a red error box: `Bad state: Stream has already been listened to.` It came back on every rebuild.
- **Error in the log:** from `StreamList<CustomCommand>` at `voice_command_screen.dart:312`, thrown in `_StreamBuilderBaseState._subscribe`.
- **Severity:** Major. The list could not be used, but the rest of the screen worked.
- **Cause:** each screen created **one** stream in `initState` and passed it to `StreamList`. The repository's streams come from `async*` functions, so each can be listened to only **once**. `StreamList` is inside a `ListView`, which throws items away when they scroll far off screen, and rebuilds an item when a new widget appears above it (e.g. an error note). Each time, a new `StreamBuilder` tried to listen to the old, already-used stream.
- **Affected:** all four lists that use `StreamList`: custom commands (Voice Command), instruction history (Voice Guidance), alert log (Haptic Alerts) and recent feedback (Instruction Feedback).
- **Fix:** `StreamList` (in `widgets/voice_widgets.dart`) now takes a function `createStream` instead of a stream. It is a `StatefulWidget` that calls the function once in its own `initState`, so each new copy of the list starts its own fresh Firestore stream, and normal rebuilds do not restart it. The four screens no longer keep a stream field.
  - *Not chosen:* `asBroadcastStream()`, because a rebuilt list would miss the current data and show "Loading…". Calling the repository in `build`, because that opens a new Firestore listener on every rebuild.
- **Fixed in commit:** `cc2c9e3` "Member 2: fix stream listened twice in lists, add tests".
- **Regression test:** `test/voice/stream_list_rebuild_test.dart`, TC-M2-34 – TC-M2-37 (one per screen). Each test scrolls to the list, back to the top and down again. Before the fix all 4 failed with the same error (Voice Command at line 312, as on the phone); after the fix all pass (run 2026-10-03).

---

## Not defects in my code (found while writing tests)

These are recorded so that the test results can be understood. They are **not** counted as defects.

| Item | What happened | Outcome |
|---|---|---|
| Plugin calls never answered in widget tests | The alert tests first "did not complete": `Vibration.cancel()` sends a message to the phone's native code, and there is no phone in a widget test, so the `await` never finished. On a real phone it is answered. | Test-only stand-in `test/voice/fake_plugins.dart` answers the vibration and text-to-speech messages and records them. No app code changed. |
| `fake_cloud_firestore` deletes sub-collections | Test TC-M2-48 ("reset keeps the history") failed because the fake's `delete()` removes the document *and* its sub-collections. Real Firestore keeps sub-collections when a document is deleted. | TC-M2-48 is marked **skipped**, with the reason in the test. The behaviour is checked on the phone instead (TC-M2-48, manual). No app code changed. |
