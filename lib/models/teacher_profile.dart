import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificationType { fce, cae, cpe, tesol, tefl, celta, delta, other }

enum AvailabilityShift { morning, afternoon, evening }

enum TeachingLevel { kinder, primary, secondary, adult }

class TeacherProfile {
  final String uid;
  final String fullName;
  final String? phone;
  final String? bio;
  final String? linkedinUrl;
  final bool nativeSpeaker;
  final List<CertificationType> certifications;
  final List<String> certificationFiles;
  final List<String> certificationNames;
  final List<String> teachingMethodologies;
  final List<AvailabilityShift> availability;
  final List<TeachingLevel> preferredLevels;
  final String? cvUrl;
  final int yearsOfExperience;
  final String? location;
  final String? photoUrl;
  final DateTime updatedAt;

  TeacherProfile({
    required this.uid,
    required this.fullName,
    this.phone,
    this.bio,
    this.linkedinUrl,
    this.nativeSpeaker = false,
    this.certifications = const [],
    this.certificationFiles = const [],
    this.certificationNames = const [],
    this.teachingMethodologies = const [],
    this.availability = const [],
    this.preferredLevels = const [],
    this.cvUrl,
    this.yearsOfExperience = 0,
    this.location,
    this.photoUrl,
    required this.updatedAt,
  });

  factory TeacherProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final files = List<String>.from(data['certificationFiles'] ?? []);
    final names = List<String>.from(data['certificationNames'] ?? []);
    // Ensure names array is same length as files (pad with empty strings)
    while (names.length < files.length) { names.add(''); }

    return TeacherProfile(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      phone: data['phone'],
      bio: data['bio'],
      linkedinUrl: data['linkedinUrl'],
      nativeSpeaker: data['nativeSpeaker'] ?? false,
      certifications: (data['certifications'] as List<dynamic>?)
              ?.map((e) => CertificationType.values.firstWhere(
                    (cert) => cert.toString() == 'CertificationType.$e',
                    orElse: () => CertificationType.other,
                  ))
              .toList() ??
          [],
      certificationFiles: files,
      certificationNames: names,
      teachingMethodologies:
          List<String>.from(data['teachingMethodologies'] ?? []),
      availability: (data['availability'] as List<dynamic>?)
              ?.map((e) => AvailabilityShift.values.firstWhere(
                    (shift) => shift.toString() == 'AvailabilityShift.$e',
                    orElse: () => AvailabilityShift.morning,
                  ))
              .toList() ??
          [],
      preferredLevels: (data['preferredLevels'] as List<dynamic>?)
              ?.map((e) => TeachingLevel.values.firstWhere(
                    (level) => level.toString() == 'TeachingLevel.$e',
                    orElse: () => TeachingLevel.primary,
                  ))
              .toList() ??
          [],
      cvUrl: data['cvUrl'],
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      location: data['location'],
      photoUrl: data['photoUrl'],
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'bio': bio,
        'linkedinUrl': linkedinUrl,
        'nativeSpeaker': nativeSpeaker,
        'certifications':
            certifications.map((e) => e.toString().split('.').last).toList(),
        'certificationFiles': certificationFiles,
        'certificationNames': certificationNames,
        'teachingMethodologies': teachingMethodologies,
        'availability':
            availability.map((e) => e.toString().split('.').last).toList(),
        'preferredLevels':
            preferredLevels.map((e) => e.toString().split('.').last).toList(),
        'cvUrl': cvUrl,
        'yearsOfExperience': yearsOfExperience,
        'location': location,
        'photoUrl': photoUrl,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
