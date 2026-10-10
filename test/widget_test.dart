import 'package:flutter_test/flutter_test.dart';
import 'package:campus_sos/models/app_user.dart';
import 'package:campus_sos/models/trusted_contact.dart';
import 'package:campus_sos/models/safety_session.dart';
import 'package:campus_sos/models/emergency_alert.dart';
import 'package:campus_sos/models/campus_report.dart';
import 'package:campus_sos/models/campus_contact.dart';

void main() {
  group('CampusSOS Data Models Test Suite', () {
    test('AppUser model serializes and defaults to student role', () {
      final user = AppUser(
        uid: 'user_123',
        name: 'Jane Doe',
        email: 'jane@campus.edu',
        college: 'State University',
      );

      expect(user.role, 'student');
      expect(user.name, 'Jane Doe');

      final initialMap = user.toInitialMap();
      expect(initialMap['uid'], 'user_123');
      expect(initialMap['role'], 'student');
      expect(initialMap['email'], 'jane@campus.edu');
    });

    test('TrustedContact model stores contact and owner details', () {
      final contact = TrustedContact(
        id: 'c_01',
        ownerUid: 'user_123',
        name: 'Alex Friend',
        phone: '+15551234567',
        relationship: 'Roommate',
      );

      final map = contact.toInitialMap();
      expect(map['ownerUid'], 'user_123');
      expect(map['name'], 'Alex Friend');
      expect(map['relationship'], 'Roommate');
    });

    test('SafetySession calculates duration and overdue status', () {
      final now = DateTime.now();
      final session = SafetySession(
        id: 's_01',
        ownerUid: 'user_123',
        destination: 'Library',
        startTime: now,
        expectedArrival: now.add(const Duration(minutes: 20)),
        status: 'active',
      );

      expect(session.isOverdue, false);
      expect(session.status, 'active');
      expect(session.destination, 'Library');

      final expiredSession = SafetySession(
        id: 's_02',
        ownerUid: 'user_123',
        destination: 'Hostel',
        startTime: now.subtract(const Duration(minutes: 30)),
        expectedArrival: now.subtract(const Duration(minutes: 10)),
        status: 'active',
      );

      expect(expiredSession.isOverdue, true);
    });

    test('EmergencyAlert creates Google Maps link correctly', () {
      final alert = EmergencyAlert(
        id: 'alert_01',
        ownerUid: 'user_123',
        alertType: 'SOS Panic',
        message: 'Assistance needed',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(alert.googleMapsUrl, contains('37.7749,-122.4194'));
    });

    test('CampusReport model initializes with submitted status', () {
      final report = CampusReport(
        id: 'rep_01',
        reporterUid: 'user_123',
        category: 'Broken Streetlight',
        description: 'Light pole #12 is flickering and dark',
        latitude: 12.9716,
        longitude: 77.5946,
      );

      final map = report.toInitialMap();
      expect(map['status'], 'submitted');
      expect(map['category'], 'Broken Streetlight');
      expect(report.googleMapsUrl, contains('12.9716,77.5946'));
    });

    test('CampusContact model deserializes directory resource', () {
      final contact = CampusContact(
        id: 'dir_01',
        name: 'Campus Security Control',
        category: 'Security',
        phone: '100',
        locationDescription: 'Main Gate',
        isActive: true,
      );

      final map = contact.toMap();
      expect(map['name'], 'Campus Security Control');
      expect(map['isActive'], true);
    });
  });
}
