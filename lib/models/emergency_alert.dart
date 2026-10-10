import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlert {
  final String id;
  final String ownerUid;
  final String alertType;
  final String message;
  final double? latitude;
  final double? longitude;
  final String status; // created, processing, sent, failed, resolved
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const EmergencyAlert({
    required this.id,
    required this.ownerUid,
    required this.alertType,
    required this.message,
    this.latitude,
    this.longitude,
    this.status = 'created',
    this.createdAt,
    this.resolvedAt,
  });

  String get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return '';
  }

  factory EmergencyAlert.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double? parseCoord(dynamic val) {
      if (val is num) return val.toDouble();
      return null;
    }

    return EmergencyAlert(
      id: id,
      ownerUid: data['ownerUid'] as String? ?? '',
      alertType: data['alertType'] as String? ?? 'SOS Panic',
      message: data['message'] as String? ?? 'Emergency assistance requested!',
      latitude: parseCoord(data['latitude']),
      longitude: parseCoord(data['longitude']),
      status: data['status'] as String? ?? 'created',
      createdAt: parseTime(data['createdAt']),
      resolvedAt: parseTime(data['resolvedAt']),
    );
  }

  factory EmergencyAlert.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return EmergencyAlert.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toInitialMap() {
    return {
      'ownerUid': ownerUid,
      'alertType': alertType,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    };
  }

  Map<String, dynamic> toResolveMap() {
    return {
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    };
  }
}
