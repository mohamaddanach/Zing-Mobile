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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Zing Network",
            style: TextStyle(color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 🔍 Search Bar (optional filtering later)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search in Network...",
                    prefixIcon:
                    Icon(Icons.search, color: Color(0xFF0F172A)),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 MAIN LOGIC
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // 1️⃣ Listen to friends_list
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userphonenumber)
                      .collection('friends_list')
                      .snapshots(),
                  builder: (context, friendsSnapshot) {
                    if (friendsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    // 📌 Extract friend phone numbers
                    final friendsPhones = friendsSnapshot.data!.docs
                        .map((doc) => doc['phone_number'] as String)
                        .toSet();

                    // 2️⃣ Listen to all users
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('country',
                          isEqualTo: widget.country)
                          .snapshots(),
                      builder: (context, usersSnapshot) {
                        if (usersSnapshot.hasError) {
                          return const Center(
                              child: Text("Connection Error"));
                        }

                        if (usersSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // 🔥 FILTER USERS
                        final otherUsers =
                        usersSnapshot.data!.docs.where((doc) {
                          final data =
                          doc.data() as Map<String, dynamic>;

                          final phone = data['phone_number'];

                          return phone !=
                              widget.userphonenumber &&
                              !friendsPhones.contains(phone);
                        }).toList();

                        if (otherUsers.isEmpty) {
                          return const Center(
                            child: Text("There is no new firends in your country"),
                          );
                        }

                        return ListView.builder(
                          itemCount: otherUsers.length,
                          itemBuilder: (context, index) {
                            var userData =
                            otherUsers[index].data()
                            as Map<String, dynamic>;

                            String name =
                                userData['username'] ?? 'User';
                            String phone =
                                userData['phone_number'] ??
                                    'No number';
                            String imageUrl =
                                userData['profile_url'] ?? '';

                            return Card(
                              margin:
                              const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                contentPadding:
                                const EdgeInsets.all(10),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                  const Color(0xFF0F172A),
                                  backgroundImage:
                                  imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl.isEmpty
                                      ? const Icon(Icons.person,
                                      color: Colors.white,
                                      size: 30)
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                                subtitle: Text(phone),
                                trailing: ElevatedButton(
                                  onPressed: () => _addFriend(
                                      name, phone, imageUrl),
                                  style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF0F172A),
                                    foregroundColor:
                                    Colors.white,
                                  ),
                                  child:
                                  const Text("Add Friend"),
                                ),
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

  // ✅ Add friend
  Future<void> _addFriend(
      String name, String phone, String image) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userphonenumber)
          .collection('friends_list')
          .doc(phone) // unique per friend
          .set({
        'username': name,
        'phone_number': phone,
        'profile_url': image,
        'added_on': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added $name as a friend!")),
      );
    } catch (e) {
      print("Error adding friend: $e");
    }
  }
}