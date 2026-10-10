import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/safety_session.dart';
import 'location_service.dart';

class SafetySessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('safety_sessions');

  /// Start a new safe arrival journey
  Future<SafetySession> startSession({
    required String ownerUid,
    required String destination,
    required Duration estimatedDuration,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');
    if (destination.trim().isEmpty) {
      throw Exception('Destination cannot be empty');
    }

    final now = DateTime.now();
    final expectedArrival = now.add(estimatedDuration);

    // Capture starting GPS coordinates if available
    final locResult = await _locationService.getCurrentLocation();

    final session = SafetySession(
      id: '',
      ownerUid: ownerUid,
      destination: destination.trim(),
      startTime: now,
      expectedArrival: expectedArrival,
      status: 'active',
      latitude: locResult.latitude,
      longitude: locResult.longitude,
    );

    final docRef = await _collection.add(session.toInitialMap());

    return SafetySession(
      id: docRef.id,
      ownerUid: ownerUid,
      destination: session.destination,
      startTime: now,
      expectedArrival: expectedArrival,
      status: 'active',
      latitude: session.latitude,
      longitude: session.longitude,
      createdAt: now,
    );
  }

  /// Mark session as arrived safely
  Future<void> checkInSafely({
    required String sessionId,
    required String ownerUid,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');

    final doc = await _collection.doc(sessionId).get();
    if (!doc.exists) return;
    if (doc.data()?['ownerUid'] != ownerUid) {
      throw Exception('Unauthorized: You cannot update another user\'s session');
    }

    await _collection.doc(sessionId).update({
      'status': 'arrived',
      'actualArrival': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel an ongoing journey
  Future<void> cancelSession({
    required String sessionId,
    required String ownerUid,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');

    final doc = await _collection.doc(sessionId).get();
    if (!doc.exists) return;
    if (doc.data()?['ownerUid'] != ownerUid) {
      throw Exception('Unauthorized: You cannot update another user\'s session');
    }

    await _collection.doc(sessionId).update({
      'status': 'cancelled',
      'actualArrival': FieldValue.serverTimestamp(),
    });
  }

  /// Update status to overdue if session has expired
  Future<void> markOverdue({
    required String sessionId,
    required String ownerUid,
  }) async {
    if (ownerUid.isEmpty) return;

    await _collection.doc(sessionId).update({
      'status': 'overdue',
    });
  }

  /// Stream current active session for the authenticated user
  Stream<SafetySession?> getActiveSessionStream(String ownerUid) {
    if (ownerUid.isEmpty) return Stream.value(null);

    return _collection
        .where('ownerUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SafetySession.fromFirestore(snapshot.docs.first);
    });
  }

  /// Stream journey history (completed, cancelled, or overdue)
  Stream<List<SafetySession>> getSessionHistoryStream(String ownerUid) {
    if (ownerUid.isEmpty) return Stream.value([]);

    return _collection
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SafetySession.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    });
  }
}
