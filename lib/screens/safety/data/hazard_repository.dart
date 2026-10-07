import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hazard.dart';

class HazardRepositoryException implements Exception {
  const HazardRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class HazardDataSource {
  String get currentUserId;
  Stream<List<Hazard>> watchHazards();
  Future<Hazard?> getHazard(String hazardId);
  Future<String> createHazard({
    required String type,
    required String description,
    required String locationName,
    required double? latitude,
    required double? longitude,
    required HazardSeverity severity,
  });
  Future<void> updateHazard({
    required String hazardId,
    required String type,
    required String description,
    required String locationName,
    required double? latitude,
    required double? longitude,
    required HazardSeverity severity,
  });
  Future<void> deleteHazard(String hazardId);
}

class HazardRepository implements HazardDataSource {
  HazardRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const collectionName = 'hazards';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _hazards =>
      _firestore.collection(collectionName);

  @override
  String get currentUserId => _auth.currentUser!.uid;

  @override
  Stream<List<Hazard>> watchHazards() {
    return _hazards
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Hazard.fromFirestore).toList());
  }

  @override
  Future<Hazard?> getHazard(String hazardId) async {
    final document = await _hazards.doc(hazardId).get();
    return document.exists ? Hazard.fromFirestore(document) : null;
  }

  @override
  Future<String> createHazard({
    required String type,
    required String description,
    required String locationName,
    required double? latitude,
    required double? longitude,
    required HazardSeverity severity,
  }) async {
    final reporterId = currentUserId;
    final document = await _hazards.add({
      'type': type,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity.firestoreValue,
      'reporterId': reporterId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
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
  }) async {
    final reporterId = currentUserId;
    final reference = _hazards.doc(hazardId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw const HazardRepositoryException('This hazard no longer exists.');
      }
      if (snapshot.data()?['reporterId'] != reporterId) {
        throw const HazardRepositoryException(
          'You can only edit hazards that you reported.',
        );
      }
      transaction.update(reference, {
        'type': type,
        'description': description,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> deleteHazard(String hazardId) async {
    final reporterId = currentUserId;
    final reference = _hazards.doc(hazardId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw const HazardRepositoryException('This hazard no longer exists.');
      }
      if (snapshot.data()?['reporterId'] != reporterId) {
        throw const HazardRepositoryException(
          'You can only delete hazards that you reported.',
        );
      }
      transaction.delete(reference);
    });
  }
}
