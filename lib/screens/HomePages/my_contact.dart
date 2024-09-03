import 'package:chatapp/controlers/chat_controller.dart';
import 'package:chatapp/models/user_model.dart'; // Import UserModel
import 'package:chatapp/screens/HomePages/user_profile_page.dart';
import 'package:flutter/material.dart'; // Import Flutter Material package
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'package:provider/provider.dart'; // Import provider package for state management
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts package for custom fonts
import 'package:chatapp/providers/user_provider.dart'; // Import UserProvider

class MyContactsPage extends StatefulWidget {
  const MyContactsPage({super.key});

  @override
  State<MyContactsPage> createState() => _MyContactsPageState();
}

class _MyContactsPageState extends State<MyContactsPage> {
  late Future<List<UserModel>>
      userContactsFuture; // Future to load user contacts
  String searchQuery = ''; // Search query for filtering contacts

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userContactsFuture = userProvider
        .loadUserContacts(); // Load contacts when widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    ChatController chatController = ChatController(context);
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Search TextField
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase(); // Update search query
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(
                  height: 10), // Space between search bar and contact list

              // FutureBuilder to display contacts
              FutureBuilder<List<UserModel>>(
                future: userContactsFuture,
                builder: (context, contactsSnapshot) {
                  if (contactsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator()); // Show loading spinner
                  } else if (contactsSnapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error: ${contactsSnapshot.error}')); // Show error message
                  } else if (!contactsSnapshot.hasData ||
                      contactsSnapshot.data!.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50), // Space at the top
                        const Icon(
                          Icons.contact_page,
                          size: 80,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'You have no contacts yet..',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Add from all users',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  // Filter contacts based on search query
                  final contacts = contactsSnapshot.data!.where((user) {
                    return user.username.toLowerCase().contains(searchQuery) ||
                        user.email.toLowerCase().contains(searchQuery);
                  }).toList();

                  return Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: contacts.map((user) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                        userId: user.uid,
                                      )),
                            );
                          },
                          child: Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  // Profile picture
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: user
                                            .profilePictureURL.isNotEmpty
                                        ? NetworkImage(user
                                            .profilePictureURL) // Load profile picture
                                        : const AssetImage('assets/images.png')
                                            as ImageProvider, // Default image
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Username
                                        Text(
                                          user.username,
                                          style: GoogleFonts.lato(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        // Email
                                        Text(
                                          user.email,
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        // Online status or last login
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              if (user.isOnline)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.circle,
                                                      color: Colors.green,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Online',
                                                      style: GoogleFonts.lato(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                Text(
                                                  'Last Login: ${DateFormat('dd MMM yyyy, hh:mm a').format(user.lastLogin)}',
                                                  style: GoogleFonts.lato(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  // Button for sending a message
                                  IconButton(
                                    icon: const Icon(Icons.message,
                                        color: Colors.blue),
                                    onPressed: () {
                                      chatController.startChat(user);
                                    },
                                  ),
                                  // Button for removing the contact
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await userProvider
                                          .removeFromContacts(user.uid);
                                      // Refresh the contacts list after removal
                                      setState(() {
                                        userContactsFuture =
                                            userProvider.loadUserContacts();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
