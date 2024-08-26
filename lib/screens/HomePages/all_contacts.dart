import 'package:chatapp/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatapp/providers/user_provider.dart';

class AllContactsPage extends StatefulWidget {
  const AllContactsPage({super.key});

  @override
  State<AllContactsPage> createState() => _AllContactsPageState();
}

class _AllContactsPageState extends State<AllContactsPage> {
  late Future<List<UserModel>> allUsersFuture;
  late Future<List<UserModel>> userContactsFuture;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    allUsersFuture = userProvider.fetchAllUsers(); // Fetch all users
    userContactsFuture = userProvider.loadUserContacts(); // Load user contacts
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
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
              const SizedBox(height: 10),
              FutureBuilder<List<UserModel>>(
                future: allUsersFuture,
                builder: (context, allUsersSnapshot) {
                  if (allUsersSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (allUsersSnapshot.hasError) {
                    return Center(
                        child: Text('Error: ${allUsersSnapshot.error}'));
                  } else if (!allUsersSnapshot.hasData ||
                      allUsersSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No users available.'));
                  }

                  // Extract the list of all users
                  final allUsers = allUsersSnapshot.data!.where((user) {
                    return user.username.toLowerCase().contains(searchQuery) ||
                        user.email.toLowerCase().contains(searchQuery);
                  }).toList();

                  return FutureBuilder<List<UserModel>>(
                    future: userContactsFuture,
                    builder: (context, userContactsSnapshot) {
                      if (userContactsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (userContactsSnapshot.hasError) {
                        return Center(
                            child:
                                Text('Error: ${userContactsSnapshot.error}'));
                      } else if (!userContactsSnapshot.hasData) {
                        return const Center(
                            child: Text('Error loading contacts.'));
                      }

                      // Extract the list of user contacts
                      final userContacts = userContactsSnapshot.data!;

                      return ListView(
                        shrinkWrap: true,
                        children: allUsers.map((user) {
                          bool isContact = userContacts
                              .any((contact) => contact.uid == user.uid);

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
                                    backgroundImage: user
                                            .profilePictureURL.isNotEmpty
                                        ? NetworkImage(user.profilePictureURL)
                                        : const AssetImage('assets/images.png')
                                            as ImageProvider,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  IconButton(
                                    icon: Icon(
                                      isContact
                                          ? Icons.remove_circle
                                          : Icons.add_circle,
                                      color:
                                          isContact ? Colors.red : Colors.blue,
                                    ),
                                    onPressed: () async {
                                      if (isContact) {
                                        await userProvider
                                            .removeFromContacts(user.uid);
                                      } else {
                                        await userProvider
                                            .addToContacts(user.uid);
                                      }
                                      // Refresh the user contacts list
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
                  );
                },
              ),
            ]),
          ),
        );
      },
    );
  }
}
