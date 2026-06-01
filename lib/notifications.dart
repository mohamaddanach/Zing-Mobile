import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  Stream<QuerySnapshot> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return FirebaseFirestore.instance
        .collection("notifications")
        .where("receiver_id", isEqualTo: uid)
    // ⚠️ removed orderBy to avoid index crash (you can re-add after creating index)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [

          // 🔵 HEADER
          Container(
            padding: const EdgeInsets.all(12),
            child: const Text(
              "Notifications",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(color: Colors.white24),

          // 🔥 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream(),
              builder: (context, snapshot) {

                // 🔥 FIX LOADING STATE
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      "No notifications",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notifications",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final data =
                    docs[index].data() as Map<String, dynamic>;

                    final id = docs[index].id;

                    final isRead = data['is_read'] ?? false;

                    return Dismissible(
                      key: Key(id),

                      direction: DismissDirection.endToStart,

                      onDismissed: (_) async {
                        await FirebaseFirestore.instance
                            .collection("notifications")
                            .doc(id)
                            .delete();
                      },

                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),

                      child: Container(
                        color: isRead
                            ? Colors.transparent
                            : Colors.white10,

                        child: ListTile(
                          leading: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),

                          title: Text(
                            data['title'] ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(
                            data['body'] ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),

                          trailing: isRead
                              ? const SizedBox()
                              : const Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.red,
                          ),

                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .doc(id)
                                .update({"is_read": true});
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}