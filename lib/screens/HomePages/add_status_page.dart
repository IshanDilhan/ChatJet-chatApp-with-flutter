import 'package:chatapp/models/status_model.dart';
import 'package:chatapp/providers/status_provider.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddStatusTextPage extends StatefulWidget {
  final String statusImageUrl;

  const AddStatusTextPage({super.key, required this.statusImageUrl});

  @override
  // ignore: library_private_types_in_public_api
  _AddStatusTextPageState createState() => _AddStatusTextPageState();
}

class _AddStatusTextPageState extends State<AddStatusTextPage> {
  final _statusTextController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  Future<void> createStatus({
    required String statusImageUrl,
    required String statusText,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DateTime timestamp = DateTime.now();

        // Fetch the existing status for the user
        QuerySnapshot statusSnapshot = await _firestore
            .collection('status')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (statusSnapshot.docs.isNotEmpty) {
          // If an existing status is found, update it
          DocumentSnapshot existingStatusDoc = statusSnapshot.docs.first;
          StatusModel existingStatus = StatusModel.fromMap(
              existingStatusDoc.data() as Map<String, dynamic>);

          // Get existing image URLs and texts
          List<String> existingImageUrls =
              List<String>.from(existingStatus.statusImageUrls ?? []);
          List<String> existingTexts =
              List<String>.from(existingStatus.statusText ?? []);

          // Add new image URL and text to the lists
          existingImageUrls.add(statusImageUrl);
          existingTexts.add(statusText);

          // Update the status document with new image URL and text
          await _firestore
              .collection('status')
              .doc(existingStatus.statusId)
              .update({
            'statusImageUrls': existingImageUrls,
            'statusText': existingTexts,
            'timestamp': timestamp.toIso8601String(),
          });

          _logger.i('Status updated successfully: ${existingStatus.statusId}');
          // ignore: use_build_context_synchronously
          Provider.of<StatusProvider>(context, listen: false).fetchStatuses();
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        } else {
          // If no existing status is found, create a new status
          final userprovider =
              // ignore: use_build_context_synchronously
              Provider.of<UserProvider>(context, listen: false).user;
          String statusId = const Uuid().v4();

          StatusModel newStatus = StatusModel(
            statusId: statusId,
            userId: user.uid,
            username: userprovider!.username,
            userProfileUrl: userprovider.profilePictureURL,
            statusImageUrls: [
              statusImageUrl
            ], // Single image initially; ensure this is a list
            statusText: [
              statusText
            ], // Single text initially; ensure this is a list
            timestamp: timestamp,
          );

          await _firestore
              .collection('status')
              .doc(statusId)
              .set(newStatus.toMap());
          // ignore: use_build_context_synchronously
          Provider.of<StatusProvider>(context, listen: false).fetchStatuses();
          // ignore: use_build_context_synchronously
          Navigator.pop(context);

          _logger.i('Status created successfully: $statusId');
        }
      } catch (e) {
        _logger.e('Failed to create status: $e');
      }
      // ignore: use_build_context_synchronously
      Provider.of<StatusProvider>(context, listen: false).statusImageUrl = '';
    } else {
      _logger.i('No user is signed in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Status Text'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Display status image
              Image.network(widget.statusImageUrl),
              TextField(
                controller: _statusTextController,
                decoration: const InputDecoration(
                  labelText: 'Enter your status text',
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  createStatus(
                      statusImageUrl: widget.statusImageUrl,
                      statusText: _statusTextController.text);
                },
                child: const Text('Save Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
