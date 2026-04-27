import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String name;
  final String? email;
  final String? phone;

  const Student({required this.name, this.email, this.phone});

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        name: map['name'] ?? '',
        email: map['email'],
        phone: map['phone'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
      };
}

class ClassGroup {
  final String id;
  final String teacherId;
  final String name;
  final String? description;
  final List<Student> students;
  final DateTime createdAt;

  const ClassGroup({
    required this.id,
    required this.teacherId,
    required this.name,
    this.description,
    required this.students,
    required this.createdAt,
  });

  factory ClassGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassGroup(
      id: doc.id,
      teacherId: data['teacherId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      students: (data['students'] as List<dynamic>? ?? [])
          .map((s) => Student.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'teacherId': teacherId,
        'name': name,
        'description': description,
        'students': students.map((s) => s.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
