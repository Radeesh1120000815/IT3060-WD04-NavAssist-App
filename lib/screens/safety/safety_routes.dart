import 'package:go_router/go_router.dart';

import 'add_emergency_contact_screen.dart';
import 'community_hazard_screen.dart';
import 'data/emergency_contact.dart';
import 'data/hazard.dart';
import 'landmark_info_screen.dart';
import 'manage_emergency_contacts_screen.dart';
import 'public_transport_screen.dart';
import 'report_hazard_screen.dart';
import 'sos_emergency_screen.dart';
import 'surroundings_screen.dart';
import 'safety_voice_scope.dart';

class SafetyRoutes {
  SafetyRoutes._();

  static const explore = '/explore';
  static const landmark = '/landmark';
  static const publicTransport = '/public-transport';
  static const hazards = '/hazards';
  static const reportHazard = '/report-hazard';
  static const editHazard = '/report-hazard/:hazardId';
  static const sos = '/sos';
  static const addEmergencyContact = '/emergency-contact/add';
  static const manageEmergencyContacts = '/emergency-contacts';
  static const editEmergencyContact = '/emergency-contact/:contactId/edit';

  static String editHazardPath(String hazardId) => '/report-hazard/$hazardId';
  static String editEmergencyContactPath(String contactId) =>
      '/emergency-contact/$contactId/edit';
}

final List<RouteBase> safetyRoutes = [
  ShellRoute(
    builder: (context, state, child) => SafetyVoiceScope(child: child),
    routes: _safetyChildRoutes,
  ),
];

final List<RouteBase> _safetyChildRoutes = [
  GoRoute(
    path: SafetyRoutes.explore,
    builder: (context, state) => const SurroundingsScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.landmark,
    builder: (context, state) => LandmarkInfoScreen(
      landmark: state.extra is LandmarkData
          ? state.extra! as LandmarkData
          : LandmarkData.demo,
    ),
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
    path: SafetyRoutes.editHazard,
    builder: (context, state) => ReportHazardScreen(
      hazardId: state.pathParameters['hazardId'],
      initialHazard: state.extra is Hazard ? state.extra! as Hazard : null,
    ),
  ),
  GoRoute(
    path: SafetyRoutes.sos,
    builder: (context, state) => const SosEmergencyScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.addEmergencyContact,
    builder: (context, state) => const AddEmergencyContactScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.manageEmergencyContacts,
    builder: (context, state) => const ManageEmergencyContactsScreen(),
  ),
  GoRoute(
    path: SafetyRoutes.editEmergencyContact,
    builder: (context, state) => AddEmergencyContactScreen(
      contact: state.extra is EmergencyContact
          ? state.extra! as EmergencyContact
          : null,
    ),
  ),
];
