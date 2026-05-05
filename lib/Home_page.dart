import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zing/home.dart';
import 'package:zing/network.dart';
import 'package:zing/login_screen.dart';
import 'package:zing/prize.dart';
import 'package:zing/messages.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String phone;
  final String country;
  final String profileUrl;
  final double points;

  const HomePage({
    super.key,
    required this.username,
    required this.phone,
    required this.country,
    required this.profileUrl,
    required this.points,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;

  String? phone;
  String? country;
  String? profileUrl;

  // ✅ FIX: MUST BE DOUBLE (NOT INT)
  double points = 0.0;

  bool isLoading = true;

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      _logout();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!doc.exists) {
        _logout();
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        phone = data['phone_number'] ?? "";
        country = data['country'] ?? "";
        profileUrl = data['profile_url'] ?? "";

        // ✅ FIX: FORCE DOUBLE
        points = (data['number_of_points'] ?? 0).toDouble();

        _pages = [
          const home(),
          Net(
            username: widget.username,
            userphonenumber: phone ?? "",
            country: country ?? "",
          ),
          Messages(
            username: widget.username,
            userphonenumber: phone ?? "",
            country: country ?? "",
          ),
          prize(),
        ];

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading user: $e");
      setState(() => isLoading = false);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F172A)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Zing Home",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                    profileUrl != null && profileUrl!.isNotEmpty
                        ? NetworkImage(profileUrl!)
                        : null,
                    child: profileUrl == null || profileUrl!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Hey ${widget.username}!",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    "Points: $points",
                    style: const TextStyle(color: Colors.amber),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),

      body: currentPageIndex < _pages.length
          ? _pages[currentPageIndex]
          : const SizedBox(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (index) {
          setState(() => currentPageIndex = index);
        },
        indicatorColor: Colors.amber,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub),
            label: "Network",
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: "Messages",
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: "Prizes",
          ),
        ],
      ),
    );
  }
}