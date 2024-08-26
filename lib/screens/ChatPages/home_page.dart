import 'package:chatapp/controlers/user_controler.dart';
import 'package:chatapp/models/chat_model.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:chatapp/providers/chat_provider.dart';
import 'package:chatapp/screens/ChatPages/chat_page.dart';
import 'package:chatapp/screens/HomePages/contact_page.dart';
import 'package:chatapp/screens/SignInPages/loging_screen.dart';
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
  User? currentuser = FirebaseAuth.instance.currentUser;

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

    try {
      final chatCollection = FirebaseFirestore.instance.collection('chats');
      final chatSnapshots = await chatCollection.get();

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
    } catch (e) {
      _logger.e('Error fetching chats: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          "ChatJet Messages",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality here
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final userController = UserController();
              try {
                await userController.signOut();
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } catch (error) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $error')),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

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
