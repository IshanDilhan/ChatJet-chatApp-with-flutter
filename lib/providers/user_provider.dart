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
        notifyListeners();
      } else {
        _logger.w("User data not found for UID: ${currentUser.uid}");
      }
    } else {
      _logger.w("No current user found in FirebaseAuth instance.");
    }
  }

  void updateUser(UserModel user) {
    _user = user;
    _logger.i("User data updated for UID: ${user.uid}");
    notifyListeners();
  }
}
