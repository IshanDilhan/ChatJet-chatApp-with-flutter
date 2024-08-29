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

  Future<void> deleteStatus(String statusId) async {
    try {
      // Reference to the statuses collection
      final statusRef = _firestore.collection('status').doc(statusId);

      // Delete the status document
      await statusRef.delete();

      Logger().i('Status with ID $statusId deleted successfully.');
    } catch (e) {
      Logger().i('Failed to delete status: $e');
      // Optionally, handle errors, e.g., by showing a message to the user
    }
  }
}
