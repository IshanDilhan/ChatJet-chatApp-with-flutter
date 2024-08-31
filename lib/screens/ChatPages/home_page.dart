import 'package:chatapp/models/chat_model.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:chatapp/providers/chat_provider.dart';
import 'package:chatapp/screens/ChatPages/chat_page.dart';
import 'package:chatapp/screens/HomePages/contact_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = Logger();
  List<ChatModel> chats = [];
  Map<String, UserModel> participantDetails = {};
  List<ChatModel> filteredChats = [];
  User? currentuser = FirebaseAuth.instance.currentUser;
  String searchQuery = '';
  bool ifSearch = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchChats();
  }

  Future<void> _loadUserData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData();
      final user = userProvider.user;
      if (user != null) {
        _logger.i("User data loaded successfully: ${user.username}");
      } else {
        _logger.w("User data could not be loaded.");
      }
    } catch (error) {
      _logger.e("Error loading user data: $error");
    }
  }

  Future<void> _fetchChats() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _logger.w('No user is currently signed in.');
      return;
    }

    final chatCollection = FirebaseFirestore.instance.collection('chats');
    chatCollection.snapshots().listen((chatSnapshots) async {
      final fetchedChats = <ChatModel>[];
      final allParticipantIds = <String>{};

      for (var doc in chatSnapshots.docs) {
        final chatData = doc.data();
        final chatId = doc.id;
        final chatModel = ChatModel.fromMap(chatId, chatData);

        if (chatModel.participants.contains(currentUser.uid)) {
          final participantIds = chatModel.participants
              .where((id) => id != currentUser.uid)
              .toList();

          allParticipantIds.addAll(participantIds);

          fetchedChats.add(chatModel);
        }
      }

      // Fetch participant details after fetching all chats
      final participantDetails =
          await _fetchUserDetails(allParticipantIds.toList());

      if (mounted) {
        setState(() {
          chats = fetchedChats;
          this.participantDetails =
              participantDetails; // Update participantDetails
        });
      }

      _logger.i('Fetched ${chats.length} chats with participant details.');
    }).onError((e) {
      _logger.e('Error listening to chat updates: $e');
    });
  }

  // Function to fetch user details based on a list of user IDs
  Future<Map<String, UserModel>> _fetchUserDetails(List<String> userIds) async {
    final userCollection = FirebaseFirestore.instance.collection('users');

    // Fetch user documents
    final userSnapshots = await userCollection
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    // Create a map of user ID to UserModel
    return Map.fromEntries(
      userSnapshots.docs.map((doc) {
        final userData =
            doc.data(); // Get document data as Map<String, dynamic>
        return MapEntry(
            doc.id, UserModel.fromMap(userData)); // Pass the map to fromMap
      }),
    );
  }

  void _updateFilteredChats() {
    // Add this method
    if (searchQuery.isEmpty) {
      filteredChats = chats;
    } else {
      filteredChats = chats.where((chat) {
        final participantId = chat.participants.firstWhere(
          (id) => id != FirebaseAuth.instance.currentUser?.uid,
          orElse: () => '',
        );
        final participant = participantDetails[participantId];
        final participantName = participant?.username.toLowerCase() ?? '';
        return participantName.contains(searchQuery);
      }).toList();
    }
  }

  void _showlogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure Do you want Logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Provider.of<UserProvider>(context, listen: false)
                    .logout(context);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateFilteredChats();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: ifSearch
            ? TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase(); // Update search query
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Color.fromARGB(167, 104, 167, 218),
                ),
              )
            : const Text(
                "ChatJet Messages",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
              ifSearch
                  ? Icons.close
                  : Icons.search, // Change icon based on search state
            ),
            onPressed: () {
              setState(() {
                ifSearch = !ifSearch; // Toggle search field visibility
                if (!ifSearch) {
                  searchQuery =
                      ''; // Clear search query when hiding search field
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _showlogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return ListView.builder(
            itemCount: filteredChats.length, // Use filteredChats
            itemBuilder: (context, index) {
              final chat = filteredChats[index]; // Use filteredChats

              // Extract the first participant ID that is not the current user
              final participantId = chat.participants.firstWhere(
                (id) => id != FirebaseAuth.instance.currentUser?.uid,
                orElse: () => '',
              );

              // Fetch participant details
              final participant = participantDetails[participantId];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: participant != null &&
                          participant.profilePictureURL.isNotEmpty
                      ? NetworkImage(participant.profilePictureURL)
                      : const AssetImage('assets/images.png') as ImageProvider,
                ),
                title: Text(participant?.username ?? 'Unknown'),
                subtitle: Text(
                  chat.lastMessage ?? 'No message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  chat.lastMessageTimestamp != null
                      ? DateFormat('hh:mm a')
                          .format(chat.lastMessageTimestamp!.toDate())
                      : 'No timestamp',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chat.chatId,
                        chatteruid: participantId,
                        chatterName: participant?.username ?? 'Unknown',
                        chatterImageUrl: participant?.profilePictureURL ?? '',
                        isOnline: participant?.isOnline ?? false,
                        lastSeen: participant?.lastLogin.toString() ?? 'N/A',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ContactPage(), // Navigate to contact page
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
