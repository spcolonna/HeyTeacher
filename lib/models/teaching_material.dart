import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_profile.dart';

enum MaterialCategory { lessonPlan, flashcard, icebreaker, worksheet, digitalTool, other }

class TeachingMaterial {
  final String id;
  final String title;
  final String description;
  final MaterialCategory category;
  final List<TeachingLevel> suitableFor;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String uploadedBy; // UID
  final String uploaderName;
  final DateTime uploadedAt;
  final int downloadCount;
  final List<String> tags;
  final String? institutionId;   // null = public (teacher-uploaded)
  final String? institutionName; // denormalized for display

  TeachingMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.suitableFor = const [],
    this.fileUrl,
    this.thumbnailUrl,
    required this.uploadedBy,
    required this.uploaderName,
    required this.uploadedAt,
    this.downloadCount = 0,
    this.tags = const [],
    this.institutionId,
    this.institutionName,
  });
  
  factory TeachingMaterial.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeachingMaterial(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: MaterialCategory.values.firstWhere(
        (e) => e.toString() == 'MaterialCategory.${data['category']}',
        orElse: () => MaterialCategory.other,
      ),
      suitableFor: (data['suitableFor'] as List<dynamic>?)
          ?.map((e) => TeachingLevel.values.firstWhere(
                (level) => level.toString() == 'TeachingLevel.$e',
                orElse: () => TeachingLevel.primary,
              ))
          .toList() ?? [],
      fileUrl: data['fileUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      uploadedBy: data['uploadedBy'] ?? '',
      uploaderName: data['uploaderName'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      downloadCount: data['downloadCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      institutionId: data['institutionId'],
      institutionName: data['institutionName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'suitableFor': suitableFor.map((e) => e.toString().split('.').last).toList(),
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'downloadCount': downloadCount,
      'tags': tags,
      'institutionId': institutionId,
      'institutionName': institutionName,
    };
  }
}
