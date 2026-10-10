import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_alert.dart';
import 'location_service.dart';

class AlertResult {
  final EmergencyAlert alert;
  final bool isStoredInFirestore;
  final String deliveryNotice;

  const AlertResult({
    required this.alert,
    required this.isStoredInFirestore,
    required this.deliveryNotice,
  });
}

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('emergency_alerts');

  /// Trigger emergency SOS alert:
  /// 1. Reads current GPS coordinates if permissions are granted
  /// 2. Saves incident record into Firestore
  /// 3. Returns alert result with clear status distinction
  Future<AlertResult> triggerSosAlert({
    required String ownerUid,
    required String studentName,
    String? customMessage,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');

    // Attempt to obtain location safely
    final locationResult = await _locationService.getCurrentLocation();
    final lat = locationResult.latitude;
    final lng = locationResult.longitude;

    String mapsLink = '';
    if (lat != null && lng != null) {
      mapsLink = LocationService.makeMapsUrl(lat, lng);
    }

    final messageText = customMessage ??
        'EMERGENCY SOS: $studentName needs urgent assistance on campus! '
            '${mapsLink.isNotEmpty ? "Current GPS location: $mapsLink" : "Location unavailable."}';

    final alertDoc = {
      'ownerUid': ownerUid,
      'alertType': 'SOS Panic',
      'message': messageText,
      'latitude': lat,
      'longitude': lng,
      'status': 'created', // Local/Firestore record status
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    };

    final docRef = await _collection.add(alertDoc);

    final alert = EmergencyAlert(
      id: docRef.id,
      ownerUid: ownerUid,
      alertType: 'SOS Panic',
      message: messageText,
      latitude: lat,
      longitude: lng,
      status: 'created',
      createdAt: DateTime.now(),
    );

    return AlertResult(
      alert: alert,
      isStoredInFirestore: true,
      deliveryNotice:
          'Alert incident logged securely to Firestore. Remote automated carrier SMS delivery requires an external backend gateway. Please use Call or Broadcast buttons below to notify contacts directly.',
    );
  }

  /// Stream alert history for the current user
  Stream<List<EmergencyAlert>> getAlertsStream(String ownerUid) {
    if (ownerUid.isEmpty) return Stream.value([]);

    return _collection
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => EmergencyAlert.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Mark an active alert as resolved
  Future<void> resolveAlert({
    required String alertId,
    required String ownerUid,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');

    final doc = await _collection.doc(alertId).get();
    if (!doc.exists) return;
    if (doc.data()?['ownerUid'] != ownerUid) {
      throw Exception('Unauthorized: You cannot modify another user\'s alert');
    }

    await _collection.doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Dial an emergency telephone number
  Future<bool> callEmergencyPhone(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      debugPrint('Failed to launch phone dialer: $e');
      return false;
    }
  }

  /// Launch SMS composer with pre-filled emergency message
  Future<bool> sendEmergencySms(String phoneNumber, String message) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$cleanNumber?body=$encodedMessage');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      debugPrint('Failed to launch SMS composer: $e');
      return false;
    }
  }

  /// Broadcast emergency message via native share sheet (WhatsApp, Telegram, etc.)
  Future<void> shareEmergencyMessage({
    required String message,
    String? subject,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: subject ?? 'CAMPUS EMERGENCY SOS',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing emergency message: $e');
    }
  }
}
