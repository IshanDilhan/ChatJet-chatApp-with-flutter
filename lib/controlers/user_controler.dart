import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/screens/SignInPages/loging_screen.dart';
import 'package:chatapp/screens/main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class UserController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  Future<void> signUp({
    required String username,
    required String mobileNumber,
    required String email,
    required String password,
    String bio = '', // Optional
    String location = '', // Optional
    List<String> interests = const [], // Optional
  }) async {
    try {
      _logger.i("Attempting to sign up with email: $email");

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          username: username,
          mobileNumber: mobileNumber,
          email: email,
          profilePictureURL: '', // Placeholder, update later
          status: 'offline',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          bio: bio,
          location: location,
          interests: interests,
          contacts: [], // Initialize with empty list
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        _logger.i("User data saved to Firestore for UID: ${user.uid}");
      }
    } catch (error) {
      _logger.e("Sign-up failed with error: $error");
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i("Attempting to sign in with email: $email");

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Update the last login time
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
          'status': 'online',
        });

        _logger.i("User signed in with UID: ${user.uid}");
      }
    } catch (error) {
      _logger.e("Sign-in failed with error: $error");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        _logger.i("Signing out user with UID: ${user.uid}");

        // Update the last logout time
        await _firestore.collection('users').doc(user.uid).update({
          'status': 'offline',
          'lastLogout': DateTime.now().toIso8601String(),
        });

        await _auth.signOut();

        _logger.i("User signed out successfully");
      }
    } catch (error) {
      _logger.e("Sign-out failed with error: $error");
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i("Password reset email sent to: $email");

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password Reset Email has been sent!",
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      );

      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        _logger.w("No user found for email: $email");

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No user found for that email.",
              style: TextStyle(fontSize: 20.0),
            ),
          ),
        );
      } else {
        _logger.e("Error during password reset: ${e.message}");
      }
    } catch (e) {
      _logger.e("Unexpected error: $e");
    }
  }

  Future<void> signInWithGoogle({
    required BuildContext context,
  }) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        _logger.e("Google Sign-In aborted by user");
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Create a new user if not exists
          UserModel newUser = UserModel(
            uid: user.uid,
            username: user.displayName ?? 'No Name',
            mobileNumber: '', // You might want to update this later
            email: user.email ?? '',
            profilePictureURL: user.photoURL ?? '',
            status: 'offline',
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            bio: '', // Optional
            location: '', // Optional
            interests: [], // Optional
            contacts: [], // Initialize with empty list
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
          _logger.i("User data saved to Firestore for UID: ${user.uid}");
        }

        // Navigate to HomePage or wherever you want
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (error) {
      _logger.e("Error during Google Sign-In: $error");
    }
  }
}
