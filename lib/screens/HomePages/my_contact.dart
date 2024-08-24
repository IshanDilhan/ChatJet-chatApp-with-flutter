import 'package:chatapp/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatapp/providers/user_provider.dart';

class MyContactsPage extends StatefulWidget {
  const MyContactsPage({super.key});

  @override
  State<MyContactsPage> createState() => _MyContactsPageState();
}

class _MyContactsPageState extends State<MyContactsPage> {
  late Future<List<UserModel>> userContactsFuture;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userContactsFuture = userProvider.loadUserContacts(); // Load user contacts
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: FutureBuilder<List<UserModel>>(
            future: userContactsFuture,
            builder: (context, contactsSnapshot) {
              if (contactsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (contactsSnapshot.hasError) {
                return Center(child: Text('Error: ${contactsSnapshot.error}'));
              } else if (!contactsSnapshot.hasData ||
                  contactsSnapshot.data!.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50), // Adjust space at the top
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

              final contacts = contactsSnapshot.data!;

              return ListView(
                children: contacts.map((user) {
                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: user.profilePictureURL.isNotEmpty
                                ? NetworkImage(user.profilePictureURL)
                                : const AssetImage('assets/images.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  user.email,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
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
                                )
                              ],
                            ),
                          ),
                          // Button for sending a message
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.blue),
                            onPressed: () {
                              // Handle sending a message
                              // Add your message sending logic here
                            },
                          ),
                          // Button for removing the contact
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () async {
                              await userProvider.removeFromContacts(user.uid);
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
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}
