import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Net extends StatefulWidget {
  final String username;
  final String userphonenumber;
  final String country;

  const Net({
    super.key,
    required this.username,
    required this.userphonenumber,
    required this.country,
  });

  @override
  State<Net> createState() => _NetState();
}

class _NetState extends State<Net> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      // 🔵 MODERN APP BAR
      appBar: AppBar(
        title: const Text(
          "Zing Network",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [

              const SizedBox(height: 12),

              // 🔍 MODERN SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search users...",
                    prefixIcon: Icon(Icons.search, color: Colors.blue),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 🔥 USERS LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userphonenumber)
                      .collection('friends_list')
                      .snapshots(),
                  builder: (context, friendsSnapshot) {

                    if (friendsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final friendsPhones = friendsSnapshot.data!.docs
                        .map((doc) => doc['phone_number'] as String)
                        .toSet();

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('country', isEqualTo: widget.country)
                          .snapshots(),
                      builder: (context, usersSnapshot) {

                        if (!usersSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final users = usersSnapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final phone = data['phone_number'];

                          return phone != widget.userphonenumber &&
                              !friendsPhones.contains(phone);
                        }).toList();

                        if (users.isEmpty) {
                          return const Center(
                            child: Text(
                              "No new users in your country",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userData =
                            users[index].data() as Map<String, dynamic>;

                            String name = userData['username'] ?? 'User';
                            String phone = userData['phone_number'] ?? '';
                            String imageUrl = userData['profile_url'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Row(
                                children: [

                                  // 🧑 PROFILE IMAGE
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.shade100,
                                    backgroundImage: imageUrl.isNotEmpty
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl.isEmpty
                                        ? const Icon(Icons.person, color: Colors.white)
                                        : null,
                                  ),

                                  const SizedBox(width: 12),

                                  // NAME + PHONE
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          phone,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔵 ADD FRIEND BUTTON (UPDATED)
                                  ElevatedButton(
                                    onPressed: () =>
                                        _addFriend(name, phone, imageUrl),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Add"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addFriend(
      String name, String phone, String image) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userphonenumber)
          .collection('friends_list')
          .doc(phone)
          .set({
        'username': name,
        'phone_number': phone,
        'profile_url': image,
        'added_on': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added $name")),
      );
    } catch (e) {
      print(e);
    }
  }
}