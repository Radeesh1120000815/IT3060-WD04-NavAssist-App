import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../voice/data/voice_settings_provider.dart';
import '../voice/services/haptic_service.dart';
import '../voice/services/voice_service.dart';

/// Gives Member 3 screens access to Member 2's existing voice service without
/// changing Member 2's service implementation or UI.
class SafetyVoiceScope extends StatefulWidget {
  const SafetyVoiceScope({super.key, required this.child});

  final Widget child;

  @override
  State<SafetyVoiceScope> createState() => _SafetyVoiceScopeState();
}

class _SafetyVoiceScopeState extends State<SafetyVoiceScope> {
  late final VoiceSettingsProvider _settings;
  late final VoiceService _voice;
  late final HapticService _haptic;

  @override
  void initState() {
    super.initState();
    _settings = VoiceSettingsProvider()..load();
    _voice = VoiceService(_settings);
    _haptic = HapticService(_settings);
  }

  @override
  void dispose() {
    _haptic.stop();
    _voice.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider.value(value: _voice),
        Provider.value(value: _haptic),
      ],
      child: widget.child,
    );
  }
}
