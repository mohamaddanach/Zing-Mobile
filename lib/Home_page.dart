import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zing/home.dart';
import 'package:zing/network.dart';
import 'package:zing/login_screen.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
  String? ph_nbr;
  String? country;
  bool isLoading = true;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Inside _HomePageState
  String? userCountry; // New variable

  void _fetchUserData() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .get();

        if (documentSnapshot.exists) {
          Map<String, dynamic> userData = documentSnapshot.data() as Map<String, dynamic>;

          // Extracting all three fields now
          String fetchedPhone = userData['phone_number']?.toString() ?? "No Phone";
          String fetchedCountry = userData['country']?.toString() ?? "No Country";

          setState(() {
            ph_nbr = fetchedPhone;
            userCountry = fetchedCountry;

            _pages = [
              const home(),
              net(
                username: widget.username,
                userphonenumber: fetchedPhone,
                country: fetchedCountry, // Passing the new field
              ),
            ];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        debugPrint("Error: $e");
        setState(() => isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Show a loader while fetching data from Firestore
    if (isLoading || ph_nbr == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zing Home", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white), // Makes drawer icon white
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0F172A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 30,
                    child: Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Hey ${widget.username}!",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  )
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
            )
          ],
        ),
      ),
      body: _pages[currentPageIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.hub),
            icon: Icon(Icons.hub_outlined),
            label: 'Network',
          ),
        ],
      ),
    );
  }
}