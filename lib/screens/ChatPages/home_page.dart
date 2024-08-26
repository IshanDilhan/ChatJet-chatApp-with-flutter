import 'package:chatapp/controlers/user_controler.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:chatapp/providers/chat_provider.dart';
import 'package:chatapp/screens/HomePages/contact_page.dart';
import 'package:chatapp/screens/SignInPages/loging_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _chats = [];

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
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user != null) {
        await chatProvider.fetchChatsForUser(user);
        setState(() {
          _chats = chatProvider.chats.values.map((chat) {
            return {
              'chatId': chat.chatId, // Include chatId
              'name': chat.chatName ?? 'Unknown',
              'image': chat.chatImageURL ?? 'https://via.placeholder.com/150',
              'lastMessage': chat.lastMessage ?? '',
              'lastMessageTime': chat.lastMessageTimestamp != null
                  ? TimeOfDay.fromDateTime(chat.lastMessageTimestamp!.toDate())
                      .format(context)
                  : 'Unknown',
            };
          }).toList();
        });
      }
    } catch (error) {
      _logger.e("Error fetching chats: $error");
    }
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(chat['image']!),
                  ),
                  title: Text(chat['name']!),
                  subtitle: Text(
                    chat['lastMessage']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(chat['lastMessageTime']!),
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => ChatPage(
                    //       chatteruid: ,
                    //       chatId: chat['chatId']!, // Pass chatId to ChatPage
                    //       chatterName: chat['name']!,
                    //       chatterImageUrl: chat['image']!,
                    //       isOnline: false, // Determine if online dynamically
                    //       lastSeen:
                    //           'Yesterday', // Provide actual last seen information
                    //     ),
                    //   ),
                    // );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const ContactPage()), // Navigate to contact page
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
