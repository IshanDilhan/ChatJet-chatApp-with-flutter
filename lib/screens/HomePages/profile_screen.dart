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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final fretcheduser = Provider.of<UserProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                children: [
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
            ProfileMenuItem(
              icon: Icons.view_kanban_rounded,
              text: "View Profile",
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const EditProfilePage(),
                //   ),
                // );
              },
            ),
            ProfileMenuItem(
              icon: Icons.edit,
              text: "Edit Profile",
              onPressed: () {
                // Navigate to edit profile page
              },
            ),
            ProfileMenuItem(
              icon: Icons.lock,
              text: "Change Password",
              onPressed: () {
                // Navigate to change password page
              },
            ),
            ProfileMenuItem(
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
