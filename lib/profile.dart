import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppColors {
  static const bg = Color(0xFF050816);
  static const card = Color(0xFF111827);

  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFF60A5FA);

  static const white = Colors.white;
  static const grey = Color(0xFF94A3B8);
}

class profile extends StatefulWidget {
  final String username;
  final String phone;
  final String country;
  final String profileUrl;
  final double points;

  const profile({
    super.key,
    required this.username,
    required this.phone,
    required this.country,
    required this.profileUrl,
    required this.points,
  });

  @override
  State<profile> createState() => _ProfileState();
}

class _ProfileState extends State<profile> {
  int selectedTab = 0;

  double getDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone.toString();

    return Scaffold(
      backgroundColor: AppColors.bg,

      appBar: AppBar(
        backgroundColor: AppColors.card,
        centerTitle: true,
        title: const Text(
          "PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [

          const SizedBox(height: 20),

          // 👤 HEADER CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [

                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.profileUrl.isNotEmpty
                      ? NetworkImage(widget.profileUrl)
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: widget.profileUrl.isEmpty
                      ? const Icon(Icons.person,
                      size: 50, color: Colors.white)
                      : null,
                ),

                const SizedBox(height: 10),

                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  widget.phone,
                  style: const TextStyle(color: AppColors.grey),
                ),

                const SizedBox(height: 10),

                Text(
                  "⭐ ${getDouble(widget.points).toStringAsFixed(2)} Points",
                  style: const TextStyle(
                    color: AppColors.blueLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 🔵 TABS (BLUE STYLE BUTTONS)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              tabButton("Friends", 0),
              tabButton("Transactions", 1),
              tabButton("Prizes", 2),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                friendsSection(phone),
                transactionsSection(phone),
                prizesSection(phone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB BUTTON =================
  Widget tabButton(String title, int index) {
    final isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.blue.withOpacity(0.4),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= FRIENDS =================
  Widget friendsSection(String phone) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .collection('friends_list')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("No friends yet",
                style: TextStyle(color: AppColors.grey)),
          );
        }

        return ListView(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;

            return Card(
              color: AppColors.card,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.blue,
                  backgroundImage: (d['profile_url'] ?? "").isNotEmpty
                      ? NetworkImage(d['profile_url'])
                      : null,
                  child: (d['profile_url'] ?? "").isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  d['username'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  d['phone_number'] ?? "",
                  style: const TextStyle(color: AppColors.grey),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= TRANSACTIONS =================
  Widget transactionsSection(String phone) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('phone_number', isEqualTo: phone)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("No transactions",
                style: TextStyle(color: AppColors.grey)),
          );
        }

        return ListView(
          children: docs.map((doc) {
            final t = doc.data() as Map<String, dynamic>;

            return Card(
              color: AppColors.card,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                title: Text(
                  t['product_name'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "Seller: ${t['seller_name']}",
                  style: const TextStyle(color: AppColors.grey),
                ),
                trailing: Text(
                  "+${getDouble(t['total_price']).toStringAsFixed(2)}",
                  style: const TextStyle(color: AppColors.blueLight),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= PRIZES =================
  Widget prizesSection(String phone) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users_prizes')
          .where('winner_phone_number', isEqualTo: phone)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("No prizes yet",
                style: TextStyle(color: AppColors.grey)),
          );
        }

        return ListView(
          children: docs.map((doc) {
            final p = doc.data() as Map<String, dynamic>;

            return Card(
              color: AppColors.card,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.emoji_events,
                    color: AppColors.blue),
                title: Text(
                  p['prize_name'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  p['winner_country'] ?? "",
                  style: const TextStyle(color: AppColors.grey),
                ),
                trailing: Text(
                  "${getDouble(p['total_points_used']).toStringAsFixed(0)} pts",
                  style: const TextStyle(color: AppColors.blueLight),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}