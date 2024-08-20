import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:logger/logger.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final Logger _logger = Logger();

  UserModel? get user => _user;

  Future<void> loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _logger.i("Loading user data for UID: ${currentUser.uid}");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        _logger.i("User data loaded successfully for UID: ${currentUser.uid}");
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'lastLogin': DateTime.now().toString()});
        notifyListeners();
      } else {
        _logger.w("User data not found for UID: ${currentUser.uid}");
      }
    } else {
      _logger.w("No current user found in FirebaseAuth instance.");
    }
    notifyListeners();
  }

  Future<void> updateUser({
    required String uid,
    String? username,
    String? bio,
    String? location,
    List<String>? interests,
    required BuildContext context,
  }) async {
    try {
      _logger.i("Attempting to update user details for UID: $uid");

      // Create a map to hold the updated fields
      Map<String, dynamic> updatedData = {};

      if (username != null && username.isNotEmpty) {
        updatedData['username'] = username;
      }
      if (bio != null && bio.isNotEmpty) {
        updatedData['bio'] = bio;
      }
      if (location != null && location.isNotEmpty) {
        updatedData['location'] = location;
      }
      if (interests != null && interests.isNotEmpty) {
        updatedData['interests'] = interests;
      }

      if (updatedData.isNotEmpty) {
        // Update the user's document in Firestore with the provided data
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updatedData);

        _logger.i("User details updated successfully for UID: $uid");

        // Optionally update the local user object if needed
        // Fetch updated user data from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          _user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          _logger.i("User data reloaded successfully for UID: $uid");
          notifyListeners();
        }

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User details updated successfully.')),
        );
      } else {
        _logger.w("No details were provided for update.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No details to update.')),
        );
      }
    } catch (e) {
      _logger.e("Error updating user data: $e");

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user details.')),
      );
    }
  }

  // void updateUser(UserModel user) {
  //   _user = user;
  //   _logger.i("User data updated for UID: ${user.uid}");
  //   notifyListeners();
  // }
}
