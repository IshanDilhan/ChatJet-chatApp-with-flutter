import 'package:chatapp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:chatapp/screens/ChatPages/home_page.dart';
import 'package:chatapp/screens/HomePages/status_screen.dart';
import 'package:chatapp/screens/Chatjet%20AI%20pages/gemini_chat.dart';
import 'package:chatapp/screens/HomePages/contact_page.dart';
import 'package:chatapp/screens/HomePages/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Provider.of<UserProvider>(context, listen: false).initializeFCMToken();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _logger.d('App resumed - setting user online');
        Provider.of<UserProvider>(context, listen: false).setUserOnline();
        break;
      case AppLifecycleState.inactive:
        _logger.d('App inactive');
        Provider.of<UserProvider>(context, listen: false).setUserOffline();
        break;
      case AppLifecycleState.paused:
        _logger.d('App paused - setting user offline');
        Provider.of<UserProvider>(context, listen: false).setUserOffline();
        break;
      case AppLifecycleState.detached:
        _logger.d('App detached');
        Provider.of<UserProvider>(context, listen: false).setUserOffline();
        break;
      case AppLifecycleState.hidden:
        _logger.d('App hidden');
        break;
      default:
        _logger.d('App lifecycle state: $state');
        break;
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(), // Pass parameters later
    const GeminiChatPage(),
    const StatusScreen(),
    const ContactPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(255, 23, 23, 23),
        unselectedItemColor: const Color.fromARGB(255, 92, 86, 86),
        selectedFontSize: 14,
        unselectedFontSize: 12,
        iconSize: 28,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              SimpleIcons.bilibili,
            ),
            label: "AI chat",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Status",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_outlined),
            label: "Contacts",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
            backgroundColor: Colors.white,
          ),
        ],
        selectedLabelStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
