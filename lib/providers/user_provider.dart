import 'package:chatapp/screens/SignInPages/loging_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:logger/logger.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final Logger _logger = Logger();
  List<UserModel> _userContacts = [];
  List<UserModel> _allUsers = [];

  User? currectuser = FirebaseAuth.instance.currentUser;

  UserModel? get user => _user;
  List<UserModel> get userContacts => _userContacts;
  List<UserModel> get allUsers => _allUsers;

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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    try {
      // Validate the new password
      if (newPassword != confirmPassword) {
        _showErrorDialog(context, 'New passwords do not match.');
        return;
      }

      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Re-authenticate the user
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: currentPassword,
        );

        try {
          // Re-authenticate the user
          await currentUser.reauthenticateWithCredential(credential);

          // Update the password
          await currentUser.updatePassword(newPassword);

          // Update Firestore to reflect the password change (if needed)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'lastPasswordChange': DateTime.now().toString()});

          _logger
              .i("Password updated successfully for UID: ${currentUser.uid}");

          // Show success message
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully.')),
          );
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } on FirebaseAuthException catch (e) {
          _logger.e("Failed to update password: $e");
          _showErrorDialog(
              // ignore: use_build_context_synchronously
              context,
              'Failed to update password. Please try again.');
        }
      } else {
        _showErrorDialog(context, 'No current user found.');
      }
    } catch (e) {
      _logger.e("Error changing password: $e");
      _showErrorDialog(
          // ignore: use_build_context_synchronously
          context,
          'An error occurred while changing the password.');
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('Usersimages')
            .child('${user?.uid}.jpg');

        // Check if the image exists before attempting to delete it
        try {
          await imageRef.getDownloadURL();
          // If the image exists, delete it
          await imageRef.delete();
          Logger().i('Profile image deleted successfully.');
        } catch (e) {
          Logger().i('No profile image found, skipping deletion.');
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .delete();

        // Delete user's account from FirebaseAuth
        await currentUser.delete();

        _logger
            .i("User account deleted successfully for UID: ${currentUser.uid}");

        // Navigate to login page after deletion
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      _logger.e("Error deleting user account: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete account. Please try again.')),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      _logger.i("User logged out successfully");

      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      _logger.e("Error logging out: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout. Please try again.')),
      );
    }
  }

  //contacts

  Future<List<UserModel>> fetchAllUsers() async {
    try {
      // Fetch all users from Firestore
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Convert snapshot to List<UserModel>
      List<UserModel> users = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      // Filter out the current user and users already in the contact list
      if (_user != null) {
        users = users.where((user) => user.uid != _user!.uid).toList();
      }

      _allUsers = users; // Update the _allUsers field
      _logger.i("Fetched ${users.length} users.");

      return users;
    } catch (e) {
      _logger.e("Error fetching users: $e");
      return [];
    }
  }

  Future<List<UserModel>> loadUserContacts() async {
    try {
      if (_user != null) {
        // Fetch all users from Firestore
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection('users').get();

        // Convert snapshot to List<UserModel>
        List<UserModel> allUsers = snapshot.docs.map((doc) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();

        // Filter out the current user and users not in the current user's contacts list
        List<UserModel> contacts = allUsers
            .where((user) =>
                _user!.contacts.contains(user.uid) && user.uid != _user!.uid)
            .toList();

        _userContacts = contacts; // Update the _userContacts field
        _logger.i("Loaded ${_userContacts.length} user contacts.");
        notifyListeners(); // Notify listeners to update the UI

        return contacts;
      } else {
        _logger.w("No user is currently logged in.");
        return []; // Return an empty list if no user is logged in
      }
    } catch (e) {
      _logger.e("Error loading user contacts: $e");
      return []; // Return an empty list in case of an error
    }
  }

  Future<void> addToContacts(String contactUid) async {
    if (_user == null) return;

    try {
      // Add contact UID to the current user's contacts list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'contacts': FieldValue.arrayUnion([contactUid])
      });

      // Update the local user model
      _user!.contacts.add(contactUid);
      notifyListeners();

      _logger.i("Added contact $contactUid.");
    } catch (e) {
      _logger.e("Error adding contact: $e");
    }
  }

  Future<void> removeFromContacts(String contactUid) async {
    if (_user == null) return;

    try {
      // Remove contact UID from the current user's contacts list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'contacts': FieldValue.arrayRemove([contactUid])
      });

      // Update the local user model
      _user!.contacts.remove(contactUid);
      notifyListeners();

      _logger.i("Removed contact $contactUid.");
    } catch (e) {
      _logger.e("Error removing contact: $e");
    }
  }
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
