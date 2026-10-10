import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String college;
  final String role;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.college,
    this.role = 'student',
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AppUser(
      uid: id,
      name: data['name'] as String? ?? 'Student',
      email: data['email'] as String? ?? '',
      college: data['college'] as String? ?? 'Campus',
      role: data['role'] as String? ?? 'student',
      phone: data['phone'] as String?,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'college': college,
      'role': role,
      if (phone != null) 'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toInitialMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'college': college,
      'role': 'student', // Always default to student
      if (phone != null) 'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? name,
    String? college,
    String? phone,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      college: college ?? this.college,
      role: role,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
