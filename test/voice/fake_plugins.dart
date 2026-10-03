import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stand-ins for the phone's vibration and text-to-speech plugins.
///
/// In a widget test there is no phone. A message to the plugins' native
/// code is never answered, so an `await` on it waits for ever (the test
/// "did not complete"). These handlers answer every message straight away
/// and remember the method names, so a test can check what was asked.
/// (Not a test file itself: the name does not end in _test.dart.)
class FakePlugins {
  final List<String> vibrationCalls = []; // e.g. ['cancel']
  final List<String> ttsCalls = []; // e.g. ['speak', 'stop']

  static const _vibration = MethodChannel('vibration');
  static const _tts = MethodChannel('flutter_tts');

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Call in setUp.
  void install() {
    _messenger.setMockMethodCallHandler(_vibration, (call) async {
      vibrationCalls.add(call.method);
      return null;
    });
    _messenger.setMockMethodCallHandler(_tts, (call) async {
      ttsCalls.add(call.method);
      return 1; // flutter_tts returns 1 for "done"
    });
  }

  /// Call in tearDown.
  void uninstall() {
    _messenger.setMockMethodCallHandler(_vibration, null);
    _messenger.setMockMethodCallHandler(_tts, null);
  }
}
