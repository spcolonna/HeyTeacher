import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_group.dart';
import '../models/class_meeting.dart';

class ClassroomService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _groups => _db.collection('classGroups');
  CollectionReference get _meetings => _db.collection('classMeetings');

  // ── Groups ──────────────────────────────────────────────

  Stream<List<ClassGroup>> getGroupsForTeacher(String teacherId) {
    return _groups
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
      final groups =
          snap.docs.map((d) => ClassGroup.fromFirestore(d)).toList();
      groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return groups;
    });
  }

  Future<ClassGroup> createGroup({
    required String teacherId,
    required String name,
    String? description,
    List<Student> students = const [],
  }) async {
    final ref = await _groups.add(ClassGroup(
      id: '',
      teacherId: teacherId,
      name: name,
      description: description,
      students: students,
      createdAt: DateTime.now(),
    ).toMap());

    final doc = await ref.get();
    return ClassGroup.fromFirestore(doc);
  }

  Future<void> updateGroup(ClassGroup group) async {
    await _groups.doc(group.id).update(group.toMap());
  }

  Future<void> deleteGroup(String groupId) async {
    // Delete the group and all its meetings
    final batch = _db.batch();
    batch.delete(_groups.doc(groupId));

    final meetings = await _meetings
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in meetings.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ── Meetings ─────────────────────────────────────────────

  Stream<List<ClassMeeting>> getMeetingsForGroup(String groupId) {
    return _meetings
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snap) {
      final meetings =
          snap.docs.map((d) => ClassMeeting.fromFirestore(d)).toList();
      meetings.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return meetings;
    });
  }

  Future<ClassMeeting> createMeeting({
    required String groupId,
    required String teacherId,
    required String title,
    required String meetLink,
    String? calendarEventId,
    required DateTime scheduledAt,
  }) async {
    final ref = await _meetings.add(ClassMeeting(
      id: '',
      groupId: groupId,
      teacherId: teacherId,
      title: title,
      meetLink: meetLink,
      calendarEventId: calendarEventId,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
    ).toMap());

    final doc = await ref.get();
    return ClassMeeting.fromFirestore(doc);
  }

  Future<void> deleteMeeting(String meetingId) async {
    await _meetings.doc(meetingId).delete();
  }
}
