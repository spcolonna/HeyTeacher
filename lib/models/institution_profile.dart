import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionProfile {
  final String uid;
  final String institutionName;
  final String? description;
  final String? address;
  final String? phone;
  final String? website;
  final String? logoUrl;
  final String? contactPersonName;
  final String? contactPersonEmail;
  final DateTime createdAt;
  
  InstitutionProfile({
    required this.uid,
    required this.institutionName,
    this.description,
    this.address,
    this.phone,
    this.website,
    this.logoUrl,
    this.contactPersonName,
    this.contactPersonEmail,
    required this.createdAt,
  });
  
  factory InstitutionProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InstitutionProfile(
      uid: doc.id,
      institutionName: data['institutionName'] ?? '',
      description: data['description'],
      address: data['address'],
      phone: data['phone'],
      website: data['website'],
      logoUrl: data['logoUrl'],
      contactPersonName: data['contactPersonName'],
      contactPersonEmail: data['contactPersonEmail'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'institutionName': institutionName,
      'description': description,
      'address': address,
      'phone': phone,
      'website': website,
      'logoUrl': logoUrl,
      'contactPersonName': contactPersonName,
      'contactPersonEmail': contactPersonEmail,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
