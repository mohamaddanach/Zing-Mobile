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
    final user = FirebaseAuth.instance.currentUser;
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

  double clean(double value) => double.parse(value.toStringAsFixed(2));

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
        return Image.network("https://via.placeholder.com/150",
            fit: BoxFit.cover);
      }

      if (value.startsWith("http")) {
        return Image.network(value, fit: BoxFit.cover);
      }

      if (value.contains(",")) {
        value = value.split(",").last;
      }

      return Image.memory(base64Decode(value), fit: BoxFit.cover);
    } catch (_) {
      return Image.network("https://via.placeholder.com/150",
          fit: BoxFit.cover);
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

    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── DRAG HANDLE ─────────────────────
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBDBDB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // ── HEADER ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0095F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Color(0xFF0095F6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Share Product",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Select a friend and add a message",
                            style: TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── MESSAGE INPUT ────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MESSAGE (OPTIONAL)",
                      style: TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                      ),
                      child: TextField(
                        controller: messageController,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "Write something to your friend...",
                          hintStyle: TextStyle(
                            color: Color(0xFF8E8E8E),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF0095F6),
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
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(color: Color(0xFFEFEFEF), height: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "SELECT FRIEND",
                        style: TextStyle(
                          color: Color(0xFF8E8E8E),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFFEFEFEF), height: 1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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
                          color: Color(0xFF0095F6),
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final friends = snapshot.data!.docs;

                    if (friends.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAFAFA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.people_outline_rounded,
                                color: Color(0xFF8E8E8E),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "No friends yet",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Add friends to share products with them",
                              style: TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend =
                        friends[index].data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEFEFEF),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFEDA75),
                                    Color(0xFFFA7E1E),
                                    Color(0xFFD62976),
                                    Color(0xFF833AB4),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFAFAFA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              friend['username'] ?? "",
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              friend['phone_number'] ?? "",
                              style: const TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontSize: 12,
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                final message =
                                messageController.text.trim();

                                await FirebaseFirestore.instance
                                    .collection("shared_products")
                                    .add({
                                  "product_id": productId,
                                  "category": collection.split("_").last,
                                  "product_name":
                                  product['product_name'] ?? "",
                                  "product_image": (product['images']
                                  is List &&
                                      product['images'].isNotEmpty)
                                      ? product['images'][0]
                                      : product['images'] ?? "",
                                  "price": product['priceonplatform'] ?? 0,
                                  "seller_name":
                                  product['seller_name'] ?? "",
                                  "sender_uid": user.uid,
                                  "sender_phone": phone,
                                  "sender_name":
                                  userDoc.data()?['username'] ?? "",
                                  "receiver_phone":
                                  friend['phone_number'] ?? "",
                                  "receiver_name":
                                  friend['username'] ?? "",
                                  "message":
                                  message.isEmpty ? null : message,
                                  "status": "pending",
                                  "timestamp":
                                  FieldValue.serverTimestamp(),
                                });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Shared with ${friend['username']}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor:
                                      const Color(0xFF0095F6),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0095F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Send",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ).whenComplete(() => messageController.dispose());
  }

  // 🎨 INSTAGRAM-STYLE PRODUCT CARD
  Widget productCard(
      Map<String, dynamic> data,
      String productId,
      String collection,
      ) {
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
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        ),
        child: Column(
          children: [
            // ── IMAGE + OVERLAYS ──────────────────────────────
            // ── IMAGE ─────────────────────────────────────────
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: _imageWidget(data),
                ),
              ),
            ),

            // ── INFO ─────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['product_name'] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "\$${data['priceonplatform']}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFEFEFEF)),
                          ),
                          child: Text(
                            "${calcPoints(data).toStringAsFixed(0)} pts",
                            style: const TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // ── ACTION ICONS (Like / Save / Repost) ──────────
                    Row(
                      children: [
                        // ── LIKE — RED ─────────────────────────────
                        if (user != null)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('liked_products')
                                .doc(productId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final isLiked = snapshot.hasData && snapshot.data!.exists;
                              return GestureDetector(
                                onTap: () => toggleLike(productId, collection),
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  color: isLiked ? Colors.red : Colors.grey.shade600,
                                  size: 22,
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 16),

                        // ── SAVE — BLUE ────────────────────────────
                        if (user != null)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('saved_products')
                                .doc(productId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final isSaved = snapshot.hasData && snapshot.data!.exists;
                              return GestureDetector(
                                onTap: () => toggleSave(productId, collection),
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  color: isSaved ? Colors.blue : Colors.grey.shade600,
                                  size: 22,
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 16),

                        // ── REPOST — GREEN ─────────────────────────
                        GestureDetector(
                          onTap: () async {
                            try {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              if (currentUser == null) return;

                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .get();

                              final userData = userDoc.data() ?? {};

                              final repostData = {
                                ...data,
                                "productId": productId,
                                "collection": collection,
                                "image_url": data['image_url'] ??
                                    data['image'] ??
                                    data['photo'] ??
                                    data['product_image'] ??
                                    data['productImage'] ??
                                    data['photoUrl'] ??
                                    (data['images'] != null &&
                                        data['images'] is List &&
                                        data['images'].isNotEmpty
                                        ? data['images'][0]
                                        : "") ??
                                    "",
                                "product_name": data['product_name'] ??
                                    data['name'] ??
                                    "Unknown Product",
                                "priceonplatform":
                                data['priceonplatform'] ?? data['price'] ?? 0,
                                "description": data['description'] ?? "",
                                "repostedByUid": currentUser.uid,
                                "repostedByName": userData['username'] ?? "Unknown User",
                                "repostedByImage": userData['profile_url'] ?? "",
                                "repostedByPhone": userData['phone_number'] ?? "",
                                "repostedAt": FieldValue.serverTimestamp(),
                              };

                              await FirebaseFirestore.instance
                                  .collection("reposts")
                                  .add(repostData);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Product reposted successfully"),
                                ),
                              );
                            } catch (e) {
                              print(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error reposting product: $e")),
                              );
                            }
                          },
                          child: const Icon(
                            Icons.repeat_rounded,
                            color: Colors.green,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // BUY — Instagram blue
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () {
                                PurchaseDialog.show(
                                  context: context,
                                  data: data,
                                  onConfirm: (qty, paymentMethod) async {
                                    await TransactionService
                                        .processPurchase(
                                      productData: {
                                        ...data,
                                        "category": collection.replaceFirst(
                                          "products_",
                                          "",
                                        )
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
                                backgroundColor: const Color(0xFF0095F6),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Buy",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // SHARE — Instagram outline button
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => shareProduct(
                                  data, productId, collection),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                      color: Color(0xFFDBDBDB)),
                                ),
                              ),
                              child: const Text(
                                "Share",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
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
      ),
    );
  }

  // 🎨 INSTAGRAM-STYLE CATEGORY HEADER
  Widget categorySection(
      String title,
      String collection,
      IconData icon,
      List<Color> gradientColors,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HEADER (Story-circle inspired) ───────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Gradient ring around icon (Instagram story style)
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFAFAFA),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Trending now",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => openCategoryPage(title, collection),
                child: const Text(
                  "See all",
                  style: TextStyle(
                    color: Color(0xFF0095F6), // Instagram blue
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── PRODUCTS ROW ─────────────────────────────────
        SizedBox(
          height: 320,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .where('status', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0095F6),
                    strokeWidth: 2,
                  ),
                );
              }

              // 🔍 Apply search filter
              final docs = snapshot.data!.docs.where((doc) {
                if (_searchQuery.isEmpty) return true;
                final data = doc.data() as Map<String, dynamic>;
                final name =
                (data['product_name'] ?? "").toString().toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? "No products yet"
                        : "No matches for \"$_searchQuery\"",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return productCard(data, doc.id, collection);
                },
              );
            },
          ),
        ),

        // Subtle divider between sections (IG-style)
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 0.5,
          color: const Color(0xFFEFEFEF),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ── INSTAGRAM-STYLE APP BAR WITH SEARCH ─────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEFEFEF), width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // 🔍 Search field (Instagram explore style)
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF8E8E8E),
                            size: 20,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                            child: const Icon(
                              Icons.cancel,
                              color: Color(0xFF8E8E8E),
                              size: 18,
                            ),
                          ),
                          hintText: "Search products, brands…",
                          hintStyle: const TextStyle(
                            color: Color(0xFF8E8E8E),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── BODY ─────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const AdvertisementBanner(),
            categorySection(
              "Electronics",
              "products_electronics",
              Icons.devices_rounded,
              const [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
              ],
            ),
            categorySection(
              "Fashion",
              "products_fashion",
              Icons.checkroom_rounded,
              const [
                Color(0xFF833AB4),
                Color(0xFFC13584),
                Color(0xFFE1306C),
              ],
            ),
            categorySection(
              "Home",
              "products_home",
              Icons.home_rounded,
              const [
                Color(0xFF405DE6),
                Color(0xFF5851DB),
                Color(0xFF833AB4),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}