import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { teacher, institution, admin }

class AppUser {
  final String uid;
  final String email;
  final UserType userType;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isVerified;
  
  AppUser({
    required this.uid,
    required this.email,
    required this.userType,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.isVerified = false,
  });
  
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${data['userType']}',
        orElse: () => UserType.teacher,
      ),
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'userType': userType.toString().split('.').last,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
    };
  }
}
