import 'package:chatapp/components/edit_details.dart';
import 'package:chatapp/components/profile_menu_items.dart';
import 'package:chatapp/components/view_full_profile_button.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showFullDetails = false;
  bool _editDetails = false;
  bool _settings = false;
  late TextEditingController usernameController = TextEditingController();
  late TextEditingController bioController = TextEditingController();
  late TextEditingController locationController = TextEditingController();
  late TextEditingController interestsController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    UserProvider fretcheduser = Provider.of<UserProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                                  fretcheduser
                                      .user!.profilePictureURL.isNotEmpty
                              ? NetworkImage(
                                  fretcheduser.user!.profilePictureURL)
                              : const AssetImage('assets/profileimage.png')
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
                                    //selectImage();
                                  },
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        Colors.black.withOpacity(0.5),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                fretcheduser.user?.profilePictureURL
                                            .isNotEmpty ==
                                        true
                                    ? GestureDetector(
                                        onTap: () {
                                          //deleteImage(imageURL);
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
                    'Contacts: ${fretcheduser.user?.contacts.isNotEmpty == true ? fretcheduser.user!.contacts.join(', ') : 'Update contacts'}',
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
                });
              },
            ),
            EditDetailsButton(
              isExpanded: _editDetails,
              onPressed: () {
                setState(() {
                  _showFullDetails = !_showFullDetails;
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
                  SizedBox(height: size.height * 0.03),
                  // Username Field
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.grey),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      style: GoogleFonts.acme(
                        fontSize: 18,
                        color: const Color.fromARGB(208, 0, 0, 0),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  // Bio Field
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      controller: bioController,
                      decoration: InputDecoration(
                        labelText: "Bio",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        prefixIcon:
                            const Icon(Icons.info_outline, color: Colors.grey),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Update bio
                        });
                      },
                      style: GoogleFonts.acme(
                        fontSize: 18,
                        color: const Color.fromARGB(208, 0, 0, 0),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  // Location Field
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: "Location",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        prefixIcon:
                            const Icon(Icons.location_on, color: Colors.grey),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Update location
                        });
                      },
                      style: GoogleFonts.acme(
                        fontSize: 18,
                        color: const Color.fromARGB(208, 0, 0, 0),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  // Interests Field
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      controller: interestsController,
                      decoration: InputDecoration(
                        labelText: "Interests",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        prefixIcon:
                            const Icon(Icons.interests, color: Colors.grey),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Update interests
                        });
                      },
                      style: GoogleFonts.acme(
                        fontSize: 18,
                        color: const Color.fromARGB(208, 0, 0, 0),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  // Save/Edit Button
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
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
                          context:
                              context, // Pass context for showing SnackBars
                        );

                        // Optionally, toggle the _editDetails state to false to exit edit mode
                        setState(() {
                          _editDetails = false;
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
                });
              },
            ),
            Column(
              children: [
                // Other sections...

                // Conditionally display only one of the buttons based on _settings
                if (_settings)
                  SizedBox(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ElevatedButton(
                        onPressed: () async {
                          //_showChangePasswordDialog();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Change Password'),
                      ),
                    ),
                  ),
                if (_settings)
                  SizedBox(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ElevatedButton(
                        onPressed: () async {
                          // _showDeleteAccountDialog();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Delete Account'),
                      ),
                    ),
                  ),
              ],
            ),
            ProfileMenuItem(
              isExpanded: _settings,
              icon: Icons.logout,
              text: "Logout",
              onPressed: () {
                // Handle logout
              },
            ),
          ],
        ),
      ),
    );
  }
}
