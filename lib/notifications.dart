import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:zing/show_products.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Widget _imageWidget(Map<String, dynamic> data) {
    try {
      final images = data['images'];
      String value;

      if (images != null && images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String && images.isNotEmpty) {
        value = images;
      } else {
        return Image.network("https://via.placeholder.com/150", fit: BoxFit.cover);
      }

      if (value.startsWith("http")) return Image.network(value, fit: BoxFit.cover);
      if (value.contains(",")) value = value.split(",").last;

      return Image.memory(base64Decode(value), fit: BoxFit.cover);
    } catch (_) {
      return Image.network("https://via.placeholder.com/150", fit: BoxFit.cover);
    }
  }

  double calcPoints(Map<String, dynamic> data) {
    final raw = data['bonus_reserve'];
    if (raw == null) return 0;
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view notifications")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // 🟢 STEP 1: Get the user's phone_number from Firestore first
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          final firestorePhone = userData?['phone_number'] ?? "";
          final authPhone = user.phoneNumber ?? "";

          // Build a list of every possible value receiver_id might have
          final possibleIds = <String>{
            user.uid,
            if (firestorePhone.isNotEmpty) firestorePhone,
            if (authPhone.isNotEmpty) authPhone,
          }.toList();

          debugPrint("🔔 Querying notifications with: $possibleIds");

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('receiver_id', whereIn: possibleIds)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              }

              final notifications = snapshot.data!.docs;

              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "All caught up! No notifications yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final doc = notifications[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isRead = data['is_read'] ?? false;

                  return GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(doc.id)
                          .update({'is_read': true});

                      final targetId = data['target_id'];
                      final targetCollection = data['collection'];

                      if (targetId != null &&
                          targetCollection != null &&
                          context.mounted) {
                        final productDoc = await FirebaseFirestore.instance
                            .collection(targetCollection)
                            .doc(targetId)
                            .get();

                        if (productDoc.exists && context.mounted) {
                          final productData =
                          productDoc.data() as Map<String, dynamic>;
                          ShowProducts.showProductDetails(
                            context: context,
                            data: productData,
                            productId: targetId,
                            collection: targetCollection,
                            imageWidget: _imageWidget,
                            calcPoints: calcPoints,
                            shareProduct: (pData, pId, col) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Use Home screen to reshare with friends."),
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRead
                              ? Colors.grey.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.grey.shade100
                                  : const Color(0xFFFFEBEE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              data['type'] == 'share'
                                  ? Icons.card_giftcard_rounded
                                  : Icons.notifications_active_outlined,
                              color: isRead ? Colors.grey : Colors.red,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['body'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4, left: 4),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
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