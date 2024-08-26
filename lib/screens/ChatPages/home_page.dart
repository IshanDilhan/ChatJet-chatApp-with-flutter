import 'package:chatapp/controlers/user_controler.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:chatapp/screens/SignInPages/loging_screen.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserData(context);
  }

  final Logger _logger = Logger();
  Future<void> _loadUserData(context) async {
    try {
      await Provider.of<UserProvider>(context, listen: false).loadUserData();
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        _logger.i("User data loaded successfully: ${user.username}");
      } else {
        _logger.w("User data could not be loaded.");
      }
    } catch (error) {
      _logger.e("Error loading user data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          "ChatJet Messages",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Add search functionality here
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              UserController userController = UserController();
              try {
                await userController.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } catch (error) {
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
              itemCount: 20, // Replace with actual chat count later
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                        'https://via.placeholder.com/150'), // Placeholder for user's avatar
                  ),
                  title: Text("Chatter ${index + 1}"),
                  subtitle: Text(
                    "Last message snippet goes here...",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      Text("12:00 PM"), // Placeholder for last message time
                  onTap: () {
                    // Navigate to chat screen
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
