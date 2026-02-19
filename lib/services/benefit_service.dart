import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/benefit.dart';
import 'firestore_wrapper.dart';

class BenefitService {
  // Get all active benefits
  Stream<List<Benefit>> getAllBenefits() {
    Query query = FirestoreWrapper.query('benefits')
        .where('isActive', isEqualTo: true)
        .orderBy('validUntil', descending: false);

    return FirestoreWrapper.getCollectionStream(query, 'All benefits').map(
        (snapshot) => snapshot.docs
            .map((doc) => Benefit.fromFirestore(doc))
            .where((benefit) => !benefit.isExpired)
            .toList());
  }

  // Get benefits by category
  Stream<List<Benefit>> getBenefitsByCategory(BenefitCategory category) {
    Query query = FirestoreWrapper.query('benefits')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('validUntil', descending: false);

    return FirestoreWrapper.getCollectionStream(query, 'Benefits by category')
        .map((snapshot) => snapshot.docs
            .map((doc) => Benefit.fromFirestore(doc))
            .where((benefit) => !benefit.isExpired)
            .toList());
  }

  // Get featured benefits (for banner)
  Stream<List<Benefit>> getFeaturedBenefits({int limit = 5}) {
    Query query = FirestoreWrapper.query('benefits')
        .where('isActive', isEqualTo: true)
        .orderBy('validUntil', descending: false)
        .limit(limit);

    return FirestoreWrapper.getCollectionStream(query, 'Featured benefits').map(
        (snapshot) => snapshot.docs
            .map((doc) => Benefit.fromFirestore(doc))
            .where((benefit) => !benefit.isExpired)
            .toList());
  }

  // Create benefit (admin only - for now we'll add manually to Firestore)
  Future<String> createBenefit(Benefit benefit) async {
    try {
      DocumentReference docRef =
          await FirestoreWrapper.addDocument('benefits', benefit.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating benefit: $e');
      rethrow;
    }
  }
}
