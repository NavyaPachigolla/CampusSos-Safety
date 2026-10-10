import 'package:cloud_firestore/cloud_firestore.dart';

class CampusContact {
  final String id;
  final String name;
  final String category;
  final String phone;
  final String locationDescription;
  final bool isActive;

  const CampusContact({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.locationDescription,
    this.isActive = true,
  });

  factory CampusContact.fromMap(Map<String, dynamic> data, String id) {
    return CampusContact(
      id: id,
      name: data['name'] as String? ?? 'Campus Authority',
      category: data['category'] as String? ?? 'Security',
      phone: data['phone'] as String? ?? '100',
      locationDescription:
          data['locationDescription'] as String? ?? 'Campus Main Office',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  factory CampusContact.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return CampusContact.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'phone': phone,
      'locationDescription': locationDescription,
      'isActive': isActive,
    };
  }
}
