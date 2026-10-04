import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      data['id'] = doc.id; // keep the document ID for updates/deletes later
      return data;
    }).toList();
  }

  // READ — real-time stream (auto-updates when data changes, useful for hazards list)
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

  // Add a search, or if it already exists, just refresh its timestamp (no duplicates)
static Future<void> addOrUpdateRecentSearch(String name) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;

  final existing = await _db
      .collection('recent_searches')
      .where('name', isEqualTo: trimmed)
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) {
    // Already exists — just bump its timestamp to move it to the top
    await existing.docs.first.reference.update({
      'createdAt': FieldValue.serverTimestamp(),
    });
  } else {
    // New search — add it
    await _db.collection('recent_searches').add({
      'name': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// Live stream of recent searches, newest first, limited to 10
static Stream<List<Map<String, dynamic>>> streamRecentSearches({int limit = 10}) {
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