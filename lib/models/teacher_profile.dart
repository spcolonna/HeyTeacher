import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificationType { fce, cae, cpe, tesol, tefl, celta, delta, other }

enum AvailabilityShift { morning, afternoon, evening }

enum TeachingLevel { kinder, primary, secondary, adult }

class WorkExperience {
  final String institutionName;
  final String role;
  final int startYear;
  final int startMonth;
  final int? endYear;
  final int? endMonth;
  final bool isCurrent;
  final String? description;

  WorkExperience({
    required this.institutionName,
    required this.role,
    required this.startYear,
    required this.startMonth,
    this.endYear,
    this.endMonth,
    this.isCurrent = false,
    this.description,
  });

  static const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmt(int year, int month) => '${monthNames[month - 1]} $year';

  String get dateRange {
    final start = _fmt(startYear, startMonth);
    final end = isCurrent
        ? 'Present'
        : (endYear != null && endMonth != null ? _fmt(endYear!, endMonth!) : '');
    return '$start – $end';
  }

  // Duration in months for display
  String get duration {
    final now = DateTime.now();
    final endY = isCurrent ? now.year : (endYear ?? now.year);
    final endM = isCurrent ? now.month : (endMonth ?? now.month);
    final months = (endY - startYear) * 12 + (endM - startMonth);
    if (months < 1) return '';
    final y = months ~/ 12;
    final m = months % 12;
    if (y == 0) return '${m}mo';
    if (m == 0) return '${y}yr';
    return '${y}yr ${m}mo';
  }

  factory WorkExperience.fromMap(Map<String, dynamic> data) {
    return WorkExperience(
      institutionName: data['institutionName'] ?? '',
      role: data['role'] ?? '',
      startYear: data['startYear'] ?? DateTime.now().year,
      startMonth: data['startMonth'] ?? 1,
      endYear: data['endYear'],
      endMonth: data['endMonth'],
      isCurrent: data['isCurrent'] ?? false,
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() => {
        'institutionName': institutionName,
        'role': role,
        'startYear': startYear,
        'startMonth': startMonth,
        if (endYear != null) 'endYear': endYear,
        if (endMonth != null) 'endMonth': endMonth,
        'isCurrent': isCurrent,
        if (description?.isNotEmpty == true) 'description': description,
      };
}

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
  final List<String> skills;
  final List<WorkExperience> workExperiences;
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
    this.skills = const [],
    this.workExperiences = const [],
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
      skills: List<String>.from(data['skills'] ?? []),
      workExperiences: (data['workExperiences'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromMap(e as Map<String, dynamic>))
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
        'skills': skills,
        'workExperiences': workExperiences.map((e) => e.toMap()).toList(),
        'cvUrl': cvUrl,
        'yearsOfExperience': yearsOfExperience,
        'location': location,
        'photoUrl': photoUrl,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
