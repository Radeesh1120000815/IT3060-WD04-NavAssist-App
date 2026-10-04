import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class StartNavigationScreen extends StatefulWidget {
  final Map<String, dynamic>? destinationData;
  const StartNavigationScreen({super.key, this.destinationData});

  @override
  State<StartNavigationScreen> createState() => _StartNavigationScreenState();
}

class _StartNavigationScreenState extends State<StartNavigationScreen> {
  static const Color primaryBlue = Color(0xFF1B4FD8);

  final FlutterTts _tts = FlutterTts();
  bool audioOn = true;
  bool vibrationOn = true;

  late String destinationName;
  final String nextInstruction = 'Turn left in 200 m';

  @override
  void initState() {
    super.initState();
    destinationName = widget.destinationData?['destinationName'] ?? 'your destination';
    _announceStart();
  }

  Future<void> _announceStart() async {
    if (audioOn) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.speak('Navigation started. Heading towards $destinationName. $nextInstruction');
    }
    if (vibrationOn) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 300);
      }
    }
  }

  void _toggleAudio() {
    setState(() => audioOn = !audioOn);
    if (!audioOn) _tts.stop();
  }

  void _toggleVibration() {
    setState(() => vibrationOn = !vibrationOn);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 6),
              const Text(
                'Navigation Started',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Next instruction card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.turn_left, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nextInstruction,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Simplified route trace (visual placeholder for a real map)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Route map preview\n(to ${destinationData_display()})',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Audio / Vibration toggles
              Row(
                children: [
                  Expanded(
                    child: _ToggleTile(
                      icon: audioOn ? Icons.volume_up : Icons.volume_off,
                      label: audioOn ? 'Audio On' : 'Audio Off',
                      active: audioOn,
                      onTap: _toggleAudio,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToggleTile(
                      icon: vibrationOn ? Icons.vibration : Icons.phone_android,
                      label: vibrationOn ? 'Vibration On' : 'Vibration Off',
                      active: vibrationOn,
                      onTap: _toggleVibration,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // SOS button (kept visible during navigation)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SOS pressed (placeholder)')),
                    );
                  },
                  icon: const Icon(Icons.warning_amber, color: Colors.red),
                  label: const Text('SOS', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // End Navigation
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _tts.stop();
                    context.go('/');
                  },
                  child: const Text('End Navigation', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  String destinationData_display() => destinationName;
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.08) : Colors.grey.shade100,
          border: Border.all(color: active ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? color : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    color: active ? color : Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
