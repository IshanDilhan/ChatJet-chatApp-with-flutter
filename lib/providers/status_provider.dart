import 'dart:io';
import 'package:chatapp/controlers/status_controller.dart';
import 'package:chatapp/controlers/storage_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:chatapp/models/status_model.dart';
import 'package:uuid/uuid.dart';

class StatusProvider with ChangeNotifier {
  final StatusController _statusController = StatusController();
  final StorageController _storageController = StorageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<StatusModel> _statuses = [];
  StatusModel? _myStatus;
  String _statusImageUrl = '';
  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  List<StatusModel> get statuses => _statuses;
  StatusModel? get mystatus => _myStatus;
  String get statusImageUrl => _statusImageUrl;

  set statusImageUrl(String url) {
    _statusImageUrl = url;
    notifyListeners(); // Notify listeners about the change
  }

  // Function to select, crop, and upload a status image
  Future<void> selectStatusImage(BuildContext context) async {
    try {
      _pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (_pickedFile != null) {
        _logger.i('Status image selected: ${_pickedFile?.path}');

        // ignore: use_build_context_synchronously
        File? croppedImg = await _cropImage(context, File(_pickedFile!.path));
        if (croppedImg != null) {
          _logger.i("Status image cropped correctly: ${croppedImg.path}");
          final String statusId = _uuid.v4(); // Generate a unique ID
          final String fileName =
              '$statusId.jpg'; // Use the ID for the file name
          const String folderPath = 'status'; // Folder path in Firebase Storage

          final downloadURL = await _storageController.uploadImage(
            folderPath,
            fileName,
            croppedImg,
          );

          if (downloadURL.isNotEmpty) {
            _logger.i("Status image uploaded successfully: $downloadURL");
            _statusImageUrl = downloadURL;
            notifyListeners();
          } else {
            _logger.e("Failed to upload status image");
          }
        } else {
          _logger.i("Status image cropping canceled or failed.");
        }
      } else {
        _logger.i('Status image selection was cancelled or failed.');
      }
    } catch (e) {
      _logger.e('Error selecting status image: $e');
    }
  }

  Future<File?> _cropImage(BuildContext context, File file) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        maxHeight: 512,
        maxWidth: 512,
        compressQuality: 60,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Status Image',
            toolbarColor: const Color.fromARGB(255, 39, 69, 176),
            toolbarWidgetColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Status Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
            ],
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile != null) {
        _logger.i('Status image cropped: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        _logger.i('Status image cropping was cancelled or failed.');
        return null;
      }
    } catch (e) {
      _logger.e('Error cropping status image: $e');
      return null;
    }
  }

  // Function to create and save a new status
  String formatCurrentTime(DateTime dateTime) {
    // Format the current time in the same format as the database
    return dateTime.toIso8601String().replaceFirst('T', ' ').split('.')[0];
  }

  // Function to fetch all statuses

  Future<void> fetchStatuses() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.i('No user is signed in.');
        return;
      }

      _logger.i('Fetching all statuses from the controller...');

      // Fetch all statuses from the controller
      final allStatuses = await _statusController.getStatuses();
      _logger.i('Fetched ${allStatuses.length} statuses.');

      // Get the current time
      final now = DateTime.now();
      _logger.i('Current time: $now');

      // Define cutoff time for 24 hours ago
      final cutoff = now.subtract(const Duration(hours: 24));
      _logger.i('Cutoff time (24 hours ago): $cutoff');

      // List to hold valid statuses
      List<StatusModel> validStatuses = [];

      for (final status in allStatuses) {
        try {
          _logger.i('Processing status with ID: ${status.statusId}');

          // Parse the timestamp from the database
          final statusTimestamp = DateTime.parse(status.timestamp.toString());
          _logger.i('Parsed timestamp for status: $statusTimestamp');

          // Check if the status is less than 24 hours old
          if (statusTimestamp.isAfter(cutoff)) {
            _logger.i('Status is valid (less than 24 hours old).');
            validStatuses.add(status);
          } else {
            // Delete old statuses
            await _firestore.collection('status').doc(status.statusId).delete();
            _logger.i('Deleted old status: ${status.statusId}');
          }
        } catch (e) {
          _logger.e('Error processing status with ID: ${status.statusId} - $e');
        }
      }

      // Log the number of valid statuses
      _logger.i('Number of valid statuses: ${validStatuses.length}');

      // Find the current user's status
      _logger.i('Number of valid statuses: ${validStatuses.length}');

      // Find the current user's status
      final myStatus = validStatuses
          .where((status) => status.userId == user.uid)
          .toList()
          .firstOrNull;

      if (myStatus != null) {
        _myStatus = myStatus;
        _logger.i('User status found and set.');
      } else {
        _myStatus = null;
        _logger.i('No status found for the current user.');
      }

      // Filter out the current user's status from the list
      _statuses =
          validStatuses.where((status) => status.userId != user.uid).toList();
      _logger.i('Filtered out the current user\'s status from the list.');

      // Notify listeners to update the UI
      notifyListeners();
      _logger.i('UI update notified successfully.');
    } catch (e) {
      _logger.e('Failed to fetch statuses: $e');
    }
  }

  // Future<void> deleteOldStatuses() async {
  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user == null) {
  //       _logger.i('No user is signed in.');
  //       return;
  //     }

  //     // Fetch all statuses from the controller
  //     final allStatuses = await _statusController.getStatuses();

  //     // Filter out statuses older than 24 hours
  //     final now = DateTime.now();
  //     final oldStatuses = allStatuses.where((status) {
  //       final statusTimestamp =
  //           status.timestamp; // Assuming timestamp is already a DateTime
  //       return now.difference(statusTimestamp).inHours >= 24;
  //     }).toList();

  //     // Delete old statuses from the database
  //     for (final status in oldStatuses) {
  //       await _statusController.deleteStatus(
  //           status.statusId); // Implement this method in your controller
  //           await deleteStatusItem(status.statusId)
  //     }

  //     // Fetch statuses again to update the UI
  //     await fetchStatuses();

  //     _logger.i('Old statuses deleted successfully.');
  //   } catch (e) {
  //     _logger.e('Failed to delete old statuses: $e');
  //   }
  // }

  Future<void> deleteStatusItem(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
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

          // Remove the image URL and text at the specified index
          if (index >= 0 && index < existingImageUrls.length) {
            existingImageUrls.removeAt(index);
          }
          if (index >= 0 && index < existingTexts.length) {
            existingTexts.removeAt(index);
          }

          // Update the status document with new lists
          await _firestore
              .collection('status')
              .doc(existingStatus.statusId)
              .update({
            'statusImageUrls': existingImageUrls,
            'statusText': existingTexts,
            'timestamp': DateTime.now().toIso8601String(), // Update timestamp
          });

          _logger.i(
              'Status item deleted successfully: ${existingStatus.statusId}');
          fetchStatuses();
        } else {
          _logger.i('No status found for the user.');
        }
      } catch (e) {
        _logger.e('Failed to delete status item: $e');
      }
    } else {
      _logger.i('No user is signed in.');
    }
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
