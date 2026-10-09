import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/add_emergency_contact_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/community_hazard_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/emergency_contact.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/emergency_contact_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/hazard.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/hazard_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/landmark_info_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/manage_emergency_contacts_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/report_hazard_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/sos_emergency_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/surroundings_screen.dart';

void main() {
  testWidgets('Explore and Landmark support 2x text on a narrow screen', (
    tester,
  ) async {
    await _pumpAccessible(tester, const SurroundingsScreen());
    expect(find.text('Explore surroundings'), findsOneWidget);
    await _scrollTo(tester, find.text('SOS / Emergency'));

    await _pumpAccessible(tester, const LandmarkInfoScreen());
    expect(find.text('Central Library'), findsOneWidget);
    await _scrollTo(tester, find.text('Start guidance'));
  });

  testWidgets('hazard screens support 2x text and narrow action layouts', (
    tester,
  ) async {
    final repository = _LayoutHazardRepository();
    await _pumpAccessible(
      tester,
      CommunityHazardScreen(repository: repository),
    );
    await _scrollTo(tester, find.text('Delete'));

    await _pumpAccessible(tester, ReportHazardScreen(repository: repository));
    await _scrollTo(tester, find.text('Blocked path'));
    await tester.tap(find.text('Blocked path').first);
    await tester.pump();
    await _scrollTo(tester, find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(find.text('Review hazard report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SOS supports 2x text on a narrow screen', (tester) async {
    await _pumpAccessible(
      tester,
      SosEmergencyScreen(repository: _LayoutContactRepository()),
    );
    await _scrollTo(tester, find.text('Primary Contact'));
    expect(find.text('Primary Contact'), findsOneWidget);
    await _scrollTo(tester, find.text('Hold to activate SOS'));
  });

  testWidgets('contact forms and management support 2x text when narrow', (
    tester,
  ) async {
    final repository = _LayoutContactRepository();
    await _pumpAccessible(
      tester,
      AddEmergencyContactScreen(repository: repository),
    );
    await _scrollTo(tester, find.text('Save contact'));

    await _pumpAccessible(
      tester,
      ManageEmergencyContactsScreen(repository: repository),
    );
    await _scrollTo(tester, find.text('Delete Secondary Contact'));
  });

  testWidgets('critical Safety actions expose meaningful semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpAccessible(tester, const SurroundingsScreen());
    expect(
      find.bySemanticsLabel('Speak / replay nearby places'),
      findsOneWidget,
    );

    await _pumpAccessible(
      tester,
      CommunityHazardScreen(repository: _LayoutHazardRepository()),
    );
    await _scrollTo(tester, find.text('Edit'));
    expect(
      find.bySemanticsLabel(
        RegExp(r'Blocked path\. HIGH severity\..*Main Street\.'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Edit Blocked path hazard report'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Delete Blocked path hazard report'),
      findsOneWidget,
    );

    await _pumpAccessible(
      tester,
      ManageEmergencyContactsScreen(repository: _LayoutContactRepository()),
    );
    await _scrollTo(tester, find.text('Primary contact'));
    expect(
      find.bySemanticsLabel(
        RegExp(r'Primary Contact is the primary emergency contact'),
      ),
      findsOneWidget,
    );
    await _scrollTo(tester, find.text('Make Secondary Contact primary'));
    expect(
      find.bySemanticsLabel('Make Secondary Contact primary'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

Future<void> _pumpAccessible(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

class _LayoutContactRepository implements EmergencyContactDataSource {
  static const contacts = [
    EmergencyContact(
      id: 'primary',
      name: 'Primary Contact',
      relationship: 'Sister',
      phone: '0771234567',
      isPrimary: true,
      createdAt: null,
      updatedAt: null,
    ),
    EmergencyContact(
      id: 'secondary',
      name: 'Secondary Contact',
      relationship: 'Friend',
      phone: '0712345678',
      isPrimary: false,
      createdAt: null,
      updatedAt: null,
    ),
  ];

  @override
  Stream<List<EmergencyContact>> streamEmergencyContacts() =>
      Stream.value(contacts);

  @override
  Future<EmergencyContact?> getEmergencyContact(String contactId) async =>
      contacts.where((contact) => contact.id == contactId).firstOrNull;

  @override
  Future<String> createEmergencyContact({
    required String name,
    required String relationship,
    required String phone,
  }) async => 'new-contact';

  @override
  Future<void> updateEmergencyContact({
    required String contactId,
    required String name,
    required String relationship,
    required String phone,
  }) async {}

  @override
  Future<void> deleteEmergencyContact(String contactId) async {}

  @override
  Future<void> setPrimaryContact(String contactId) async {}
}

class _LayoutHazardRepository implements HazardDataSource {
  static const hazard = Hazard(
    id: 'hazard',
    type: 'Blocked path',
    description: 'Construction blocks the pavement',
    locationName: 'Main Street',
    latitude: null,
    longitude: null,
    severity: HazardSeverity.high,
    reporterId: 'owner',
    createdAt: null,
    updatedAt: null,
  );

  @override
  String get currentUserId => 'owner';

  @override
  Stream<List<Hazard>> watchHazards() => Stream.value(const [hazard]);

  @override
  Future<Hazard?> getHazard(String hazardId) async => hazard;

  @override
  Future<String> createHazard({
    required String type,
    required String description,
    required String locationName,
    required double? latitude,
    required double? longitude,
    required HazardSeverity severity,
  }) async => 'new-hazard';

  @override
  Future<void> updateHazard({
    required String hazardId,
    required String type,
    required String description,
    required String locationName,
    required double? latitude,
    required double? longitude,
    required HazardSeverity severity,
  }) async {}

  @override
  Future<void> deleteHazard(String hazardId) async {}
}
