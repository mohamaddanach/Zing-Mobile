import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectFriendScreen extends StatelessWidget {
  final String myPhone;

  const SelectFriendScreen({
    super.key,
    required this.myPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Friend"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(myPhone)
            .collection('friends_list')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data!.docs;

          if (friends.isEmpty) {
            return const Center(child: Text("No friends found"));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final data =
              friends[index].data() as Map<String, dynamic>;

              String name = data['username'] ?? "User";
              String phone = data['phone_number'] ?? "";
              String image = data['profile_url'] ?? "";

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  image.isNotEmpty ? NetworkImage(image) : null,
                  child: image.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(name),
                subtitle: Text(phone),

                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Selected $name")),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}