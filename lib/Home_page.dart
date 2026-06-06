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
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Instagram light theme
  static const bg = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const text = Color(0xFF262626);
  static const grey = Color(0xFF8E8E8E);
  static const divider = Color(0xFFDBDBDB);
  static const blue = Color(0xFF0095F6);
  static const danger = Color(0xFFED4956);

  // Iconic Instagram brand gradient
  static const gradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFFEDA77),
      Color(0xFFF58529),
      Color(0xFFDD2A7B),
      Color(0xFF8134AF),
      Color(0xFF515BD4),
    ],
  );
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
    {"title": "Electronics", "icon": Icons.devices, "color": Colors.blue},
    {"title": "Home", "icon": Icons.chair, "color": Colors.green},
    {"title": "Fashion", "icon": Icons.checkroom, "color": Colors.purple},
    {"title": "Offers", "icon": Icons.local_offer, "color": Colors.red},
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
    AiHelper(),
  ];

  // ---------------------------------------------------------------------------
  // STORY-RING AVATAR (Instagram gradient ring)
  // ---------------------------------------------------------------------------
  Widget _normalAvatar({double radius = 34}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.divider,
      backgroundImage:
      profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
      child: profileUrl.isEmpty
          ? Icon(Icons.person, color: AppColors.grey, size: radius)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAV ITEM (labelless, flat — Instagram style)
  // ---------------------------------------------------------------------------
  Widget _navItem(int index, IconData outline, IconData filled) {
    final selected = currentPageIndex == index;

    Widget iconWidget = Icon(
      selected ? filled : outline,
      color: selected ? AppColors.text : AppColors.grey,
      size: selected ? 29 : 26,
    );

    // Apply gradient color to the active icon
    if (selected) {
      iconWidget = ShaderMask(
        shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
        child: Icon(filled, color: Colors.white, size: 29),
      );
    }

    return Expanded(
      child: InkResponse(
        onTap: () => setState(() => currentPageIndex = index),
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top indicator bar — thicker and only visible when selected
              Container(
                height: 3,
                width: 28,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.gradient : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              iconWidget,
              const SizedBox(height: 2),
              // Small dot under the active item for extra clarity
              Container(
                height: 4,
                width: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.text : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.text,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,

      // ───────────────────────── APP BAR (Instagram style) ─────────────────
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
          child: Text(
            "ZING",
            style: GoogleFonts.pacifico(
              color: Colors.white, // needed so ShaderMask shows the gradient
              fontSize: 30,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            splashRadius: 22,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const NotificationsPanel(),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.text,
            ),
          ),
          IconButton(
            splashRadius: 22,
            onPressed: () {
              setState(() => currentPageIndex = 2); // open "Shared"
            },
            icon: const Icon(Icons.send_outlined, color: AppColors.text),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(height: 0.6, color: AppColors.divider),
        ),
      ),

      // ───────────────────────── DRAWER (Instagram style) ──────────────────
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    _normalAvatar(radius: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Points pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF58529), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "$points Points",
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: AppColors.divider, height: 24),

              _DrawerTile(
                icon: Icons.favorite_border,
                label: "Liked products",
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
              _DrawerTile(
                icon: Icons.bookmark_border,
                label: "Saved products",
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
              _DrawerTile(
                icon: Icons.person_outline,
                label: "Profile",
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
              const Divider(color: AppColors.divider, height: 1),

              // Log out
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text(
                  "Log out",
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _logout,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      // ───────────────────────── BODY ──────────────────────────────────────
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pages[currentPageIndex],
      ),

      // ───────────────────────── BOTTOM NAV (Instagram style) ──────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.6),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home),
              _navItem(1, Icons.search_outlined, Icons.search),
              _navItem(2, Icons.send_outlined, Icons.send),
              _navItem(3, Icons.emoji_events_outlined, Icons.emoji_events),
              _navItem(4, Icons.smart_toy_outlined, Icons.smart_toy),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Instagram-style drawer row
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text, size: 26),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}