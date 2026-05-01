import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teaching_material.dart';
import '../models/teacher_profile.dart';
import 'firestore_wrapper.dart';

class MaterialService {
  // Upload a new teaching material
  Future<String> uploadMaterial(TeachingMaterial material) async {
    try {
      DocumentReference docRef =
          await FirestoreWrapper.addDocument('materials', material.toMap());
      return docRef.id;
    } catch (e, stackTrace) {
      print('Error uploading material: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get all materials
  Stream<List<TeachingMaterial>> getAllMaterials() {
    Query query = FirestoreWrapper.query('materials')
        .orderBy('uploadedAt', descending: true);

    return FirestoreWrapper.getCollectionStream(query, 'All materials').map(
        (snapshot) => snapshot.docs
            .map((doc) => TeachingMaterial.fromFirestore(doc))
            .toList());
  }

  // Returns public materials + materials from the given institution IDs.
  // Two Firestore queries merged client-side (Firestore has no OR across fields).
  Stream<List<TeachingMaterial>> getMaterialsForUser(
      List<String> institutionIds) {
    // Public materials (no institutionId)
    final publicStream = FirestoreWrapper.query('materials')
        .where('institutionId', isNull: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .handleError((e) => print('🔥 FIRESTORE INDEX NEEDED: $e'))
        .map((s) =>
            s.docs.map((d) => TeachingMaterial.fromFirestore(d)).toList());

    if (institutionIds.isEmpty) return publicStream;

    // Institution-specific materials (whereIn supports up to 10 values)
    final instStream = FirestoreWrapper.query('materials')
        .where('institutionId', whereIn: institutionIds.take(10).toList())
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .handleError((e) => print('🔥 FIRESTORE INDEX NEEDED: $e'))
        .map((s) =>
            s.docs.map((d) => TeachingMaterial.fromFirestore(d)).toList());

    // Combine both streams
    return publicStream.asyncExpand((pub) => instStream.map((inst) {
          final all = [...pub, ...inst];
          all.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return all;
        }));
  }

  // Get materials by category
  Stream<List<TeachingMaterial>> getMaterialsByCategory(
      MaterialCategory category) {
    Query query = FirestoreWrapper.query('materials')
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('uploadedAt', descending: true);

    return FirestoreWrapper.getCollectionStream(
            query, 'Materials by category ${category.toString()}')
        .map((snapshot) => snapshot.docs
            .map((doc) => TeachingMaterial.fromFirestore(doc))
            .toList());
  }

  // Search materials
  Stream<List<TeachingMaterial>> searchMaterials({
    MaterialCategory? category,
    List<TeachingLevel>? levels,
    String? searchTerm,
  }) {
    Query query = FirestoreWrapper.query('materials');

    if (category != null) {
      query = query.where('category',
          isEqualTo: category.toString().split('.').last);
    }

    return query
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .handleError((error, stackTrace) {
      print('Error searching materials: $error');
      print('Stack trace: $stackTrace');
    }).map((snapshot) {
      List<TeachingMaterial> materials = snapshot.docs
          .map((doc) => TeachingMaterial.fromFirestore(doc))
          .toList();

      // Filter by levels in-memory
      if (levels != null && levels.isNotEmpty) {
        materials = materials
            .where((material) =>
                material.suitableFor.any((level) => levels.contains(level)))
            .toList();
      }

      // Filter by search term
      if (searchTerm != null && searchTerm.isNotEmpty) {
        String lowerSearch = searchTerm.toLowerCase();
        materials = materials
            .where((material) =>
                material.title.toLowerCase().contains(lowerSearch) ||
                material.description.toLowerCase().contains(lowerSearch) ||
                material.tags
                    .any((tag) => tag.toLowerCase().contains(lowerSearch)))
            .toList();
      }

      return materials;
    });
  }

  // Get materials uploaded by a specific user
  Stream<List<TeachingMaterial>> getMaterialsByUser(String uid) {
    Query query = FirestoreWrapper.query('materials')
        .where('uploadedBy', isEqualTo: uid)
        .orderBy('uploadedAt', descending: true);

    return FirestoreWrapper.getCollectionStream(query, 'Materials by user $uid')
        .map((snapshot) => snapshot.docs
            .map((doc) => TeachingMaterial.fromFirestore(doc))
            .toList());
  }

  // Increment download count
  Future<void> incrementDownloadCount(String materialId) async {
    try {
      await FirestoreWrapper.updateDocument('materials', materialId, {
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      print('Error incrementing download count: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Delete material
  Future<void> deleteMaterial(String materialId) async {
    try {
      await FirestoreWrapper.deleteDocument('materials', materialId);
    } catch (e, stackTrace) {
      print('Error deleting material: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Update material
  Future<void> updateMaterial(
      String materialId, Map<String, dynamic> updates) async {
    try {
      await FirestoreWrapper.updateDocument('materials', materialId, updates);
    } catch (e, stackTrace) {
      print('Error updating material: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get popular materials (most downloaded)
  Stream<List<TeachingMaterial>> getPopularMaterials({int limit = 10}) {
    Query query = FirestoreWrapper.query('materials')
        .orderBy('downloadCount', descending: true)
        .limit(limit);

    return FirestoreWrapper.getCollectionStream(query, 'Popular materials').map(
        (snapshot) => snapshot.docs
            .map((doc) => TeachingMaterial.fromFirestore(doc))
            .toList());
  }

  // Get recent materials
  Stream<List<TeachingMaterial>> getRecentMaterials({int limit = 10}) {
    Query query = FirestoreWrapper.query('materials')
        .orderBy('uploadedAt', descending: true)
        .limit(limit);

    return FirestoreWrapper.getCollectionStream(query, 'Recent materials').map(
        (snapshot) => snapshot.docs
            .map((doc) => TeachingMaterial.fromFirestore(doc))
            .toList());
  }
}
