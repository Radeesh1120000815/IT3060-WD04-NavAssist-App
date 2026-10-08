import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'emergency_contact.dart';

class EmergencyContactRepositoryException implements Exception {
  const EmergencyContactRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class EmergencyContactDataSource {
  Stream<List<EmergencyContact>> streamEmergencyContacts();

  Future<String> createEmergencyContact({
    required String name,
    required String relationship,
    required String phone,
  });

  Future<void> updateEmergencyContact({
    required String contactId,
    required String name,
    required String relationship,
    required String phone,
  });

  Future<void> deleteEmergencyContact(String contactId);

  Future<void> setPrimaryContact(String contactId);
}

class EmergencyContactRepository implements EmergencyContactDataSource {
  EmergencyContactRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmergencyContactRepositoryException(
        'Authentication required. Sign in before accessing emergency contacts.',
      );
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _contacts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts');
  }

  @override
  Stream<List<EmergencyContact>> streamEmergencyContacts() async* {
    final userId = _currentUserId;
    try {
      await for (final snapshot in _contacts(
        userId,
      ).orderBy('createdAt').snapshots()) {
        yield snapshot.docs
            .map(EmergencyContact.fromFirestore)
            .toList(growable: false);
      }
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Emergency contact read failed: ${error.plugin}/${error.code}: ${error.message}',
      );
      Error.throwWithStackTrace(
        EmergencyContactRepositoryException(
          emergencyContactErrorMessage(error, operation: 'load'),
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<String> createEmergencyContact({
    required String name,
    required String relationship,
    required String phone,
  }) async {
    final userId = _currentUserId;
    final cleanName = name.trim();
    final cleanRelationship = relationship.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isEmpty || cleanRelationship.isEmpty || cleanPhone.isEmpty) {
      throw const EmergencyContactRepositoryException(
        'Name, relationship, and phone number are required.',
      );
    }

    try {
      final existing = await _contacts(userId).limit(1).get();
      final document = await _contacts(userId).add({
        'name': cleanName,
        'relationship': cleanRelationship,
        'phone': cleanPhone,
        'isPrimary': existing.docs.isEmpty,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return document.id;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Emergency contact create failed: ${error.plugin}/${error.code}: ${error.message}',
      );
      Error.throwWithStackTrace(
        EmergencyContactRepositoryException(
          emergencyContactErrorMessage(error, operation: 'save'),
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<void> updateEmergencyContact({
    required String contactId,
    required String name,
    required String relationship,
    required String phone,
  }) async {
    final userId = _currentUserId;
    try {
      await _contacts(userId).doc(contactId).update({
        'name': name.trim(),
        'relationship': relationship.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      _throwFirestoreError(error, stackTrace, operation: 'update');
    }
  }

  @override
  Future<void> setPrimaryContact(String contactId) async {
    final userId = _currentUserId;
    try {
      final snapshot = await _contacts(userId).get();
      if (!snapshot.docs.any((document) => document.id == contactId)) {
        throw const EmergencyContactRepositoryException(
          'This emergency contact no longer exists.',
        );
      }
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.update(document.reference, {
          'isPrimary': document.id == contactId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (error, stackTrace) {
      _throwFirestoreError(error, stackTrace, operation: 'set primary');
    }
  }

  @override
  Future<void> deleteEmergencyContact(String contactId) async {
    final userId = _currentUserId;
    try {
      final snapshot = await _contacts(userId).orderBy('createdAt').get();
      final target = snapshot.docs.where(
        (document) => document.id == contactId,
      );
      if (target.isEmpty) {
        throw const EmergencyContactRepositoryException(
          'This emergency contact no longer exists.',
        );
      }
      final wasPrimary =
          target.first.data()['isPrimary'] == true ||
          (!snapshot.docs.any(
                (document) => document.data()['isPrimary'] == true,
              ) &&
              snapshot.docs.first.id == contactId);
      final remaining = snapshot.docs
          .where((document) => document.id != contactId)
          .toList(growable: false);
      final batch = _firestore.batch()..delete(target.first.reference);
      if (wasPrimary && remaining.isNotEmpty) {
        batch.update(remaining.first.reference, {
          'isPrimary': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (error, stackTrace) {
      _throwFirestoreError(error, stackTrace, operation: 'delete');
    }
  }
}

Never _throwFirestoreError(
  FirebaseException error,
  StackTrace stackTrace, {
  required String operation,
}) {
  debugPrint(
    'Emergency contact $operation failed: ${error.plugin}/${error.code}: ${error.message}',
  );
  Error.throwWithStackTrace(
    EmergencyContactRepositoryException(
      emergencyContactErrorMessage(error, operation: operation),
    ),
    stackTrace,
  );
}

String emergencyContactErrorMessage(Object error, {required String operation}) {
  if (error is EmergencyContactRepositoryException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Permission denied. You do not have permission to $operation emergency contacts.',
      'unauthenticated' =>
        'Authentication required. Sign in before emergency contacts can be ${operation == 'load' ? 'loaded' : 'saved'}.',
      'failed-precondition' =>
        'Firestore could not $operation contacts because its current configuration does not support this query.',
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' => 'Network or Firestore unavailable. Check your connection and try again.',
      _ =>
        'Firestore could not $operation contacts (${error.code}). ${error.message ?? 'Try again.'}',
    };
  }
  return 'Could not $operation emergency contacts. Check the connection and try again.';
}
