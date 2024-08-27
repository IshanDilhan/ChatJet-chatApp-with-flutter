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
  late StatusModel? _myStatus;
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

  // Function to fetch all statuses
  Future<void> fetchStatuses() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.i('No user is signed in.');
        return;
      }

      // Fetch all statuses from the controller
      final allStatuses = await _statusController.getStatuses();

      // Find the current user's status
      final myStatus = allStatuses.cast<StatusModel?>().firstWhere(
            (status) => status?.userId == user.uid,
            orElse: () => null, // Return null if no status is found.
          );

      // If a status is found, assign it to _myStatus
      if (myStatus != null) {
        _myStatus = myStatus;
      }

      // Log the user's status (if it exists)
      _logger
          .i(_myStatus?.toString() ?? 'No status found for the current user.');

      // Filter out the current user's status from the list
      _statuses =
          allStatuses.where((status) => status.userId != user.uid).toList();

      // Notify listeners to update the UI
      notifyListeners();

      _logger.i('Statuses fetched and filtered successfully.');
    } catch (e) {
      _logger.e('Failed to fetch statuses: $e');
      // Optionally, handle errors, e.g., by showing a message to the user
    }
  }

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
