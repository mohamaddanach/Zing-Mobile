import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone.toString();

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
      ),

      body: Column(
        children: [

          const SizedBox(height: 20),

          // 👤 PROFILE HEADER
          CircleAvatar(
            radius: 55,
            backgroundImage: widget.profileUrl.isNotEmpty
                ? NetworkImage(widget.profileUrl)
                : null,
            backgroundColor: Colors.grey[800],
            child: widget.profileUrl.isEmpty
                ? const Icon(Icons.person,
                size: 55, color: Colors.white)
                : null,
          ),

          const SizedBox(height: 10),

          Text(
            widget.username,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),

          Text(
            widget.phone,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 10),

          Text(
            "⭐ ${widget.points.toStringAsFixed(2)} points",
            style: const TextStyle(
                color: Colors.amber, fontSize: 16),
          ),

          const SizedBox(height: 20),

          // 🔥 TABS BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              tabButton("Friends", 0),
              tabButton("Transactions", 1),
              tabButton("Prizes", 2),
            ],
          ),

          const SizedBox(height: 10),

          // 🔥 CONTENT
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

  // ================= TABS =================

  Widget tabButton(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = index);
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selectedTab == index
              ? Colors.amber
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color:
            selectedTab == index ? Colors.black : Colors.white,
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
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                (d['profile_url'] ?? "").isNotEmpty
                    ? NetworkImage(d['profile_url'])
                    : null,
                backgroundColor: Colors.grey[800],
                child: (d['profile_url'] ?? "").isEmpty
                    ? const Icon(Icons.person,
                    color: Colors.white)
                    : null,
              ),
              title: Text(
                d['username'] ?? "",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                d['phone_number'] ?? "",
                style: const TextStyle(color: Colors.grey),
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
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView(
          children: docs.map((doc) {
            final t = doc.data() as Map<String, dynamic>;

            return Card(
              color: const Color(0xFF111827),
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  t['product_name'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "Seller: ${t['seller_name']}\nQty: ${t['quantity']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  "+${t['total_price']}",
                  style: const TextStyle(color: Colors.amber),
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
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView(
          children: docs.map((doc) {
            final p = doc.data() as Map<String, dynamic>;

            return Card(
              color: const Color(0xFF1F2937),
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.emoji_events,
                    color: Colors.amber),
                title: Text(
                  p['prize_name'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "Country: ${p['winner_country']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  "${p['prize_number_of_points_required']} pts",
                  style: const TextStyle(color: Colors.amber),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}