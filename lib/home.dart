import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zing/purchase_dialog.dart';
import 'select_friend_screen.dart';
import 'transaction_service.dart';
import 'more_by_categoty.dart';
class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {

  double clean(double value) =>
      double.parse(value.toStringAsFixed(2));

  double calcPoints(Map<String, dynamic> data) {
    final raw = data['bonus_reserve'];

    if (raw == null) return 0;

    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0;

    return 0;
  }

  Widget _imageWidget(Map<String, dynamic> data) {
    try {
      final images = data['images'];
      String value;

      if (images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String) {
        value = images;
      } else {
        return Image.network("https://via.placeholder.com/150", fit: BoxFit.cover);
      }

      if (value.startsWith("http")) {
        return Image.network(value, fit: BoxFit.cover);
      }

      if (value.contains(",")) {
        value = value.split(",").last;
      }

      return Image.memory(base64Decode(value), fit: BoxFit.cover);

    } catch (_) {
      return Image.network("https://via.placeholder.com/150", fit: BoxFit.cover);
    }
  }
  void openCategoryPage(String title, String collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => all_in_one_category(
          title: title,
          collection: collection,
        ),
      ),
    );
  }
  Future<void> shareProduct(
      Map<String, dynamic> product,
      String productId,
      )  async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    String phone = userDoc.data()?['phone_number'] ?? "";
    if (phone.isEmpty) phone = user.phoneNumber ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [

              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Text(
                "Select Friend",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(phone)
                      .collection('friends_list')
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final friends = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend =
                        friends[index].data() as Map<String, dynamic>;

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(friend['username'] ?? ""),
                          subtitle: Text(friend['phone_number'] ?? ""),

                          onTap: () async {
                            Navigator.pop(context);

                            // ✅ SAVE SHARE
                            await FirebaseFirestore.instance
                                .collection("shared_products")
                                .add({
                              "product_id": productId,
                              "product_name": product['product_name'] ?? "",
                              "product_image":
                              (product['images'] is List &&
                                  product['images'].isNotEmpty)
                                  ? product['images'][0]
                                  : product['images'] ?? "",

                              "price": product['priceonplatform'] ?? 0,
                              "seller_name": product['seller_name'] ?? "",

                              "sender_uid": user.uid,
                              "sender_phone": phone,
                              "sender_name": userDoc.data()?['username'] ?? "",

                              "receiver_phone": friend['phone_number'] ?? "",
                              "receiver_name": friend['username'] ?? "",

                              "status": "pending",
                              "timestamp": FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Shared with ${friend['username']}"),
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
        );
      },
    );
  }

  // 🎨 PRODUCT CARD (UPDATED)
  Widget productCard(Map<String, dynamic> data, String productId) {
    return Container(
      width: 190,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [

          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: _imageWidget(data),
              ),
            ),
          ),

          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    data['product_name'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Text(
                    "\$${data['priceonplatform']}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                      "${calcPoints(data).toStringAsFixed(0)} pts",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),

                  Row(
                    children: [

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            PurchaseDialog.show(
                              context: context,
                              data: data,
                              onConfirm: (qty, paymentMethod) async {
                                await TransactionService.processPurchase(
                                  productData: data,
                                  quantity: qty,
                                  source: "home",
                                  paymentMethod: paymentMethod,
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Buy"),
                        ),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: OutlinedButton(
                        onPressed: () => shareProduct(data, productId),
                          child: const Text("Share"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget categorySection(String title, String collection, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.all(12),
          child:
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(
                children: [
                  Icon(icon, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              TextButton(
                onPressed: () {
                  openCategoryPage(title, collection);
                },
                child: const Text(
                  "More...",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            ],
          ),
        ),

        SizedBox(
          height: 270,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
            .where('status' , isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc = snapshot.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;

                  return productCard(data, doc.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Zingo",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 10),

            categorySection("Electronics", "products_electronics", Icons.devices),
            categorySection("Fashion", "products_fashion", Icons.checkroom),
            categorySection("Home", "products_home", Icons.home),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

}