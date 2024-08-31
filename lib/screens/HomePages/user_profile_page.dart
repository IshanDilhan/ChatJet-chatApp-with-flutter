import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
  }

  Future<UserModel> _fetchUserData() async {
    Provider.of<UserProvider>(context, listen: false);
    // Fetch user data based on ID
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    } else {
      throw Exception('User not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('User not found'));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
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
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.width * 0.4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: user.profilePictureURL.isNotEmpty
                                  ? NetworkImage(user.profilePictureURL)
                                  : const AssetImage('assets/images.png')
                                      as ImageProvider,
                            ),
                            border: Border.all(
                              color: const Color(0xFF2661FA),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Color(0xFF2661FA),
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                Text(
                  user.mobileNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                Text(
                  user.bio.isNotEmpty ? user.bio : 'Hi, I am using ChatJet...',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Text(
                      'Location: ${user.location.isNotEmpty ? user.location : 'Not added'}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Interests: ${user.interests.isNotEmpty ? user.interests.join(', ') : 'not added'}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      // ignore: unnecessary_null_comparison
                      'Last login: ${user.lastLogin != null ? DateFormat('MMMM d, yyyy h:mm a').format(user.lastLogin) : 'Not specified'}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      // ignore: unnecessary_null_comparison
                      'Created: ${user.createdAt != null ? DateFormat('MMMM d, yyyy h:mm a').format(user.createdAt) : 'Not specified'}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
