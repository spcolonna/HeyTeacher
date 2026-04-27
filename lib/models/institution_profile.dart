import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionProfile {
  final String uid;
  final String institutionName;
  final String? rut;
  final String? institutionType;
  final String? description;
  final String? address;
  final String? phone;
  final String? website;
  final String? logoUrl;
  final String? contactPersonName;
  final String? contactPersonEmail;
  final String? instagramUrl;
  final String? facebookUrl;
  final DateTime createdAt;

  InstitutionProfile({
    required this.uid,
    required this.institutionName,
    this.rut,
    this.institutionType,
    this.description,
    this.address,
    this.phone,
    this.website,
    this.logoUrl,
    this.contactPersonName,
    this.contactPersonEmail,
    this.instagramUrl,
    this.facebookUrl,
    required this.createdAt,
  });

  factory InstitutionProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InstitutionProfile(
      uid: doc.id,
      institutionName: data['institutionName'] ?? '',
      rut: data['rut'],
      institutionType: data['institutionType'],
      description: data['description'],
      address: data['address'],
      phone: data['phone'],
      website: data['website'],
      logoUrl: data['logoUrl'],
      contactPersonName: data['contactPersonName'],
      contactPersonEmail: data['contactPersonEmail'],
      instagramUrl: data['instagramUrl'],
      facebookUrl: data['facebookUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionName': institutionName,
      'rut': rut,
      'institutionType': institutionType,
      'description': description,
      'address': address,
      'phone': phone,
      'website': website,
      'logoUrl': logoUrl,
      'contactPersonName': contactPersonName,
      'contactPersonEmail': contactPersonEmail,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
