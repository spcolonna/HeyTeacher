import 'package:cloud_firestore/cloud_firestore.dart';

class ClassMeeting {
  final String id;
  final String groupId;
  final String teacherId;
  final String title;
  final String meetLink;
  final String? calendarEventId;
  final DateTime scheduledAt;
  final DateTime createdAt;

  const ClassMeeting({
    required this.id,
    required this.groupId,
    required this.teacherId,
    required this.title,
    required this.meetLink,
    this.calendarEventId,
    required this.scheduledAt,
    required this.createdAt,
  });

  factory ClassMeeting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassMeeting(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      title: data['title'] ?? '',
      meetLink: data['meetLink'] ?? '',
      calendarEventId: data['calendarEventId'],
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'teacherId': teacherId,
        'title': title,
        'meetLink': meetLink,
        'calendarEventId': calendarEventId,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
