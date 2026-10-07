import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/community_hazard_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/hazard.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/hazard_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/report_hazard_screen.dart';

void main() {
  testWidgets('Report Hazard blocks submit without a category', (tester) async {
    final repository = _FakeHazardRepository(const []);
    await _pumpLarge(tester, ReportHazardScreen(repository: repository));

    final submit = find.text('Submit report');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(
      find.text('Select one hazard category before submitting.'),
      findsOneWidget,
    );
    expect(repository.createCalls, 0);
  });

  testWidgets('Selecting a hazard category updates the form', (tester) async {
    await _pumpLarge(
      tester,
      ReportHazardScreen(repository: _FakeHazardRepository(const [])),
    );

    await tester.tap(find.text('Pothole').first);
    await tester.pump();

    expect(find.text('Selected'), findsOneWidget);
  });

  testWidgets('Hazard list shows its empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityHazardScreen(
          repository: _FakeHazardRepository(const []),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No hazards to show'), findsOneWidget);
  });

  testWidgets('Owner hazard shows Edit and Delete actions', (tester) async {
    await _pumpHazards(tester, reporterId: 'owner');

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Non-owner hazard hides Edit and Delete actions', (tester) async {
    await _pumpHazards(tester, reporterId: 'another-user');

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('Edit mode pre-fills existing hazard data', (tester) async {
    final repository = _FakeHazardRepository(const [], userId: 'owner');
    await _pumpLarge(
      tester,
      ReportHazardScreen(
        repository: repository,
        hazardId: sampleHazard.id,
        initialHazard: sampleHazard,
      ),
    );

    expect(find.text('Edit hazard report'), findsOneWidget);
    expect(find.text('Blocked path'), findsOneWidget);
    expect(find.text('Construction blocks the pavement'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('Delete action shows confirmation dialog', (tester) async {
    await _pumpHazards(tester, reporterId: 'owner');

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete hazard report?'), findsOneWidget);
    expect(find.text('Keep report'), findsOneWidget);
    expect(find.text('Delete report'), findsOneWidget);
  });

  testWidgets('Canceling hazard deletion does not delete it', (tester) async {
    final repository = await _pumpHazards(tester, reporterId: 'owner');

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep report'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
    expect(find.text('Blocked path'), findsOneWidget);
  });
}

const sampleHazard = Hazard(
  id: 'hazard-1',
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

Future<_FakeHazardRepository> _pumpHazards(
  WidgetTester tester, {
  required String reporterId,
}) async {
  final repository = _FakeHazardRepository([
    Hazard(
      id: sampleHazard.id,
      type: sampleHazard.type,
      description: sampleHazard.description,
      locationName: sampleHazard.locationName,
      latitude: null,
      longitude: null,
      severity: sampleHazard.severity,
      reporterId: reporterId,
      createdAt: null,
      updatedAt: null,
    ),
  ], userId: 'owner');
  await tester.pumpWidget(
    MaterialApp(home: CommunityHazardScreen(repository: repository)),
  );
  await tester.pump();
  return repository;
}

Future<void> _pumpLarge(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: child));
}

class _FakeHazardRepository implements HazardDataSource {
  _FakeHazardRepository(this.hazards, {this.userId = 'owner'});

  final List<Hazard> hazards;
  final String userId;
  int createCalls = 0;
  int deleteCalls = 0;

  @override
  String get currentUserId => userId;

  @override
  Stream<List<Hazard>> watchHazards() => Stream.value(hazards);

  @override
  Future<Hazard?> getHazard(String hazardId) async =>
      hazards.where((hazard) => hazard.id == hazardId).firstOrNull;

  @override
  Future<String> createHazard({
    required String type,
    required String description,
    required String locationName,
    required double? latitude,
    required double? longitude,
    required HazardSeverity severity,
  }) async {
    createCalls++;
    return 'new-hazard';
  }

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
  Future<void> deleteHazard(String hazardId) async {
    deleteCalls++;
  }
}
