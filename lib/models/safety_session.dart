import 'package:cloud_firestore/cloud_firestore.dart';

class SafetySession {
  final String id;
  final String ownerUid;
  final String destination;
  final DateTime startTime;
  final DateTime expectedArrival;
  final DateTime? actualArrival;
  final String status; // active, arrived, overdue, cancelled
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const SafetySession({
    required this.id,
    required this.ownerUid,
    required this.destination,
    required this.startTime,
    required this.expectedArrival,
    this.actualArrival,
    this.status = 'active',
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  bool get isOverdue {
    if (status != 'active') return false;
    return DateTime.now().isAfter(expectedArrival);
  }

  Duration get remainingDuration {
    final now = DateTime.now();
    if (now.isAfter(expectedArrival)) return Duration.zero;
    return expectedArrival.difference(now);
  }

  factory SafetySession.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTime(dynamic val, DateTime defaultTime) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return defaultTime;
    }

    DateTime? parseNullableTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final now = DateTime.now();
    final start = parseTime(data['startTime'], now);
    final expected = parseTime(
      data['expectedArrival'],
      now.add(const Duration(minutes: 30)),
    );

    double? parseCoord(dynamic val) {
      if (val is num) return val.toDouble();
      return null;
    }

    return SafetySession(
      id: id,
      ownerUid: data['ownerUid'] as String? ?? '',
      destination: data['destination'] as String? ?? 'Campus Location',
      startTime: start,
      expectedArrival: expected,
      actualArrival: parseNullableTime(data['actualArrival']),
      status: data['status'] as String? ?? 'active',
      latitude: parseCoord(data['latitude']),
      longitude: parseCoord(data['longitude']),
      createdAt: parseNullableTime(data['createdAt']),
    );
  }

  factory SafetySession.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return SafetySession.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toInitialMap() {
    return {
      'ownerUid': ownerUid,
      'destination': destination,
      'startTime': Timestamp.fromDate(startTime),
      'expectedArrival': Timestamp.fromDate(expectedArrival),
      'actualArrival': null,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toArrivalMap() {
    return {
      'status': 'arrived',
      'actualArrival': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCancelMap() {
    return {
      'status': 'cancelled',
      'actualArrival': FieldValue.serverTimestamp(),
    };
  }
}
