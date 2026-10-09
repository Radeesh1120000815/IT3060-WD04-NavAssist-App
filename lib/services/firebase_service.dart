import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // CREATE — add a new document to any collection
  static Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    DocumentReference ref = await _db.collection(collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // READ — get all documents in a collection (one-time fetch)
  static Future<List<Map<String, dynamic>>> getDocuments(String collection) async {
    QuerySnapshot snapshot = await _db.collection(collection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // READ — real-time stream (auto-updates when data changes)
  static Stream<List<Map<String, dynamic>>> streamDocuments(String collection) {
    return _db.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // UPDATE — update fields in an existing document
  static Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  // DELETE — remove a document
  static Future<void> deleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  // ===== RECENT SEARCHES (Home / Search screens) =====

  // CREATE or UPDATE — add a search, or if it already exists, refresh its timestamp
  // (prevents duplicates). Includes a timeout so a flaky network connection
  // (observed on some emulators) can't hang navigation indefinitely.
  static Future<void> addOrUpdateRecentSearch(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      final existing = await _db
          .collection('recent_searches')
          .where('name', isEqualTo: trimmed)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference
            .update({'createdAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 5));
      } else {
        await _db.collection('recent_searches').add({
          'name': trimmed,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('addOrUpdateRecentSearch failed or timed out: $e');
      // Swallow the error so navigation can still proceed even if saving fails
      // (e.g. due to a temporary network issue).
    }
  }

  // READ — live stream of recent searches, newest first, limited to 10
  static Stream<List<Map<String, dynamic>>> streamRecentSearches({int limit = 10}) {
    if (Firebase.apps.isEmpty) return Stream.value(const []);

    return _db
        .collection('recent_searches')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}