import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/institution_staff.dart';
import 'notification_service.dart';

class StaffService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Returns an existing staff doc ID for the pair, or null
  Future<String?> _existingDocId(
      String institutionId, String teacherId) async {
    final snap = await _db
        .collection('institution_staff')
        .where('institutionId', isEqualTo: institutionId)
        .where('teacherId', isEqualTo: teacherId)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  // Send (or re-send) a staff request
  // Searches for teacher by email in `users` collection.
  // Returns null on success, or an error string.
  Future<String?> sendRequest({
    required String institutionId,
    required String institutionName,
    required String teacherEmail,
  }) async {
    try {
      // Find teacher user by email
      final userSnap = await _db
          .collection('users')
          .where('email', isEqualTo: teacherEmail.trim().toLowerCase())
          .where('userType', isEqualTo: 'teacher')
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) {
        return 'No teacher found with that email.';
      }

      final teacherDoc = userSnap.docs.first;
      final teacherId = teacherDoc.id;
      final teacherData = teacherDoc.data();
      final teacherName = teacherData['displayName'] ?? '';
      final teacherPhotoUrl = teacherData['photoUrl'];

      // Check if record already exists
      final existingId = await _existingDocId(institutionId, teacherId);

      if (existingId != null) {
        // Re-send: update to pending regardless of previous status
        await _db.collection('institution_staff').doc(existingId).update({
          'status': 'pending',
          'requestedAt': Timestamp.now(),
          'respondedAt': null,
        });
      } else {
        // Create new record
        final staff = InstitutionStaff(
          id: '',
          institutionId: institutionId,
          institutionName: institutionName,
          teacherId: teacherId,
          teacherEmail: teacherEmail.trim().toLowerCase(),
          teacherName: teacherName,
          teacherPhotoUrl: teacherPhotoUrl,
          status: StaffStatus.pending,
          requestedAt: DateTime.now(),
        );
        await _db.collection('institution_staff').add(staff.toMap());
      }

      // Notify teacher
      await NotificationService().createNotification(
        userId: teacherId,
        title: 'New staff request',
        body: '$institutionName wants you to join their staff',
        type: 'staff_request',
      );

      return null;
    } catch (e) {
      print('🔥 sendRequest error: $e');
      return 'Error: $e';
    }
  }

  Stream<List<InstitutionStaff>> getStaffForInstitution(String institutionId) {
    return _db
        .collection('institution_staff')
        .where('institutionId', isEqualTo: institutionId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => InstitutionStaff.fromFirestore(d)).toList());
  }

  Stream<List<InstitutionStaff>> getInstitutionsForTeacher(String teacherId) {
    return _db
        .collection('institution_staff')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => InstitutionStaff.fromFirestore(d)).toList());
  }

  Future<void> respondToRequest(String docId, bool accepted) async {
    await _db.collection('institution_staff').doc(docId).update({
      'status': accepted ? 'accepted' : 'rejected',
      'respondedAt': Timestamp.now(),
    });
  }

  Future<void> cancelRequest(String docId) async {
    await _db.collection('institution_staff').doc(docId).delete();
  }

  Future<void> removeStaff({
    required String docId,
    required int rating,
    required String comment,
    required String reason,
  }) async {
    await _db.collection('institution_staff').doc(docId).update({
      'status': 'removed',
      'removedAt': Timestamp.now(),
      'removalRating': rating,
      'removalComment': comment.trim().isEmpty ? null : comment.trim(),
      'removalReason': reason,
    });
  }

  Future<void> updateStaffLevels(String docId, List<String> levels) async {
    await _db
        .collection('institution_staff')
        .doc(docId)
        .update({'levels': levels});
  }

  // Returns completed staff records with ratings (for clearing)
  Future<List<InstitutionStaff>> getTeacherClearing(String teacherId) async {
    final snap = await _db
        .collection('institution_staff')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', isEqualTo: 'removed')
        .orderBy('removedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => InstitutionStaff.fromFirestore(d))
        .where((s) => s.removalRating != null)
        .toList();
  }
}
