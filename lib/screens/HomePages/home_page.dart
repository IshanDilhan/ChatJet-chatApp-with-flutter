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
    _loadUserData();
  }

  Logger _logger = Logger();
  Future<void> _loadUserData() async {
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
    Size size = MediaQuery.of(context).size;
    final fretcheduser = Provider.of<UserProvider>(context).user;

    return Scaffold(
      // ignore: sized_box_for_whitespace
      body: Container(
        width: double.infinity,
        height: size.height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                "assets/images/top1.png",
                width: size.width,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                "assets/images/top2.png",
                width: size.width,
              ),
            ),
            Positioned(
              top: 50,
              right: 30,
              child: Image.asset(
                "assets/images/main.png",
                width: size.width * 0.35,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                "assets/images/bottom1.png",
                width: size.width,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                "assets/images/bottom2.png",
                width: size.width,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Hello, ${fretcheduser?.username ?? 'User'}!",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2661FA),
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                Container(
                  alignment: Alignment.center,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: ElevatedButton(
                    onPressed: () async {
                      UserController userController = UserController();
                      try {
                        await userController.signOut();
                        // Navigate to login page after logout
                        Navigator.pushReplacement(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      } catch (error) {
                        // Handle logout error
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logout failed: $error')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
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
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 255, 136, 34),
                            Color.fromARGB(255, 255, 177, 41),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(0),
                      child: const Text(
                        "Logout",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
