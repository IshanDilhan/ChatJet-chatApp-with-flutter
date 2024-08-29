import 'dart:io';

import 'package:chatapp/components/edit_details.dart';
import 'package:chatapp/components/profile_menu_items.dart';
import 'package:chatapp/components/view_full_profile_button.dart';
import 'package:chatapp/controlers/storage_controller.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  bool _showFullDetails = false;
  bool _editDetails = false;
  bool _settings = false;
  bool _editPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  late TextEditingController usernameController = TextEditingController();
  late TextEditingController bioController = TextEditingController();
  late TextEditingController locationController = TextEditingController();
  late TextEditingController interestsController = TextEditingController();
  late TextEditingController currentpasswordController =
      TextEditingController();
  late TextEditingController newPasswordController = TextEditingController();
  late TextEditingController againnewpasswordController =
      TextEditingController();

  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _obscureCurrentPassword = !_obscureCurrentPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  String? filepath;
  String? profileImageUrl;
  XFile? pickedFile;
  final ImagePicker _picker = ImagePicker();
  Future<void> selectImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        Logger().i('Image selected: ${pickedFile?.path}');

        File? croppedImg =
            // ignore: use_build_context_synchronously
            await cropImage(context, File(pickedFile?.path as String));
        if (croppedImg != null) {
          Logger().i("Cropped correctly: ${croppedImg.path}");
          setState(() {
            // Update the state to refresh the UI
            filepath = croppedImg.path;
          });
          final storageController = StorageController();
          final downloadURL = await storageController.uploadImage(
              'Usersimages', "${user?.uid}.jpg", croppedImg);

          if (downloadURL.isNotEmpty) {
            Logger().i("Image uploaded successfully: $downloadURL");
            updateProfileimagelink(downloadURL);
          } else {
            Logger().e("Failed to upload image");
          }
        } else {
          Logger().i("Cropping canceled or failed.");
        }
      } else {
        Logger().i('Image selection was cancelled or failed.');
      }
    } catch (e) {
      Logger().e('Error selecting image: $e');
    }
  }

  Future<File?> cropImage(BuildContext context, File file) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        maxHeight: 512,
        maxWidth: 512,
        compressQuality: 60,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: const Color.fromARGB(255, 158, 39, 146),
            toolbarWidgetColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPresetCustom(),
            ],
          ),
          IOSUiSettings(
            title: 'Cropper',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPresetCustom(), // IMPORTANT: iOS supports only one custom aspect ratio in preset list
            ],
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile != null) {
        Logger().i('Image cropped: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        Logger().i('Image cropping was cancelled or failed.');
        return null;
      }
    } catch (e) {
      Logger().e('Error cropping image: $e');
      return null;
    }
  }

  Future<void> updateProfileimagelink(String imageURL) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePictureURL': imageURL});

        // ignore: use_build_context_synchronously
        await context.read<UserProvider>().loadUserData();

        Logger().i('imageURL updated');
      } catch (e) {
        // Handle errors here, for example by showing an error message
        Logger().i('Failed to update imageURL: $e');
      }
    } else {
      // Handle the case where no user is signed in
      Logger().i('No user is signed in.');
    }
  }

  Future<void> deleteImage(String imageURL, BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Reference to the image in Firebase Storage
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('Usersimages')
            .child('${user.uid}.jpg');

        // Delete the image from Firebase Storage
        await imageRef.delete();
        Logger().i('Profile image deleted successfully.');

        // Update Firestore to remove the image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePictureURL': ''});

        // ignore: use_build_context_synchronously
        await context.read<UserProvider>().loadUserData();
      } catch (e) {
        Logger().e('Failed to delete image : $e');

        // Optionally, show a snackbar to notify the user of the failure
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to delete profile picture  Please try again.')),
        );
      }
    } else {
      Logger().i('No user is signed in.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is signed in.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    UserProvider fretcheduser = Provider.of<UserProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
          child: Column(children: [
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  "assets/images/top1.png",
                  width: size.width,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: size.width * 0.4,
                  height: size.width * 0.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: fretcheduser.user?.profilePictureURL != null &&
                              fretcheduser.user!.profilePictureURL.isNotEmpty
                          ? NetworkImage(fretcheduser.user!.profilePictureURL)
                          : const AssetImage('assets/images.png')
                              as ImageProvider,
                    ),
                    border: Border.all(
                      color: const Color(0xFF2661FA),
                      width: 4,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                selectImage();
                              },
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black.withOpacity(0.5),
                                child: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            fretcheduser.user?.profilePictureURL.isNotEmpty ==
                                    true
                                ? GestureDetector(
                                    onTap: () {
                                      deleteImage(
                                          fretcheduser.user!.profilePictureURL,
                                          context);
                                    },
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor:
                                          Colors.red.withOpacity(0.5),
                                      child: const Icon(
                                        Icons.delete,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          fretcheduser.user?.username ?? 'Loading...',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Color(0xFF2661FA),
          ),
        ),
        Text(
          fretcheduser.user?.email ?? 'Loading...',
          style: GoogleFonts.acme(
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        Text(
          fretcheduser.user?.mobileNumber ?? 'Loading...',
          style: GoogleFonts.acme(
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        Text(
          fretcheduser.user?.bio.isNotEmpty == true
              ? fretcheduser.user!.bio
              : 'Hi, I am using ChatJet...',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        if (_showFullDetails)
          Column(
            children: [
              Text(
                'Location: ${fretcheduser.user?.location.isNotEmpty == true ? fretcheduser.user!.location : 'Update Location'}',
                style: GoogleFonts.acme(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Interests: ${fretcheduser.user?.interests.isNotEmpty == true ? fretcheduser.user!.interests.join(', ') : 'Update interests'}',
                style: GoogleFonts.acme(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Last login: ${fretcheduser.user?.lastLogin != null ? DateFormat('MMMM d, yyyy h:mm a').format(fretcheduser.user!.lastLogin) : 'Not specified'}',
                style: GoogleFonts.acme(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Created: ${fretcheduser.user?.createdAt != null ? DateFormat('MMMM d, yyyy h:mm a').format(fretcheduser.user!.createdAt) : 'Not specified'}',
                style: GoogleFonts.acme(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ViewMoreButton(
          isExpanded: _showFullDetails,
          onPressed: () {
            setState(() {
              _showFullDetails = !_showFullDetails;
              _editDetails = false;
              _settings = false;
            });
          },
        ),
        EditDetailsButton(
          isExpanded: _editDetails,
          onPressed: () {
            setState(() {
              _showFullDetails = false;
              _settings = false;
              _editPassword = false;
              _editDetails = !_editDetails;
              usernameController = TextEditingController(
                  text: fretcheduser.user?.username ?? '');
              bioController = TextEditingController(
                  text: fretcheduser.user?.bio.isNotEmpty == true
                      ? fretcheduser.user?.bio
                      : 'Hi, I am using ChatJet...');
              locationController = TextEditingController(
                  text: fretcheduser.user?.location ?? '');
              interestsController = TextEditingController(
                text: (fretcheduser.user?.interests ?? []).isNotEmpty
                    ? fretcheduser.user!.interests.join(', ')
                    : '',
              );
            });
            // Add any logic needed after saving or canceling the edits
          },
        ),
        if (_editDetails)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                margin:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'username',
                    labelStyle: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  style: GoogleFonts.acme(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  minLines: 1,
                  maxLines: 1,
                ),
              ),

              // Bio Field
              Container(
                alignment: Alignment.center,
                margin:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: bioController,
                  decoration: InputDecoration(
                    labelText: 'bio',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    prefixIcon:
                        Icon(Icons.info_outline, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  style: GoogleFonts.acme(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),

              // Location Field
              Container(
                alignment: Alignment.center,
                margin:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'location',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    prefixIcon:
                        Icon(Icons.location_on, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  style: GoogleFonts.acme(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
              ),

              Container(
                alignment: Alignment.center,
                margin:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: interestsController,
                  decoration: InputDecoration(
                    labelText: 'interests',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    prefixIcon:
                        Icon(Icons.interests, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  style: GoogleFonts.acme(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),

              // Save/Edit Button
              Container(
                alignment: Alignment.center,
                margin:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: ElevatedButton(
                  onPressed: () async {
                    // Call the updateUserDetails function when the button is pressed
                    await fretcheduser.updateUser(
                      uid: fretcheduser
                          .user!.uid, // Ensure you pass the user's UID
                      username: usernameController.text.isNotEmpty
                          ? usernameController.text
                          : null,
                      bio: bioController.text.isNotEmpty
                          ? bioController.text
                          : null,
                      location: locationController.text.isNotEmpty
                          ? locationController.text
                          : null,
                      interests: interestsController.text.isNotEmpty
                          ? interestsController.text
                              .split(',')
                              .map((s) => s.trim())
                              .toList()
                          : null,
                      context: context, // Pass context for showing SnackBars
                    );

                    // Optionally, toggle the _editDetails state to false to exit edit mode
                    setState(() {
                      _editDetails = false;
                      usernameController.clear();
                      bioController.clear;
                      locationController.clear();
                      interestsController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 87, 102, 229), // Harmonized color
                    padding: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80.0),
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    height: 50.0,
                    width: size.width * 0.5,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(80.0),
                        color: const Color.fromARGB(
                            255, 118, 130, 236) // Harmonized color

                        ),
                    padding: const EdgeInsets.all(0),
                    child: Text(
                      _editDetails ? "Save Changes" : "Edit Details",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.acme(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ProfileMenuItem(
          isExpanded: _settings,
          icon: Icons.settings,
          text: "Setting",
          onPressed: () {
            setState(() {
              _settings = !_settings;
              _showFullDetails = false;
              _editDetails = false;
              _editPassword = false;
            });
          },
        ),
        Column(children: [
          // Other sections...

          if (_settings)
            GestureDetector(
              onTap: () => {
                setState(() {
                  _editPassword = !_editPassword;
                })
              },
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 185, 184, 184),
                      Color.fromARGB(255, 185, 184, 184)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _editPassword = !_editPassword;
                        });
                      },
                      icon: const Icon(
                        Icons.lock_outline,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Change Password',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(right: 15),
                      child: Transform.rotate(
                        angle: _editPassword ? -3.14 / 2 : 3.14 / 2,
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_editPassword)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Column(
                children: [
                  _buildPasswordTextField(
                    controller: currentpasswordController,
                    obscureText: _obscureCurrentPassword,
                    toggleObscureText: _toggleCurrentPasswordVisibility,
                    labelText: 'Current Password',
                    icon: Icons.lock,
                  ),
                  _buildPasswordTextField(
                    controller: newPasswordController,
                    obscureText: _obscureNewPassword,
                    toggleObscureText: _toggleNewPasswordVisibility,
                    labelText: 'New Password',
                    icon: Icons.lock_open,
                  ),
                  _buildPasswordTextField(
                    controller: againnewpasswordController,
                    obscureText: _obscureConfirmPassword,
                    toggleObscureText: _toggleConfirmPasswordVisibility,
                    labelText: 'Confirm New Password',
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      // Validate inputs and call the changePassword method
                      if (currentpasswordController.text.isEmpty ||
                          newPasswordController.text.isEmpty ||
                          againnewpasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill in all fields.')),
                        );
                        return;
                      }

                      // Ensure passwords match
                      if (newPasswordController.text !=
                          againnewpasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('New passwords do not match.')),
                        );
                        return;
                      }

                      // Call the changePassword method from UserProvider
                      await fretcheduser.changePassword(
                        currentPassword: currentpasswordController.text,
                        newPassword: newPasswordController.text,
                        confirmPassword: againnewpasswordController.text,
                        context: context,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 87, 102, 229), // Harmonized color
                      padding: const EdgeInsets.all(0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 50.0,
                      width: size.width * 0.5,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(80.0),
                          color: const Color.fromARGB(
                              255, 118, 130, 236) // Harmonized color

                          ),
                      padding: const EdgeInsets.all(0),
                      child: Text(
                        "Update Password",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.acme(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_settings)
            GestureDetector(
              onTap: () async {
                bool confirmed = await _showDeleteAccountDialog(context);
                if (confirmed) {
                  // ignore: use_build_context_synchronously
                  await fretcheduser.deleteAccount(context);
                }
              },
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 185, 184, 184),
                      Color.fromARGB(255, 185, 184, 184)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool confirmed =
                            await _showDeleteAccountDialog(context);
                        if (confirmed) {
                          // ignore: use_build_context_synchronously
                          await fretcheduser.deleteAccount(context);
                        }
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Color.fromARGB(255, 210, 41, 41),
                      ),
                      label: const Text(
                        'Delete Acount',
                        style:
                            TextStyle(color: Color.fromARGB(255, 204, 21, 21)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ProfileMenuItem(
            isExpanded: _settings,
            icon: Icons.logout,
            text: "Logout",
            onPressed: () async {
              bool? confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(false); // User cancels the logout
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(true); // User confirms the logout
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                await fretcheduser
                    // ignore: use_build_context_synchronously
                    .logout(context); // Call the logout function if confirmed
              }
            },
          ),
        ]),
      ])),
    );
  }
}

Widget _buildPasswordTextField({
  required TextEditingController controller,
  required String labelText,
  required IconData icon,
  required bool obscureText,
  required VoidCallback
      toggleObscureText, // Function to toggle the obscureText state
}) {
  return Container(
    alignment: Alignment.center,
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.white, Colors.grey.shade200],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3), // Changes position of shadow
        ),
      ],
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed:
              toggleObscureText, // Calls the toggle function passed from the parent
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      style: GoogleFonts.acme(
        fontSize: 18,
        color: Colors.black87,
      ),
      minLines: 1,
      maxLines: 1,
    ),
  );
}

Future<bool> _showDeleteAccountDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
                'Are you sure you want to delete your account? This action cannot be undone.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false; // Return false if the dialog is dismissed
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
