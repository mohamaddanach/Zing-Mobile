import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:zing/show_products.dart'; // Make sure the path matches your project layout

class LikedProductsScreen extends StatelessWidget {
  const LikedProductsScreen({super.key});

  // 🟢 Helper method to decode or fallback images cleanly
  Widget imageWidget(Map<String, dynamic> data) {
    try {
      final images = data['images'];
      String value;

      if (images != null && images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String && images.isNotEmpty) {
        value = images;
      } else {
        return Image.network(
          "https://via.placeholder.com/150",
          fit: BoxFit.cover,
        );
      }

      if (value.startsWith("http")) {
        return Image.network(value, fit: BoxFit.cover);
      }

      if (value.contains(",")) {
        value = value.split(",").last;
      }

      return Image.memory(base64Decode(value), fit: BoxFit.cover);
    } catch (_) {
      return Image.network(
        "https://via.placeholder.com/150",
        fit: BoxFit.cover,
      );
    }
  }

  // 🟢 Dependency injection requirement for ShowProducts
  double calcPoints(Map<String, dynamic> data) {
    final raw = data['bonus_reserve'];
    if (raw == null) return 0;
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  // 🟢 Handles removing the items from the subcollection
  Future<void> deleteFromLikes(String userId, String productId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('liked_products')
        .doc(productId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Liked Products",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('liked_products')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final likedDocs = snapshot.data!.docs;

          if (likedDocs.isEmpty) {
            return const Center(child: Text("No liked products yet"));
          }

          return ListView.builder(
            itemCount: likedDocs.length,
            itemBuilder: (context, index) {
              final likedData = likedDocs[index].data() as Map<String, dynamic>;
              final productId = likedData['product_id'];
              final collection = likedData['collection'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(collection)
                    .doc(productId)
                    .get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final product = productSnapshot.data!.data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 85,
                            height: 85,
                            child: imageWidget(product),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['product_name'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "\$${product['priceonplatform']}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                collection.replaceFirst('products_', '').toUpperCase(),
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                        // 🟢 3 VERTICAL DOTS POPUP MENU ON THE RIGHT
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.black54),
                          onSelected: (value) {
                            if (value == 'view') {
                              // Open the bottom modal sheet layout
                              ShowProducts.showProductDetails(
                                context: context,
                                data: product,
                                productId: productId,
                                collection: collection,
                                imageWidget: imageWidget,
                                calcPoints: calcPoints,
                                shareProduct: (data, id, col) {
                                  // Call your sharing framework directly or show snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Use Home interface to share directly with friends")),
                                  );
                                },
                              );
                            } else if (value == 'delete') {
                              deleteFromLikes(user.uid, productId);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("View Product"),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Delete from Like", style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}