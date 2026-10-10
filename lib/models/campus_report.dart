import 'package:cloud_firestore/cloud_firestore.dart';

class CampusReport {
  final String id;
  final String reporterUid;
  final String category;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String status; // submitted, under_review, resolved
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CampusReport({
    required this.id,
    required this.reporterUid,
    required this.category,
    required this.description,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.status = 'submitted',
    this.createdAt,
    this.updatedAt,
  });

  String get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return '';
  }

  factory CampusReport.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double? parseCoord(dynamic val) {
      if (val is num) return val.toDouble();
      return null;
    }

    return CampusReport(
      id: id,
      reporterUid: data['reporterUid'] as String? ?? '',
      category: data['category'] as String? ?? 'Hazard',
      description: data['description'] as String? ?? '',
      latitude: parseCoord(data['latitude']),
      longitude: parseCoord(data['longitude']),
      photoUrl: data['photoUrl'] as String?,
      status: data['status'] as String? ?? 'submitted',
      createdAt: parseTime(data['createdAt']),
      updatedAt: parseTime(data['updatedAt']),
    );
  }

  factory CampusReport.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return CampusReport.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toInitialMap() {
    return {
      'reporterUid': reporterUid,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'status': 'submitted', // Student submissions always start as submitted
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
