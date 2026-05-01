import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffStatus { pending, accepted, rejected, removed }

class InstitutionStaff {
  final String id;
  final String institutionId;
  final String institutionName;
  final String teacherId;
  final String teacherEmail;
  final String teacherName;
  final String? teacherPhotoUrl;
  final StaffStatus status;
  final List<String> levels;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final DateTime? removedAt;
  final int? removalRating;
  final String? removalComment;
  final String? removalReason;

  InstitutionStaff({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.teacherId,
    required this.teacherEmail,
    required this.teacherName,
    this.teacherPhotoUrl,
    required this.status,
    this.levels = const [],
    required this.requestedAt,
    this.respondedAt,
    this.removedAt,
    this.removalRating,
    this.removalComment,
    this.removalReason,
  });

  factory InstitutionStaff.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InstitutionStaff(
      id: doc.id,
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherEmail: data['teacherEmail'] ?? '',
      teacherName: data['teacherName'] ?? '',
      teacherPhotoUrl: data['teacherPhotoUrl'],
      status: StaffStatus.values.firstWhere(
        (s) => s.toString().split('.').last == data['status'],
        orElse: () => StaffStatus.pending,
      ),
      levels: List<String>.from(data['levels'] ?? []),
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      removedAt: data['removedAt'] != null
          ? (data['removedAt'] as Timestamp).toDate()
          : null,
      removalRating: data['removalRating'],
      removalComment: data['removalComment'],
      removalReason: data['removalReason'],
    );
  }

  Map<String, dynamic> toMap() => {
        'institutionId': institutionId,
        'institutionName': institutionName,
        'teacherId': teacherId,
        'teacherEmail': teacherEmail,
        'teacherName': teacherName,
        'teacherPhotoUrl': teacherPhotoUrl,
        'status': status.toString().split('.').last,
        'levels': levels,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'respondedAt':
            respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
        'removedAt': removedAt != null ? Timestamp.fromDate(removedAt!) : null,
        'removalRating': removalRating,
        'removalComment': removalComment,
        'removalReason': removalReason,
      };
}
