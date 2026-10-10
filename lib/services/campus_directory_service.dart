import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campus_contact.dart';

class CampusDirectoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('campus_contacts');

  /// Fallback verified default emergency contacts (clearly identified demo entries)
  static final List<CampusContact> fallbackContacts = [
    const CampusContact(
      id: 'default_sec_1',
      name: 'Campus Main Security Post',
      category: 'Security',
      phone: '+18005550199',
      locationDescription: 'Main Gate Control Room, Building A',
      isActive: true,
    ),
    const CampusContact(
      id: 'default_med_1',
      name: 'Campus Health & Medical Centre',
      category: 'Medical',
      phone: '+18005550198',
      locationDescription: 'Student Wellness Pavilion, Ground Floor',
      isActive: true,
    ),
    const CampusContact(
      id: 'default_hostel_1',
      name: 'Chief Hostel Warden (Emergency)',
      category: 'Hostel',
      phone: '+18005550197',
      locationDescription: 'Residential Quad Central Office',
      isActive: true,
    ),
    const CampusContact(
      id: 'default_women_1',
      name: 'Women\'s Safety Cell & Counseling',
      category: 'Support',
      phone: '+18005550196',
      locationDescription: 'Administration Block, Room 204',
      isActive: true,
    ),
    const CampusContact(
      id: 'default_police_1',
      name: 'Local Police Emergency Desk',
      category: 'Police',
      phone: '911',
      locationDescription: 'City District Sector 4 Police Station',
      isActive: true,
    ),
  ];

  /// Stream active campus contacts from Firestore
  /// Returns fallback default contacts if collection is empty or unreachable
  Stream<List<CampusContact>> getContactsStream() {
    return _collection.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return fallbackContacts;
      }
      final contacts = snapshot.docs
          .map((doc) => CampusContact.fromFirestore(doc))
          .where((c) => c.isActive)
          .toList();
      return contacts.isNotEmpty ? contacts : fallbackContacts;
    }).handleError((_) => fallbackContacts);
  }

  /// Helper to seed default campus contacts into Firestore (for first setup)
  Future<void> seedDefaultContactsIfEmpty() async {
    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        for (final contact in fallbackContacts) {
          await _collection.add(contact.toMap());
        }
      }
    } catch (_) {
      // Ignored if permissions restrict writing to campus_contacts
    }
  }
}
