import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'purchase_dialog.dart';
import 'transaction_service.dart';
import 'show_products.dart';

class all_in_one_category extends StatefulWidget {
  final String title;
  final String collection;

  const all_in_one_category({
    super.key,
    required this.title,
    required this.collection,
  });

  @override
  State<all_in_one_category> createState() => _all_in_one_categoryState();
}

class _all_in_one_categoryState extends State<all_in_one_category> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double calcPoints(Map<String, dynamic> data) {
    final raw = data['bonus_reserve'];
    if (raw == null) return 0;
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  // 🖼 SAFE IMAGE HANDLER
  Widget _imageWidget(Map<String, dynamic> data) {
    try {
      final images = data['images'];
      String value = "";

      if (images is List && images.isNotEmpty) {
        value = images.first.toString();
      } else if (images is String) {
        value = images;
      }

      if (value.isEmpty) {
        return Image.network(
          "https://via.placeholder.com/150",
          fit: BoxFit.cover,
        );
      }

      if (value.startsWith("http")) {
        return Image.network(
          value,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.network("https://via.placeholder.com/150"),
        );
      }

      if (value.contains(",")) {
        value = value.split(",").last;
      }

      return Image.memory(
        base64Decode(value),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.network("https://via.placeholder.com/150"),
      );
    } catch (_) {
      return Image.network(
        "https://via.placeholder.com/150",
        fit: BoxFit.cover,
      );
    }
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

  Future<void> repostProduct(
      Map<String, dynamic> data, String productId, String collection) async {
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
        "product_name":
        data['product_name'] ?? data['name'] ?? "Unknown Product",
        "priceonplatform": data['priceonplatform'] ?? data['price'] ?? 0,
        "description": data['description'] ?? "",
        "repostedByUid": currentUser.uid,
        "repostedByName": userData['username'] ?? "Unknown User",
        "repostedByImage": userData['profile_url'] ?? "",
        "repostedByPhone": userData['phone_number'] ?? "",
        "repostedAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection("reposts").add(repostData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product reposted successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error reposting product: $e")),
        );
      }
    }
  }

  // 🎨 INSTAGRAM-STYLE GRID PRODUCT CARD
  Widget _productCard(
      Map<String, dynamic> data, String productId, String collection) {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () {
        ShowProducts.showProductDetails(
          context: context,
          data: data,
          productId: productId,
          collection: collection,
          imageWidget: _imageWidget,
          calcPoints: (d) => d['bonus_reserve'] ?? 0,
          shareProduct: (_, __, ___) {},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE ─────────────────────────────────────
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: _imageWidget(data),
                ),
              ),
            ),

            // ── INFO ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['product_name'] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
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
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(6),
                            border:
                            Border.all(color: const Color(0xFFEFEFEF)),
                          ),
                          child: Text(
                            "${calcPoints(data).toStringAsFixed(0)} pts",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── ACTION ICONS (Like / Save / Repost) ──
                  Row(
                    children: [
                      if (user != null)
                        StreamBuilder<DocumentSnapshot>(
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
                              child: Icon(
                                isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: isLiked
                                    ? Colors.red
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      const SizedBox(width: 14),
                      if (user != null)
                        StreamBuilder<DocumentSnapshot>(
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
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                color: isSaved
                                    ? Colors.blue
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () =>
                            repostProduct(data, productId, collection),
                        child: const Icon(
                          Icons.repeat_rounded,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── BUY + SHARE BUTTONS ──────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                              PurchaseDialog.show(
                                context: context,
                                data: data,
                                onConfirm: (qty, paymentMethod) async {
                                  await TransactionService.processPurchase(
                                    productData: {
                                      ...data,
                                      "category": collection.replaceFirst(
                                          "products_", ""),
                                    },
                                    quantity: qty,
                                    source: "category_page",
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            // hook up share later if needed
                          },
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
                          child: const Icon(
                            Icons.send_outlined,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ── INSTAGRAM-STYLE APP BAR WITH SEARCH ──────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEFEFEF), width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Title row with back button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.black, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                          color: Colors.black, fontSize: 15),
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
                        hintText: "Search in ${widget.title.toLowerCase()}…",
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

      // ── BODY ─────────────────────────────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(widget.collection)
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

          // 🔍 search filter
          final docs = snapshot.data!.docs.where((doc) {
            if (_searchQuery.isEmpty) return true;
            final data = doc.data() as Map<String, dynamic>;
            final name =
            (data['product_name'] ?? "").toString().toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          if (docs.isEmpty) {
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
                      Icons.search_off_rounded,
                      color: Color(0xFF8E8E8E),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty
                        ? "No products yet"
                        : "No matches for \"$_searchQuery\"",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Try a different keyword",
                    style: TextStyle(
                      color: Color(0xFF8E8E8E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            physics: const BouncingScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.62,
            ),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _productCard(data, docs[i].id, widget.collection);
            },
          );
        },
      ),
    );
  }
}