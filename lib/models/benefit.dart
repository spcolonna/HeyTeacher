import 'package:cloud_firestore/cloud_firestore.dart';

enum BenefitCategory {
  learningMaterials,
  institutions,
  lifestyle,
  shopping,
}

class Benefit {
  final String id;
  final String sponsorName;
  final String sponsorLogo; // URL de la imagen del logo
  final String title;
  final String description;
  final String discount; // ej: "20% OFF", "1 mes gratis"
  final BenefitCategory category;
  final DateTime validUntil;
  final bool isActive;
  final String? termsAndConditions;
  final String? websiteUrl;

  Benefit({
    required this.id,
    required this.sponsorName,
    required this.sponsorLogo,
    required this.title,
    required this.description,
    required this.discount,
    required this.category,
    required this.validUntil,
    this.isActive = true,
    this.termsAndConditions,
    this.websiteUrl,
  });

  factory Benefit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Benefit(
      id: doc.id,
      sponsorName: data['sponsorName'] ?? '',
      sponsorLogo: data['sponsorLogo'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discount: data['discount'] ?? '',
      category: BenefitCategory.values.firstWhere(
        (e) => e.toString() == 'BenefitCategory.${data['category']}',
        orElse: () => BenefitCategory.lifestyle,
      ),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      termsAndConditions: data['termsAndConditions'],
      websiteUrl: data['websiteUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sponsorName': sponsorName,
      'sponsorLogo': sponsorLogo,
      'title': title,
      'description': description,
      'discount': discount,
      'category': category.toString().split('.').last,
      'validUntil': Timestamp.fromDate(validUntil),
      'isActive': isActive,
      'termsAndConditions': termsAndConditions,
      'websiteUrl': websiteUrl,
    };
  }

  bool get isExpired => DateTime.now().isAfter(validUntil);

  String getCategoryLabel() {
    switch (category) {
      case BenefitCategory.learningMaterials:
        return 'Learning Materials';
      case BenefitCategory.institutions:
        return 'Institutions';
      case BenefitCategory.lifestyle:
        return 'Lifestyle';
      case BenefitCategory.shopping:
        return 'Shopping';
    }
  }
}
