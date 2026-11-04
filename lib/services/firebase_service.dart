import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import '../config/firebase.dart';

class FirebaseService {
  final Firestore _db;

  FirebaseService([Firestore? firestore])
      : _db = firestore ?? FirebaseConfig.db;

  Firestore get db => _db;

  Future<List<String>> listCollections() async {
    final collections = await _db.listCollections();
    return collections.map((col) => col.id).toList();
  }

  Future<List<Map<String, dynamic>>> getCollection(
    String collectionPath, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    Query<DocumentData> query = _db.collection(collectionPath);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = _sanitize(doc.data());
      return {
        'id': doc.id,
        if (data is Map<String, dynamic>) ...data,
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    final docRef = _db.collection(collectionPath).doc(documentId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return null;

    final data = _sanitize(snapshot.data());
    return {
      'id': snapshot.id,
      if (data is Map<String, dynamic>) ...data,
    };
  }

  Future<String> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    final docRef = _db.collection(collectionPath).doc();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> setDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final docRef = _db.collection(collectionPath).doc(documentId);
    await docRef.set(
      data,
      options: merge ? const SetOptions.merge() : null,
    );
  }

  Future<void> updateDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final docRef = _db.collection(collectionPath).doc(documentId);
    await docRef.update(data);
  }

  Future<void> deleteDocument(
    String collectionPath,
    String documentId,
  ) async {
    final docRef = _db.collection(collectionPath).doc(documentId);
    await docRef.delete();
  }

  dynamic _sanitize(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is Iterable) return value.map(_sanitize).toList();
    return value;
  }
}
