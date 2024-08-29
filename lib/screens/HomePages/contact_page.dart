import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatapp/providers/user_provider.dart';
import 'package:chatapp/screens/HomePages/all_contacts.dart';
import 'package:chatapp/screens/HomePages/my_contact.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.fetchAllUsers();

    // Load user contacts
    // Fetch all users
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 90, 91, 93),
          elevation: 2, // Reduced elevation
          toolbarHeight: 36, // Reduced height
          bottom: PreferredSize(
            preferredSize:
                const Size.fromHeight(40.0), // Reduced height of TabBar
            child: TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 2, // Thinner indicator
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle:
                  GoogleFonts.lato(fontSize: 14), // Google Font for label
              tabs: const [
                Tab(
                  text: 'My Contacts',
                  icon: Icon(Icons.person),
                ),
                Tab(
                  text: 'All Contacts',
                  icon: Icon(Icons.group),
                ),
              ],
              indicatorSize: TabBarIndicatorSize.label,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 10.0),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            MyContactsPage(),
            AllContactsPage(),
          ],
        ),
      ),
    );
  }
}
