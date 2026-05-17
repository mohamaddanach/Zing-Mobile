import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:zing/show_products.dart'; // Ensure this matches your project layout

class SellerProfile extends StatelessWidget {
  final String sellerName;

  const SellerProfile({
    super.key,
    required this.sellerName,
  });

  // 🟢 Null-safe image decoder and fallback widget for ShowProducts & lists
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

  // 🟢 Dependency injection requirement for rendering points inside ShowProducts
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Seller Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("sellers")
            .where("name", isEqualTo: sellerName)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Seller not found"));
          }

          final seller = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final joinedAt = (seller['joinedAt'] as Timestamp?)?.toDate();
          final year = joinedAt?.year ?? "Unknown";
          final category = seller['product_category'] ?? "electronics";
          final collectionString = "products_$category";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: seller['profile_image'] != null
                      ? NetworkImage(seller['profile_image'])
                      : null,
                  child: seller['profile_image'] == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  seller['name'] ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Joined: $year",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "Country: ${seller['country'] ?? ""}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Seller Products",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(collectionString)
                      .where("seller_name", isEqualTo: sellerName)
                      .where("status", isEqualTo: true)
                      .snapshots(),
                  builder: (context, productSnap) {
                    if (!productSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final products = productSnap.data!.docs;

                    if (products.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text("No products listed yet"),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final doc = products[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final productId = doc.id;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: imageWidget(data),
                              ),
                            ),
                            title: Text(
                              data['product_name'] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "\$${data['priceonplatform'] ?? 0}",
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),

                            // 🟢 THE 3 DOT MENU FOR THE SELLER PAGE (ONLY VIEW OPTION)
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.black54),
                              onSelected: (value) {
                                if (value == 'view') {
                                  ShowProducts.showProductDetails(
                                    context: context,
                                    data: data,
                                    productId: productId,
                                    collection: collectionString,
                                    imageWidget: imageWidget,
                                    calcPoints: calcPoints,
                                    shareProduct: (productData, id, col) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Use Home interface to share directly with friends"),
                                        ),
                                      );
                                    },
                                  );
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
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}