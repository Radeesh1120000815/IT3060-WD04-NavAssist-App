import 'package:go_router/go_router.dart';

import 'community_hazard_screen.dart';
import 'landmark_info_screen.dart';
import 'public_transport_screen.dart';
import 'report_hazard_screen.dart';
import 'sos_emergency_screen.dart';
import 'surroundings_screen.dart';

class SafetyRoutes {
  SafetyRoutes._();

  static const explore = '/explore';
  static const landmark = '/landmark';
  static const publicTransport = '/public-transport';
  static const hazards = '/hazards';
  static const reportHazard = '/report-hazard';
  static const sos = '/sos';
}

final List<RouteBase> safetyRoutes = [
  GoRoute(
    path: SafetyRoutes.explore,
    builder: (context, state) => const SurroundingsScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.landmark,
    builder: (context, state) => const LandmarkInfoScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.publicTransport,
    builder: (context, state) => const PublicTransportScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.hazards,
    builder: (context, state) => const CommunityHazardScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.reportHazard,
    builder: (context, state) => const ReportHazardScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.sos,
    builder: (context, state) => const SosEmergencyScreen(),
  ),
];
