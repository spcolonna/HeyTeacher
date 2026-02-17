import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreWrapper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void _logError(
      String operation, dynamic error, StackTrace? stackTrace) {
    print('╔═══════════════════════════════════════════════════════════════╗');
    print('║ FIRESTORE ERROR');
    print('╠═══════════════════════════════════════════════════════════════╣');
    print('║ Operation: $operation');
    print('║ Error: $error');
    if (stackTrace != null) {
      print('║ Stack: $stackTrace');
    }
    print('╚═══════════════════════════════════════════════════════════════╝');

    // Si el error contiene un link de índice, resaltarlo
    String errorStr = error.toString();
    if (errorStr.contains('console.firebase.google.com')) {
      RegExp urlPattern =
          RegExp(r'https://console\.firebase\.google\.com[^\s)]+');
      var match = urlPattern.firstMatch(errorStr);
      if (match != null) {
        print('');
        print('🔗 CREATE INDEX HERE:');
        print(match.group(0));
        print('');
      }
    }
  }

  static Future<DocumentSnapshot> getDocument(
      String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e, stackTrace) {
      _logError('GET $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  static Future<DocumentReference> addDocument(
      String collection, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e, stackTrace) {
      _logError('ADD to $collection', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).doc(docId).set(data);
    } catch (e, stackTrace) {
      _logError('SET $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).doc(docId).update(data);
    } catch (e, stackTrace) {
      _logError('UPDATE $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> deleteDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).delete();
    } catch (e, stackTrace) {
      _logError('DELETE $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  static Query query(String collection) {
    return _firestore.collection(collection);
  }

  static Stream<QuerySnapshot> getCollectionStream(
      Query query, String description) {
    return query.snapshots().handleError((error, stackTrace) {
      _logError('STREAM: $description', error, stackTrace);
    });
  }

  static CollectionReference collection(String collectionPath) {
    return _firestore.collection(collectionPath);
  }
}
