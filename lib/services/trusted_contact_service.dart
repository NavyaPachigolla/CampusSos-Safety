import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trusted_contact.dart';

class TrustedContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('trusted_contacts');

  /// Stream contacts owned strictly by the specified user UID
  Stream<List<TrustedContact>> getContactsStream(String ownerUid) {
    if (ownerUid.isEmpty) {
      return Stream.value([]);
    }

    return _collection
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TrustedContact.fromFirestore(doc))
          .toList();
      // Sort in-memory to prevent complex composite index requirements on Firestore
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Add a trusted contact for the authenticated user
  Future<String> addContact({
    required String ownerUid,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');
    if (name.trim().isEmpty) throw Exception('Contact name cannot be empty');
    if (phone.trim().isEmpty) throw Exception('Phone number cannot be empty');

    final contact = TrustedContact(
      id: '',
      ownerUid: ownerUid,
      name: name.trim(),
      phone: phone.trim(),
      relationship: relationship.trim(),
    );

    final docRef = await _collection.add(contact.toInitialMap());
    return docRef.id;
  }

  /// Update an existing contact, verifying user ownership
  Future<void> updateContact({
    required String contactId,
    required String ownerUid,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');

    final doc = await _collection.doc(contactId).get();
    if (!doc.exists) throw Exception('Contact not found');
    if (doc.data()?['ownerUid'] != ownerUid) {
      throw Exception('Unauthorized: You cannot edit another user\'s contact');
    }

    await _collection.doc(contactId).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'relationship': relationship.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a trusted contact, verifying user ownership
  Future<void> deleteContact({
    required String contactId,
    required String ownerUid,
  }) async {
    if (ownerUid.isEmpty) throw Exception('User not authenticated');

    final doc = await _collection.doc(contactId).get();
    if (!doc.exists) return;
    if (doc.data()?['ownerUid'] != ownerUid) {
      throw Exception('Unauthorized: You cannot delete another user\'s contact');
    }

    await _collection.doc(contactId).delete();
  }
}
