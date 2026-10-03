import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'voice_routes.dart';
import 'voice_shell.dart';

/// Development entry point for Member 2 only. It lets me run my screens
/// without changing the shared lib/main.dart or lib/router.dart.
///
/// Run with:  flutter run -t lib/screens/voice/voice_dev_main.dart
Future<void> main() async {
  // Same Firebase start-up as lib/main.dart.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Sign in anonymously so Firestore data is saved under a user id.
  // (VoiceRepository would also do this on first use.)
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously().timeout(
        const Duration(seconds: 10),
      );
    }
  } catch (e) {
    // No internet: the app still opens and uses default settings.
    debugPrint('voice_dev_main: anonymous sign-in failed: $e');
  }

  // Only this dev app shows the tab bar placeholder (see VoiceShell).
  VoiceShell.showTabBarPlaceholder = true;

  runApp(const VoiceDevApp());
}

final GoRouter _router = GoRouter(
  initialLocation: VoiceRoutes.activeNavigation,
  routes: voiceRoutes,
);

class VoiceDevApp extends StatelessWidget {
  const VoiceDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NavAssist (Member 2 dev)',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
