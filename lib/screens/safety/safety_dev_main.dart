import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'safety_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  runApp(const SafetyPreviewApp());
}

final GoRouter _safetyPreviewRouter = GoRouter(
  initialLocation: SafetyRoutes.explore,
  routes: safetyRoutes,
);

class SafetyPreviewApp extends StatelessWidget {
  const SafetyPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NavAssist — Member 3 preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155E75)),
        useMaterial3: true,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      routerConfig: _safetyPreviewRouter,
    );
  }
}
