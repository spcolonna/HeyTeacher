import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { pending, reviewed, accepted, rejected }

class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String institutionName;
  final String teacherId;
  final String teacherName;
  final String? teacherEmail;
  final String? cvUrl;
  final String? coverLetter;
  final DateTime appliedAt;
  final ApplicationStatus status;
  final String? institutionNotes;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.institutionName,
    required this.teacherId,
    required this.teacherName,
    this.teacherEmail,
    this.cvUrl,
    this.coverLetter,
    required this.appliedAt,
    this.status = ApplicationStatus.pending,
    this.institutionNotes,
  });

  factory JobApplication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JobApplication(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? 'Unknown Job',
      institutionName: data['institutionName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      teacherEmail: data['teacherEmail'],
      cvUrl: data['cvUrl'],
      coverLetter: data['coverLetter'],
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      status: ApplicationStatus.values.firstWhere(
        (e) => e.toString() == 'ApplicationStatus.${data['status']}',
        orElse: () => ApplicationStatus.pending,
      ),
      institutionNotes: data['institutionNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'institutionName': institutionName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherEmail': teacherEmail,
      'cvUrl': cvUrl,
      'coverLetter': coverLetter,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'status': status.toString().split('.').last,
      'institutionNotes': institutionNotes,
    };
  }
}
