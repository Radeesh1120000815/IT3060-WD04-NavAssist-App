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
    expect(find.text('Contact updated'), findsOneWidget);
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
    await tester.tap(find.text('Delete Nimal Perera'));
    await tester.pumpAndSettle();
    expect(find.text('Delete emergency contact?'), findsOneWidget);
    await tester.tap(find.text('Delete contact'));
    await tester.pumpAndSettle();
    expect(repository.deleteCalls, 1);
  });
}

class _FakeContactRepository implements EmergencyContactDataSource {
  _FakeContactRepository(this.contacts);

  final Stream<List<EmergencyContact>> contacts;
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
