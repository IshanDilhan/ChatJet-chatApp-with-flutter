import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/models/status_model.dart';
import 'package:logger/logger.dart';

class StatusController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Logger _logger = Logger();

  // Function to create and save a new status

  // Function to fetch all statuses
  Future<List<StatusModel>> getStatuses() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('status').get();

      List<StatusModel> statuses = snapshot.docs.map((doc) {
        return StatusModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      _logger.i('Fetched ${statuses.length} statuses.');
      return statuses;
    } catch (e) {
      _logger.e('Failed to fetch statuses: $e');
      return [];
    }
  }
}
