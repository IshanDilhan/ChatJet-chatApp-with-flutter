import 'package:chatapp/screens/ChatPages/home_page.dart';
import 'package:chatapp/screens/HomePages/status_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatapp/screens/HomePages/contact_page.dart';
import 'package:chatapp/screens/HomePages/profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), // Pass parameters later
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
        selectedItemColor: const Color.fromARGB(
            255, 23, 23, 23), // Color for the selected item
        unselectedItemColor:
            const Color.fromARGB(255, 92, 86, 86), // Color for unselected items
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
            icon: Icon(Icons.insert_chart_outlined),
            label: "Status",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            label: "Contacts",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
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
