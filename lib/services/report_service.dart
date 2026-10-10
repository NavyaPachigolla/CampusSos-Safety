import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campus_report.dart';
import 'location_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('campus_reports');

  /// Submit a new unsafe campus area report
  /// Student reports always initiate in 'submitted' status
  Future<String> submitReport({
    required String reporterUid,
    required String category,
    required String description,
    bool attachCurrentLocation = true,
    String? photoUrl,
  }) async {
    if (reporterUid.isEmpty) throw Exception('User not authenticated');
    if (description.trim().isEmpty) {
      throw Exception('Description cannot be empty');
    }

    double? lat;
    double? lng;

    if (attachCurrentLocation) {
      final loc = await _locationService.getCurrentLocation();
      lat = loc.latitude;
      lng = loc.longitude;
    }

    final report = CampusReport(
      id: '',
      reporterUid: reporterUid,
      category: category,
      description: description.trim(),
      latitude: lat,
      longitude: lng,
      photoUrl: photoUrl,
      status: 'submitted',
    );

    final docRef = await _collection.add(report.toInitialMap());
    return docRef.id;
  }

  /// Stream reports submitted by the current student
  Stream<List<CampusReport>> getUserReportsStream(String reporterUid) {
    if (reporterUid.isEmpty) return Stream.value([]);

    return _collection
        .where('reporterUid', isEqualTo: reporterUid)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => CampusReport.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }
}
