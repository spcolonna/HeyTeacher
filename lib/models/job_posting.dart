import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_profile.dart';

enum JobStatus { active, filled, closed }

class JobPosting {
  final String id;
  final String postedBy; // UID of institution or teacher coordinator
  final String institutionName;
  final String jobTitle;
  final String description;
  final String location; // Geographic zone
  final List<AvailabilityShift> shifts;
  final List<TeachingLevel> levels;
  final List<CertificationType> requiredCertifications;
  final int? hoursPerWeek;
  final String? salaryRange;
  final DateTime postedAt;
  final DateTime? expiresAt;
  final JobStatus status;
  final int applicationsCount;
  
  JobPosting({
    required this.id,
    required this.postedBy,
    required this.institutionName,
    required this.jobTitle,
    required this.description,
    required this.location,
    required this.shifts,
    required this.levels,
    this.requiredCertifications = const [],
    this.hoursPerWeek,
    this.salaryRange,
    required this.postedAt,
    this.expiresAt,
    this.status = JobStatus.active,
    this.applicationsCount = 0,
  });
  
  factory JobPosting.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JobPosting(
      id: doc.id,
      postedBy: data['postedBy'] ?? '',
      institutionName: data['institutionName'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      shifts: (data['shifts'] as List<dynamic>?)
          ?.map((e) => AvailabilityShift.values.firstWhere(
                (shift) => shift.toString() == 'AvailabilityShift.$e',
                orElse: () => AvailabilityShift.morning,
              ))
          .toList() ?? [],
      levels: (data['levels'] as List<dynamic>?)
          ?.map((e) => TeachingLevel.values.firstWhere(
                (level) => level.toString() == 'TeachingLevel.$e',
                orElse: () => TeachingLevel.primary,
              ))
          .toList() ?? [],
      requiredCertifications: (data['requiredCertifications'] as List<dynamic>?)
          ?.map((e) => CertificationType.values.firstWhere(
                (cert) => cert.toString() == 'CertificationType.$e',
                orElse: () => CertificationType.other,
              ))
          .toList() ?? [],
      hoursPerWeek: data['hoursPerWeek'],
      salaryRange: data['salaryRange'],
      postedAt: (data['postedAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      status: JobStatus.values.firstWhere(
        (e) => e.toString() == 'JobStatus.${data['status']}',
        orElse: () => JobStatus.active,
      ),
      applicationsCount: data['applicationsCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'postedBy': postedBy,
      'institutionName': institutionName,
      'jobTitle': jobTitle,
      'description': description,
      'location': location,
      'shifts': shifts.map((e) => e.toString().split('.').last).toList(),
      'levels': levels.map((e) => e.toString().split('.').last).toList(),
      'requiredCertifications': requiredCertifications.map((e) => e.toString().split('.').last).toList(),
      'hoursPerWeek': hoursPerWeek,
      'salaryRange': salaryRange,
      'postedAt': Timestamp.fromDate(postedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'status': status.toString().split('.').last,
      'applicationsCount': applicationsCount,
    };
  }
}
