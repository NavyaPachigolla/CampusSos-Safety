import 'package:cloud_firestore/cloud_firestore.dart';

class TrustedContact {
  final String id;
  final String ownerUid;
  final String name;
  final String phone;
  final String relationship;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TrustedContact({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.phone,
    required this.relationship,
    this.createdAt,
    this.updatedAt,
  });

  factory TrustedContact.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TrustedContact(
      id: id,
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      relationship: data['relationship'] as String? ?? 'Friend',
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  factory TrustedContact.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return TrustedContact.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toInitialMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TrustedContact copyWith({
    String? name,
    String? phone,
    String? relationship,
  }) {
    return TrustedContact(
      id: id,
      ownerUid: ownerUid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
