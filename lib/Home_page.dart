import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zing/home.dart';
import 'package:zing/network.dart';
import 'package:zing/login_screen.dart';
import 'package:zing/prize.dart';
import 'package:zing/messages.dart';
import 'package:zing/profile.dart';
import 'liked_products_screen.dart';
import 'saved_products_screen.dart';
import 'notifications.dart';
import 'ai_helper.dart';
class AppColors {
  static const bg = Color(0xFF050816);
  static const card = Color(0xFF111827);

  static const red = Color(0xFFE11D48);
  static const redLight = Color(0xFFFF4D6D);

  static const white = Colors.white;
  static const grey = Color(0xFF94A3B8);
}

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
  final List<Map<String, dynamic>> categories = const [
    {
      "title": "Electronics",
      "icon": Icons.devices,
      "color": Colors.blue,
    },
    {
      "title": "Home",
      "icon": Icons.chair,
      "color": Colors.green,
    },
    {
      "title": "Fashion",
      "icon": Icons.checkroom,
      "color": Colors.purple,
    },
    {
      "title": "Offers",
      "icon": Icons.local_offer,
      "color": Colors.red,
    },
  ];
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;

  String username = "";
  String phone = "";
  String country = "";
  String profileUrl = "";
  double points = 0.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  void _listenToUserData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      _logout();
      return;
    }

    FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        _logout();
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        username = data['username'] ?? widget.username;
        phone = data['phone_number'] ?? "";
        country = data['country'] ?? "";
        profileUrl = data['profile_url'] ?? "";
        points = (data['number_of_points'] ?? 0).toDouble();
        isLoading = false;
      });
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  List<Widget> get _pages => [
    const home(),
    Net(
      username: username,
      userphonenumber: phone,
      country: country,
    ),
    Messages(
      username: username,
      userphonenumber: phone,
      country: country,
    ),
    PrizePage(
      username: username,
      userphonenumber: phone,
      country: country,
    ),
    ai_helper()
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.red),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,

      // 🔴 IDEALZ STYLE APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.red,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ZING",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const NotificationsPanel(),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // 🔥 DRAWER (MODERN IDEALZ STYLE)
      drawer: Drawer(
        backgroundColor: AppColors.card,
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 70, left: 20, right: 20, bottom: 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.red,
                    Color(0xFF0B0F1A),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  CircleAvatar(
                    radius: 35,
                    backgroundImage: profileUrl.isNotEmpty
                        ? NetworkImage(profileUrl)
                        : null,
                    child: profileUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    phone,
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "$points Points",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              title: const Text(
                "Liked products",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LikedProductsScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.bookmark,
                color: Colors.orange,
              ),
              title: const Text(
                "Saved products",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedProductsScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text("Profile",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => profile(
                      username: username,
                      phone: phone,
                      country: country,
                      profileUrl: profileUrl,
                      points: points,
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔥 BODY
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[currentPageIndex],
      ),

      // 🔴 IDEALZ STYLE BOTTOM NAV
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 15,
            )
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: currentPageIndex,
          indicatorColor: Colors.white.withOpacity(0.2),
          onDestinationSelected: (index) {
            setState(() => currentPageIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.home, color: Colors.white),
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(Icons.hub_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.hub, color: Colors.white),
              label: "Network",
            ),
            NavigationDestination(
              icon: Icon(Icons.message_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.message, color: Colors.white),
              label: "Shared",
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.emoji_events, color: Colors.white),
              label: "Prizes",
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.smart_toy, color: Colors.white),
              label: "AI Assistant",
            ),
          ],
        ),
      ),
    );
  }
}