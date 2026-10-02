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
}