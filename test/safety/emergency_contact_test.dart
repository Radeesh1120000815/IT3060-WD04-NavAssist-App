import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/add_emergency_contact_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/emergency_contact.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/data/emergency_contact_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/manage_emergency_contacts_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/safety/sos_emergency_screen.dart';

void main() {
  group('EmergencyContact', () {
    test('serializes and deserializes Firestore-compatible values', () {
      final createdAt = DateTime.utc(2026, 10, 7, 10, 30);
      final contact = EmergencyContact(
        id: 'contact-1',
        name: 'Maya Perera',
        relationship: 'Sister',
        phone: '0771234567',
        isPrimary: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final map = contact.toMap();
      final restored = EmergencyContact.fromMap('contact-1', map);

      expect(map['createdAt'], isA<Timestamp>());
      expect(restored.id, 'contact-1');
      expect(restored.name, 'Maya Perera');
      expect(restored.relationship, 'Sister');
      expect(restored.phone, '0771234567');
      expect(
        restored.createdAt?.millisecondsSinceEpoch,
        createdAt.millisecondsSinceEpoch,
      );
    });

    test('uses safe fallbacks for malformed documents', () {
      final contact = EmergencyContact.fromMap('broken', {
        'name': 42,
        'relationship': '',
      });

      expect(contact.name, 'Unnamed contact');
      expect(contact.relationship, 'Relationship unknown');
      expect(contact.phone, 'Phone unavailable');
      expect(contact.createdAt, isNull);
    });
  });

  testWidgets('add contact validates all required fields', (tester) async {
    final repository = _FakeContactRepository(Stream.value(const []));
    await tester.pumpWidget(
      MaterialApp(home: AddEmergencyContactScreen(repository: repository)),
    );

    await tester.tap(find.text('Save contact'));
    await tester.pump();

    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Relationship is required.'), findsOneWidget);
    expect(find.text('Phone number is required.'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('Other relationship shows custom relationship field', (
    tester,
  ) async {
    final repository = _FakeContactRepository(Stream.value(const []));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: AddEmergencyContactScreen(repository: repository)),
    );

    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    expect(find.text('Custom relationship'), findsOneWidget);
  });

  testWidgets('SOS shows empty contact state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SosEmergencyScreen(
          repository: _FakeContactRepository(Stream.value(const [])),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No emergency contact saved'), findsOneWidget);
    expect(find.text('Add emergency contact'), findsOneWidget);
  });

  testWidgets('SOS displays contact loading state', (tester) async {
    final controller = StreamController<List<EmergencyContact>>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: SosEmergencyScreen(
          repository: _FakeContactRepository(controller.stream),
        ),
      ),
    );

    expect(find.text('Loading emergency contact...'), findsOneWidget);
  });

  testWidgets('SOS displays the saved primary contact', (tester) async {
    const contact = EmergencyContact(
      id: 'contact-1',
      name: 'Maya Perera',
      relationship: 'Sister',
      phone: '0771234567',
      isPrimary: true,
      createdAt: null,
      updatedAt: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SosEmergencyScreen(
          repository: _FakeContactRepository(Stream.value(const [contact])),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Maya Perera'), findsWidgets);
    expect(find.text('Sister - 0771234567'), findsOneWidget);
  });

  testWidgets('SOS displays a contact read error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SosEmergencyScreen(
          repository: _FakeContactRepository(
            Stream.error(Exception('permission denied')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Could not load emergency contacts'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('SOS chooses primary contact from multiple contacts', (
    tester,
  ) async {
    const contacts = [
      EmergencyContact(
        id: 'one',
        name: 'First Contact',
        relationship: 'Friend',
        phone: '0711111111',
        isPrimary: false,
        createdAt: null,
        updatedAt: null,
      ),
      EmergencyContact(
        id: 'two',
        name: 'Primary Contact',
        relationship: 'Sister',
        phone: '0722222222',
        isPrimary: true,
        createdAt: null,
        updatedAt: null,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: SosEmergencyScreen(
          repository: _FakeContactRepository(Stream.value(contacts)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Primary Contact'), findsOneWidget);
    expect(find.text('First Contact'), findsNothing);
    expect(find.text('Manage contacts'), findsOneWidget);
  });

  testWidgets('edit form loads contact and saves an update', (tester) async {
    const contact = EmergencyContact(
      id: 'edit-me',
      name: 'Maya Perera',
      relationship: 'Sister',
      phone: '0771234567',
      isPrimary: true,
      createdAt: null,
      updatedAt: null,
    );
    final repository = _FakeContactRepository(Stream.value(const [contact]));
    await tester.pumpWidget(
      MaterialApp(
        home: AddEmergencyContactScreen(
          repository: repository,
          contact: contact,
        ),
      ),
    );

    expect(find.text('Edit emergency contact'), findsOneWidget);
    expect(find.text('Maya Perera'), findsWidgets);
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.updateCalls, 1);
    expect(find.text('Contact updated successfully'), findsOneWidget);
  });

  testWidgets('failed add preserves all entered contact values', (
    tester,
  ) async {
    final repository = _FakeContactRepository(
      Stream.value(const []),
      createError: const EmergencyContactRepositoryException(
        'Permission denied. Unable to save this contact.',
      ),
    );
    await _pumpContactScreen(
      tester,
      AddEmergencyContactScreen(repository: repository),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Amal Silva');
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Neighbour');
    await tester.enterText(find.byType(TextFormField).at(2), '0771234567');
    await tester.ensureVisible(find.text('Save contact'));
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();

    expect(
      find.text('Permission denied. Unable to save this contact.'),
      findsOneWidget,
    );
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller?.text, 'Amal Silva');
    expect(fields[1].controller?.text, 'Neighbour');
    expect(fields[2].controller?.text, '0771234567');
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Save contact'), findsOneWidget);
  });

  testWidgets('failed update preserves edited contact values', (tester) async {
    const contact = EmergencyContact(
      id: 'edit-me',
      name: 'Maya Perera',
      relationship: 'Sister',
      phone: '0771234567',
      isPrimary: true,
      createdAt: null,
      updatedAt: null,
    );
    final repository = _FakeContactRepository(
      Stream.value(const [contact]),
      updateError: const EmergencyContactRepositoryException(
        'Network or Firestore unavailable. Try again.',
      ),
    );
    await _pumpContactScreen(
      tester,
      AddEmergencyContactScreen(repository: repository, contact: contact),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Maya Fernando');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Network or Firestore unavailable. Try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      'Maya Fernando',
    );
    expect(find.text('Sister'), findsWidgets);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('successful add shows clear success feedback', (tester) async {
    final repository = _FakeContactRepository(Stream.value(const []));
    await _pumpContactScreen(
      tester,
      AddEmergencyContactScreen(repository: repository),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Maya Perera');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sister').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '0771234567');
    await tester.ensureVisible(find.text('Save contact'));
    await tester.tap(find.text('Save contact'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Contact added successfully'), findsOneWidget);
  });

  testWidgets('management shows multiple contacts and confirms deletion', (
    tester,
  ) async {
    const contacts = [
      EmergencyContact(
        id: 'one',
        name: 'Maya Perera',
        relationship: 'Sister',
        phone: '0771234567',
        isPrimary: true,
        createdAt: null,
        updatedAt: null,
      ),
      EmergencyContact(
        id: 'two',
        name: 'Nimal Perera',
        relationship: 'Father',
        phone: '0712345678',
        isPrimary: false,
        createdAt: null,
        updatedAt: null,
      ),
    ];
    final repository = _FakeContactRepository(Stream.value(contacts));
    await tester.pumpWidget(
      MaterialApp(home: ManageEmergencyContactsScreen(repository: repository)),
    );
    await tester.pump();

    expect(find.text('Maya Perera'), findsOneWidget);
    expect(find.text('Nimal Perera'), findsOneWidget);
    expect(find.text('Primary contact'), findsOneWidget);
    expect(
      find.text('Your primary contact is shown during SOS activation.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete Nimal Perera'));
    await tester.pumpAndSettle();
    expect(find.text('Delete emergency contact?'), findsOneWidget);
    expect(
      find.text('Nimal Perera will be removed from your emergency contacts.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete contact'));
    await tester.pumpAndSettle();
    expect(repository.deleteCalls, 1);
  });

  testWidgets('management displays primary first and explains reassignment', (
    tester,
  ) async {
    final older = DateTime.utc(2026, 1, 1);
    final newer = DateTime.utc(2026, 1, 2);
    final contacts = [
      EmergencyContact(
        id: 'older',
        name: 'Older Contact',
        relationship: 'Friend',
        phone: '0711111111',
        isPrimary: false,
        createdAt: older,
        updatedAt: older,
      ),
      EmergencyContact(
        id: 'primary',
        name: 'Primary Contact',
        relationship: 'Sister',
        phone: '0722222222',
        isPrimary: true,
        createdAt: newer,
        updatedAt: newer,
      ),
    ];
    await _pumpContactScreen(
      tester,
      ManageEmergencyContactsScreen(
        repository: _FakeContactRepository(Stream.value(contacts)),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Primary Contact')).dy,
      lessThan(tester.getTopLeft(find.text('Older Contact')).dy),
    );
    await tester.tap(find.text('Delete Primary Contact'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Primary Contact will be removed. Older Contact will automatically become the primary contact.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep contact'));
    await tester.pumpAndSettle();
  });

  testWidgets('changing primary shows clear success feedback', (tester) async {
    const contacts = [
      EmergencyContact(
        id: 'one',
        name: 'Maya Perera',
        relationship: 'Sister',
        phone: '0771234567',
        isPrimary: true,
        createdAt: null,
        updatedAt: null,
      ),
      EmergencyContact(
        id: 'two',
        name: 'Nimal Perera',
        relationship: 'Father',
        phone: '0712345678',
        isPrimary: false,
        createdAt: null,
        updatedAt: null,
      ),
    ];
    final repository = _FakeContactRepository(Stream.value(contacts));
    await _pumpContactScreen(
      tester,
      ManageEmergencyContactsScreen(repository: repository),
    );

    await tester.tap(find.text('Make Nimal Perera primary'));
    await tester.pumpAndSettle();

    expect(repository.setPrimaryCalls, 1);
    expect(
      find.text(
        'Primary contact changed successfully. Nimal Perera is now the primary contact.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpContactScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pump();
}

class _FakeContactRepository implements EmergencyContactDataSource {
  _FakeContactRepository(this.contacts, {this.createError, this.updateError});

  final Stream<List<EmergencyContact>> contacts;
  final Object? createError;
  final Object? updateError;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int setPrimaryCalls = 0;

  @override
  Future<String> createEmergencyContact({
    required String name,
    required String relationship,
    required String phone,
  }) async {
    createCalls++;
    if (createError case final error?) throw error;
    return 'new-contact';
  }

  @override
  Stream<List<EmergencyContact>> streamEmergencyContacts() => contacts;

  @override
  Future<void> updateEmergencyContact({
    required String contactId,
    required String name,
    required String relationship,
    required String phone,
  }) async {
    updateCalls++;
    if (updateError case final error?) throw error;
  }

  @override
  Future<void> deleteEmergencyContact(String contactId) async {
    deleteCalls++;
  }

  @override
  Future<void> setPrimaryContact(String contactId) async {
    setPrimaryCalls++;
  }
}
