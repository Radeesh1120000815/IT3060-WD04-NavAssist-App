import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/emergency_contact.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/emergency_contact_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/sos_emergency_screen.dart';

void main() {
  testWidgets('SOS short press does not activate', (tester) async {
    await _pumpSos(tester);
    final control = find.text('Hold to activate SOS');

    await tester.tap(control);
    await tester.pump();

    expect(find.text('SOS activated'), findsNothing);
    expect(find.textContaining('Hold cancelled'), findsOneWidget);
  });

  testWidgets('Releasing before three seconds cancels SOS', (tester) async {
    await _pumpSos(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to activate SOS')),
    );

    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    expect(find.text('SOS activated'), findsNothing);
    expect(find.textContaining('Hold cancelled'), findsOneWidget);
  });

  testWidgets('Holding for three seconds activates simulated SOS', (
    tester,
  ) async {
    await _pumpSos(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to activate SOS')),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Keep holding'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();

    expect(find.text('SOS activated'), findsOneWidget);
    expect(find.text('Simulated active state'), findsOneWidget);
    expect(find.text('Cancel SOS'), findsOneWidget);
    await gesture.up();
  });

  testWidgets('active simulated SOS can be cancelled', (tester) async {
    await _pumpSos(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to activate SOS')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();
    await gesture.up();

    await tester.tap(find.text('Cancel SOS'));
    await tester.pump();

    expect(find.text('SOS activated'), findsNothing);
    expect(find.text('Hold to activate SOS'), findsOneWidget);
    expect(
      find.text(
        'Simulated SOS cancelled. No call, message, or location was sent.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('SOS hold control has a clear TalkBack label', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpSos(tester);

    expect(
      find.bySemanticsLabel(
        'Activate SOS. Press and hold for 3 seconds. Release early to cancel.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

Future<void> _pumpSos(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: SosEmergencyScreen(repository: _EmptyContactRepository()),
    ),
  );
  await tester.pump();
}

class _EmptyContactRepository implements EmergencyContactDataSource {
  @override
  Future<EmergencyContact?> getEmergencyContact(String contactId) async => null;

  @override
  Stream<List<EmergencyContact>> streamEmergencyContacts() =>
      Stream.value(const []);

  @override
  Future<String> createEmergencyContact({
    required String name,
    required String relationship,
    required String phone,
  }) => throw UnimplementedError();

  @override
  Future<void> updateEmergencyContact({
    required String contactId,
    required String name,
    required String relationship,
    required String phone,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteEmergencyContact(String contactId) =>
      throw UnimplementedError();

  @override
  Future<void> setPrimaryContact(String contactId) =>
      throw UnimplementedError();
}
