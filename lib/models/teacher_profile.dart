import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificationType { fce, cae, cpe, tesol, tefl, celta, delta, other }

enum AvailabilityShift { morning, afternoon, evening }

enum TeachingLevel { kinder, primary, secondary, adult }

class TeacherProfile {
  final String uid;
  final String fullName;
  final String? phone;
  final String? bio;
  final List<CertificationType> certifications;
  final List<String> certificationFiles; // URLs from Firebase Storage
  final List<AvailabilityShift> availability;
  final List<TeachingLevel> preferredLevels;
  final String? cvUrl;
  final int yearsOfExperience;
  final String? location; // Geographic zone
  final DateTime updatedAt;
  
  TeacherProfile({
    required this.uid,
    required this.fullName,
    this.phone,
    this.bio,
    this.certifications = const [],
    this.certificationFiles = const [],
    this.availability = const [],
    this.preferredLevels = const [],
    this.cvUrl,
    this.yearsOfExperience = 0,
    this.location,
    required this.updatedAt,
  });
  
  factory TeacherProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeacherProfile(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      phone: data['phone'],
      bio: data['bio'],
      certifications: (data['certifications'] as List<dynamic>?)
          ?.map((e) => CertificationType.values.firstWhere(
                (cert) => cert.toString() == 'CertificationType.$e',
                orElse: () => CertificationType.other,
              ))
          .toList() ?? [],
      certificationFiles: List<String>.from(data['certificationFiles'] ?? []),
      availability: (data['availability'] as List<dynamic>?)
          ?.map((e) => AvailabilityShift.values.firstWhere(
                (shift) => shift.toString() == 'AvailabilityShift.$e',
                orElse: () => AvailabilityShift.morning,
              ))
          .toList() ?? [],
      preferredLevels: (data['preferredLevels'] as List<dynamic>?)
          ?.map((e) => TeachingLevel.values.firstWhere(
                (level) => level.toString() == 'TeachingLevel.$e',
                orElse: () => TeachingLevel.primary,
              ))
          .toList() ?? [],
      cvUrl: data['cvUrl'],
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      location: data['location'],
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'bio': bio,
      'certifications': certifications.map((e) => e.toString().split('.').last).toList(),
      'certificationFiles': certificationFiles,
      'availability': availability.map((e) => e.toString().split('.').last).toList(),
      'preferredLevels': preferredLevels.map((e) => e.toString().split('.').last).toList(),
      'cvUrl': cvUrl,
      'yearsOfExperience': yearsOfExperience,
      'location': location,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
