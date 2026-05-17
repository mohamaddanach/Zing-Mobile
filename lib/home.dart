import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zing/purchase_dialog.dart';
import 'select_friend_screen.dart';
import 'transaction_service.dart';
import 'more_by_categoty.dart';
import 'package:url_launcher/url_launcher.dart';
import 'advertisement.dart';
import 'show_products.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double getPoints(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  Future<void> toggleLike(String productId, String collection) async {
    String _searchQuery = "";
    final user = FirebaseAuth.instance.currentUser;
    @override
    void dispose() {
      // 🟢 Clean memory usage when the page is closed
      _searchController.dispose();
      super.dispose();
    }
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('liked_products')
        .doc(productId);

    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'product_id': productId,
        'collection': collection,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> toggleSave(String productId, String collection) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_products')
        .doc(productId);

    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'product_id': productId,
        'collection': collection,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

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
      String collection,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    String phone = userDoc.data()?['phone_number'] ?? "";
    if (phone.isEmpty) phone = user.phoneNumber ?? "";

    // MESSAGE CONTROLLER
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [

              // ── DRAG HANDLE ─────────────────────
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // ── HEADER ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Color(0xFFD32F2F),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Share Product",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Select a friend and add a message",
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── MESSAGE INPUT ────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "MESSAGE (OPTIONAL)",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: TextField(
                        controller: messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "Write something to your friend...",
                          hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF1976D2),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── DIVIDER ──────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF2A2A2A))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "SELECT FRIEND",
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF2A2A2A))),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── FRIENDS LIST ─────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(phone)
                      .collection('friends_list')
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD32F2F),
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final friends = snapshot.data!.docs;

                    if (friends.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                color: Color(0xFF6B7280), size: 40),
                            SizedBox(height: 10),
                            Text(
                              "No friends yet",
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend =
                        friends[index].data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),

                            // AVATAR
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                            ),

                            title: Text(
                              friend['username'] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),

                            subtitle: Text(
                              friend['phone_number'] ?? "",
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),

                            // SEND BUTTON
                            trailing: GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);

                                final message = messageController.text.trim();

                                await FirebaseFirestore.instance
                                    .collection("shared_products")
                                    .add({
                                  "product_id":   productId,
                                  "category":     collection.split("_").last,
                                  "product_name": product['product_name'] ?? "",
                                  "product_image": (product['images'] is List &&
                                      product['images'].isNotEmpty)
                                      ? product['images'][0]
                                      : product['images'] ?? "",
                                  "price":       product['priceonplatform'] ?? 0,
                                  "seller_name": product['seller_name'] ?? "",

                                  "sender_uid":   user.uid,
                                  "sender_phone": phone,
                                  "sender_name":  userDoc.data()?['username'] ?? "",

                                  "receiver_phone": friend['phone_number'] ?? "",
                                  "receiver_name":  friend['username'] ?? "",

                                  // ── NEW ──
                                  "message": message.isEmpty ? null : message,

                                  "status":    "pending",
                                  "timestamp": FieldValue.serverTimestamp(),
                                });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Shared with ${friend['username']}",
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD32F2F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Send",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).whenComplete(() => messageController.dispose());
  }

  // 🎨 PRODUCT CARD (UPDATED)
  Widget productCard(Map<String, dynamic> data, String productId, String collection) {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
        onTap: () {
          ShowProducts.showProductDetails(
            context: context,
            data: data,
            productId: productId,
            collection: collection,
            imageWidget: _imageWidget,
            calcPoints: calcPoints,
            shareProduct: shareProduct,
          );
        },
        child: Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── IMAGE + LIKE & SAVE OVERLAY ──────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [

                // IMAGE
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: _imageWidget(data),
                  ),
                ),

                // TOP-RIGHT: SAVE BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: user == null
                      ? const SizedBox.shrink()
                      : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('saved_products')
                        .doc(productId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final isSaved =
                          snapshot.hasData && snapshot.data!.exists;
                      return GestureDetector(
                        onTap: () => toggleSave(productId, collection),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSaved
                                ? const Color(0xFF1976D2)
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: isSaved
                                ? Colors.white
                                : const Color(0xFF1976D2),
                            size: 17,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // TOP-LEFT: LIKE BUTTON
                Positioned(
                  top: 8,
                  left: 8,
                  child: user == null
                      ? const SizedBox.shrink()
                      : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('liked_products')
                        .doc(productId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final isLiked =
                          snapshot.hasData && snapshot.data!.exists;
                      return GestureDetector(
                        onTap: () => toggleLike(productId, collection),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isLiked
                                ? const Color(0xFFD32F2F)
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: isLiked
                                ? Colors.white
                                : const Color(0xFFD32F2F),
                            size: 17,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),

          // ── INFO ─────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    data['product_name'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  Text(
                    "\$${data['priceonplatform']}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "${calcPoints(data).toStringAsFixed(2)} pts",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [

                      // BUY
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            PurchaseDialog.show(
                              context: context,
                              data: data,
                              onConfirm: (qty, paymentMethod) async {
                                await TransactionService.processPurchase(
                                  productData: {
                                    ...data,
                                    "category": collection.replaceFirst("products_", "")
                                  },
                                  quantity: qty,
                                  source: "home",
                                  paymentMethod: paymentMethod,
                                  productId: productId,
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Buy",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // SHARE
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => shareProduct(data, productId, collection),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Share",
                            style: TextStyle(color: Colors.white),
                          ),
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
        ));
  }

  Widget categorySection(String title, String collection, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Row(
                  children: [
                    Icon(icon, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                // 🔵 MORE BUTTON (UPDATED)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      openCategoryPage(title, collection);
                    },
                    child: const Text(
                      "MORE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),

        SizedBox(
          height: 280,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .where('status', isEqualTo: true)
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

                  return productCard(data, doc.id, collection);
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
            const AdvertisementBanner(),
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